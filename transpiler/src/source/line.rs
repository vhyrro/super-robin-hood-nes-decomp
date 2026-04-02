use chumsky::prelude::*;

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Line {
    Blank,
    Label(String),
    Command {
        label: Option<String>,
        name: String,
        args: String,
    },
    Assignment {
        target: String,
        value: String,
    },
}

impl Line {
    pub fn parse(raw: &str) -> Self {
        let content = content().parse(raw).into_result().unwrap_or_default();

        grammar()
            .parse(content.trim_end())
            .into_result()
            .unwrap_or(Self::Blank)
    }

    pub fn label(&self) -> Option<&str> {
        match self {
            Self::Label(label) => Some(label),
            Self::Command { label, .. } => label.as_deref(),
            Self::Assignment { target, .. } if !target.is_empty() => Some(target),
            Self::Blank | Self::Assignment { .. } => None,
        }
    }

    pub fn command(&self) -> Option<(&str, &str)> {
        match self {
            Self::Command { name, args, .. } => Some((name, args)),
            Self::Blank | Self::Label(_) | Self::Assignment { .. } => None,
        }
    }
}

fn content<'a>() -> impl Parser<'a, &'a str, &'a str, extra::Default> {
    let quoted = just('"')
        .then(
            any()
                .filter(|character: &char| *character != '"')
                .repeated(),
        )
        .then(just('"').or_not())
        .to_slice();
    let plain = any()
        .filter(|character: &char| !matches!(*character, '"' | ';'))
        .repeated()
        .at_least(1)
        .to_slice();

    choice((quoted, plain))
        .repeated()
        .to_slice()
        .then_ignore(any().repeated())
}

fn grammar<'a>() -> impl Parser<'a, &'a str, Line, extra::Default> {
    let blank = choice((
        space()
            .repeated()
            .ignore_then(just('*'))
            .then_ignore(any().repeated())
            .to(Line::Blank),
        end().to(Line::Blank),
    ));

    let assignment_target = any()
        .filter(|character: &char| !character.is_whitespace() && *character != '=')
        .repeated()
        .at_least(1)
        .to_slice();

    let indented_assignment = assignment_target
        .then_ignore(space().repeated())
        .then_ignore(just('='))
        .then(any().repeated().to_slice().map(str::trim))
        .map(|(target, value)| Line::Assignment {
            target: target.to_owned(),
            value: value.to_owned(),
        });

    let indented = space()
        .repeated()
        .at_least(1)
        .ignore_then(choice((indented_assignment, head_line())));

    let labelled =
        word()
            .then_ignore(space().repeated())
            .then(head())
            .map(|(token, (name, args))| {
                if let Some((target, value)) = token.split_once('=') {
                    return Line::Assignment {
                        target: target.to_owned(),
                        value: value.to_owned(),
                    };
                }

                let label = token.trim_end_matches(':').to_owned();

                match name.as_str() {
                    "=" => Line::Assignment {
                        target: label,
                        value: args,
                    },
                    "" => Line::Label(label),
                    _ => Line::Command {
                        label: Some(label),
                        name,
                        args,
                    },
                }
            });

    blank.or(indented).or(labelled)
}

fn head_line<'a>() -> impl Parser<'a, &'a str, Line, extra::Default> {
    head().map(|(name, args)| {
        if name == "=" {
            Line::Assignment {
                target: String::new(),
                value: args,
            }
        } else {
            Line::Command {
                label: None,
                name,
                args,
            }
        }
    })
}

fn head<'a>() -> impl Parser<'a, &'a str, (String, String), extra::Default> {
    end().to((String::new(), String::new())).or(word()
        .then(any().repeated().to_slice().map(str::trim))
        .map(|(head, args)| split_head(head, args)))
}

fn word<'a>() -> impl Parser<'a, &'a str, &'a str, extra::Default> {
    any()
        .filter(|character: &char| !character.is_whitespace())
        .repeated()
        .at_least(1)
        .to_slice()
}

fn space<'a>() -> impl Parser<'a, &'a str, (), extra::Default> {
    any()
        .filter(|character: &char| character.is_whitespace())
        .ignored()
}

fn split_head(head: &str, args: &str) -> (String, String) {
    if head.is_empty() {
        return (String::new(), String::new());
    }

    if head == "=" {
        return ("=".to_owned(), args.to_owned());
    }

    match head.split_once('=') {
        Some((_, value)) => ("=".to_owned(), value.trim().to_owned()),
        None => (head.to_owned(), args.to_owned()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labelled_instruction() {
        assert_eq!(
            Line::parse("FRED: LDA #1 ; hi"),
            Line::Command {
                label: Some("FRED".to_owned()),
                name: "LDA".to_owned(),
                args: "#1".to_owned(),
            }
        );
    }

    #[test]
    fn indented_instruction() {
        assert_eq!(
            Line::parse("\tlda #1"),
            Line::Command {
                label: None,
                name: "lda".to_owned(),
                args: "#1".to_owned(),
            }
        );
    }

    #[test]
    fn assignments() {
        assert_eq!(
            Line::parse("\tname = value"),
            Line::Assignment {
                target: "name".to_owned(),
                value: "value".to_owned(),
            }
        );
        assert_eq!(
            Line::parse("NAME=value"),
            Line::Assignment {
                target: "NAME".to_owned(),
                value: "value".to_owned(),
            }
        );
    }

    #[test]
    fn labels_and_comments() {
        assert_eq!(Line::parse("mapf"), Line::Label("mapf".to_owned()));
        assert_eq!(Line::parse("* whole line"), Line::Blank);
        assert_eq!(Line::parse("\t; nothing"), Line::Blank);
    }

    #[test]
    fn quoted_semicolons_are_not_comments() {
        assert_eq!(
            Line::parse("\tdefb \"; hi\""),
            Line::Command {
                label: None,
                name: "defb".to_owned(),
                args: "\"; hi\"".to_owned(),
            }
        );
    }

    #[test]
    fn whitespace_before_indented_equals() {
        assert_eq!(
            Line::parse("\tfoo \t= bar"),
            Line::Assignment {
                target: "foo".to_owned(),
                value: "bar".to_owned(),
            }
        );
        assert_eq!(
            Line::parse("\tfoo bar = baz"),
            Line::Command {
                label: None,
                name: "foo".to_owned(),
                args: "bar = baz".to_owned(),
            }
        );
    }
}
