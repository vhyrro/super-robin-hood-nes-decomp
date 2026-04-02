use chumsky::prelude::*;

use crate::source::line::Line;
use crate::source::syntax;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Condition {
    If,
    Ifs,
    Iff,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Statement {
    Line(Line, String),
    Conditional {
        kind: Condition,
        args: String,
        body: Vec<Statement>,
        alternative: Vec<Statement>,
    },
    Do {
        label: Option<String>,
        args: String,
        body: Vec<Statement>,
        until: Option<String>,
    },
    Macro {
        name: String,
        parameters: Vec<String>,
        body: Vec<String>,
        raw: String,
    },
    Repeat {
        args: String,
        line: Option<(Line, String)>,
    },
}

#[derive(Clone)]
struct TokenLine {
    line: Line,
    raw: String,
}

pub fn parse(lines: &[String]) -> Vec<Statement> {
    let tokens: Vec<TokenLine> = lines
        .iter()
        .map(|raw| TokenLine {
            line: Line::parse(raw),
            raw: raw.clone(),
        })
        .collect();

    let parser = parser();
    let statements = parser
        .parse(tokens.as_slice())
        .into_result()
        .expect("source blocks are balanced");

    statements
}

fn parser<'a>() -> impl Parser<'a, &'a [TokenLine], Vec<Statement>, extra::Default> {
    let statement = statement();
    let terminator = any()
        .filter(|token: &TokenLine| is_terminator(&token.line))
        .map(statement_line);

    choice((statement, terminator))
        .repeated()
        .collect::<Vec<_>>()
        .then_ignore(end())
}

fn statement<'a>() -> impl Parser<'a, &'a [TokenLine], Statement, extra::Default> {
    recursive(|statement| {
        let plain = any()
            .filter(|token: &TokenLine| !is_terminator(&token.line))
            .map(statement_line);

        let conditional = any()
            .filter(|token: &TokenLine| condition(&token.line).is_some())
            .map(|token| {
                (
                    condition(&token.line).expect("condition"),
                    command_args(&token.line).to_owned(),
                )
            })
            .then(statement.clone().repeated().collect::<Vec<_>>())
            .then(
                command("ELSE")
                    .ignore_then(statement.clone().repeated().collect::<Vec<_>>())
                    .or_not(),
            )
            .then_ignore(command("ENDIF"))
            .map(
                |(((kind, args), body), alternative)| Statement::Conditional {
                    kind,
                    args,
                    body,
                    alternative: alternative.unwrap_or_default(),
                },
            );

        let do_head = any()
            .filter(|token: &TokenLine| is_command(&token.line, "DO"))
            .map(|token| {
                (
                    token.line.label().map(str::to_owned),
                    command_args(&token.line).to_owned(),
                )
            });

        let do_end = command("UNTIL")
            .map(|token| Some(command_args(&token.line).to_owned()))
            .or(command("LOOP").to(None));

        let do_block = do_head
            .then(statement.clone().repeated().collect::<Vec<_>>())
            .then(do_end)
            .map(|(((label, args), body), until)| Statement::Do {
                label,
                args,
                body,
                until,
            });

        let macro_definition = any()
            .filter(|token: &TokenLine| is_command(&token.line, "MACRO"))
            .then(
                any()
                    .filter(|token: &TokenLine| !is_command(&token.line, "ENDM"))
                    .map(|token| token.raw)
                    .repeated()
                    .collect::<Vec<_>>(),
            )
            .then_ignore(command("ENDM"))
            .map(|(token, body)| Statement::Macro {
                name: token.line.label().unwrap_or_default().to_ascii_uppercase(),
                parameters: syntax::split_operands(command_args(&token.line)),
                body,
                raw: token.raw,
            });

        let repeat = any()
            .filter(|token: &TokenLine| is_command(&token.line, "REPEAT"))
            .map(|token| command_args(&token.line).to_owned())
            .then(
                any()
                    .map(|token: TokenLine| (token.line, token.raw))
                    .or_not(),
            )
            .map(|(args, line)| Statement::Repeat { args, line });

        choice((conditional, do_block, macro_definition, repeat, plain))
    })
}

fn command<'a>(
    expected: &'static str,
) -> impl Parser<'a, &'a [TokenLine], TokenLine, extra::Default> + Clone {
    any().filter(move |token: &TokenLine| is_command(&token.line, expected))
}

fn statement_line(token: TokenLine) -> Statement {
    Statement::Line(token.line, token.raw)
}

fn condition(line: &Line) -> Option<Condition> {
    let (name, _) = line.command()?;

    if name.eq_ignore_ascii_case("IF") {
        Some(Condition::If)
    } else if name.eq_ignore_ascii_case("IFS") {
        Some(Condition::Ifs)
    } else if name.eq_ignore_ascii_case("IFF") {
        Some(Condition::Iff)
    } else {
        None
    }
}

fn is_command(line: &Line, expected: &str) -> bool {
    line.command()
        .is_some_and(|(name, _)| name.eq_ignore_ascii_case(expected))
}

fn is_terminator(line: &Line) -> bool {
    ["ELSE", "ENDIF", "ENDM", "LOOP", "UNTIL"]
        .iter()
        .any(|name| is_command(line, name))
}

fn command_args(line: &Line) -> &str {
    line.command().map_or("", |(_, args)| args)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn statements(lines: &[&str]) -> Vec<Statement> {
        parse(
            &lines
                .iter()
                .map(|line| (*line).to_owned())
                .collect::<Vec<_>>(),
        )
    }

    #[test]
    fn conditional_with_alternative() {
        let parsed = statements(&["\tif 1", "\tlda #1", "\telse", "\tlda #2", "\tendif"]);

        assert_eq!(
            parsed,
            vec![Statement::Conditional {
                kind: Condition::If,
                args: "1".to_owned(),
                body: vec![Statement::Line(
                    Line::Command {
                        label: None,
                        name: "lda".to_owned(),
                        args: "#1".to_owned(),
                    },
                    "\tlda #1".to_owned(),
                )],
                alternative: vec![Statement::Line(
                    Line::Command {
                        label: None,
                        name: "lda".to_owned(),
                        args: "#2".to_owned(),
                    },
                    "\tlda #2".to_owned(),
                )],
            }]
        );
    }

    #[test]
    fn nested_do_blocks() {
        let parsed = statements(&["\tdo 2", "\tdo 3", "\tnop", "\tloop", "\tloop"]);

        assert!(matches!(
            parsed.as_slice(),
            [Statement::Do {
                until: None,
                body,
                ..
            }] if matches!(
                body.as_slice(),
                [Statement::Do {
                    until: None,
                    body,
                    ..
                }] if body.len() == 1
            )
        ));
    }

    #[test]
    fn macro_body_remains_raw() {
        let parsed = statements(&["test macro a,b", "\tif a", "\tnop", "\tendif", "\tendm"]);

        assert!(matches!(
            parsed.as_slice(),
            [Statement::Macro {
                name,
                parameters,
                body,
                ..
            }] if name == "TEST"
                && parameters == &["a".to_owned(), "b".to_owned()]
                && body.len() == 3
        ));
    }

    #[test]
    fn repeat_consumes_one_line() {
        let parsed = statements(&["\trepeat 2", "\tnop"]);

        assert!(matches!(
            parsed.as_slice(),
            [Statement::Repeat {
                line: Some((Line::Command { name, .. }, _)),
                ..
            }] if name == "nop"
        ));
    }
}
