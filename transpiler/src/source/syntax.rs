use chumsky::prelude::*;

pub fn split_operands(text: &str) -> Vec<String> {
    operands().parse(text).into_result().unwrap_or_default()
}

pub fn parse_string(text: &str) -> String {
    let text = text.trim();
    let inner = text.strip_prefix('"').unwrap_or(text);
    let inner = inner.strip_suffix('"').unwrap_or(inner);
    inner.replace("\"\"", "\"")
}

pub fn bracket_groups(text: &str) -> Vec<String> {
    groups().parse(text).into_result().unwrap_or_default()
}

fn operands<'a>() -> impl Parser<'a, &'a str, Vec<String>, extra::Default> {
    operand()
        .then_ignore(just(','))
        .repeated()
        .collect::<Vec<_>>()
        .then(operand())
        .map(|(mut operands, last)| {
            operands.push(last);

            if operands.last().is_some_and(|operand| operand.is_empty()) {
                operands.pop();
            }

            operands.into_iter().map(str::to_owned).collect()
        })
}

fn operand<'a>() -> impl Parser<'a, &'a str, &'a str, extra::Default> {
    let quoted = just('"')
        .then(
            any()
                .filter(|character: &char| *character != '"')
                .repeated(),
        )
        .then(just('"').or_not())
        .to_slice();

    let atom = choice((
        quoted,
        group(),
        any()
            .filter(|character: &char| !matches!(*character, ',' | '"' | '(' | ')' | '[' | ']'))
            .to_slice(),
    ));

    atom.repeated().to_slice().map(str::trim)
}

fn group<'a>() -> impl Parser<'a, &'a str, &'a str, extra::Default> {
    recursive(|group| {
        let quoted = just('"')
            .then(
                any()
                    .filter(|character: &char| *character != '"')
                    .repeated(),
            )
            .then(just('"').or_not())
            .to_slice();

        let atom = choice((
            quoted,
            group,
            any()
                .filter(|character: &char| !matches!(*character, '(' | ')' | '[' | ']' | '"'))
                .to_slice(),
        ));

        choice((just('('), just('[')))
            .then(atom.repeated())
            .then(choice((just(')'), just(']'))))
            .to_slice()
    })
}

fn groups<'a>() -> impl Parser<'a, &'a str, Vec<String>, extra::Default> {
    let group = just('[')
        .ignore_then(
            any()
                .filter(|character: &char| !matches!(*character, '[' | ']'))
                .repeated()
                .to_slice(),
        )
        .then_ignore(just(']'))
        .map(str::to_owned);

    choice((group.map(Some), any().to(None)))
        .repeated()
        .collect::<Vec<_>>()
        .map(|groups| groups.into_iter().flatten().collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn operands_respect_nesting_and_quotes() {
        assert_eq!(
            split_operands("1,2,(3,4),\"a,b\""),
            vec!["1", "2", "(3,4)", "\"a,b\""]
        );
    }

    #[test]
    fn operands_preserve_intermediate_empties() {
        assert_eq!(split_operands("a,,b"), vec!["a", "", "b"]);
        assert_eq!(split_operands("a,"), vec!["a"]);
        assert_eq!(split_operands(","), vec![""]);
        assert_eq!(split_operands(""), Vec::<String>::new());
    }

    #[test]
    fn strings_unescape_doubled_quotes() {
        assert_eq!(parse_string("\"a\"\"b\""), "a\"b");
    }

    #[test]
    fn bracket_groups_split_on_brackets() {
        assert_eq!(bracket_groups("[1][2,3]"), vec!["1", "2,3"]);
    }

    #[test]
    fn bracket_groups_discard_unterminated_groups() {
        assert_eq!(bracket_groups("a[bc"), Vec::<String>::new());
    }
}
