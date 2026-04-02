use std::error::Error;
use std::fmt::{self, Display, Formatter};

use chumsky::pratt::{infix, left, prefix};
use chumsky::prelude::*;

use super::{BinaryOp, Expr};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ParseError {
    message: String,
}

impl ParseError {
    fn new(message: impl Into<String>) -> Self {
        Self {
            message: message.into(),
        }
    }
}

impl Display for ParseError {
    fn fmt(&self, formatter: &mut Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.message)
    }
}

impl Error for ParseError {}

pub fn parse(source: &str) -> Result<Expr, ParseError> {
    parser()
        .parse(source.as_bytes())
        .into_result()
        .map_err(|errors| {
            let message = errors
                .first()
                .map(ToString::to_string)
                .unwrap_or_else(|| "invalid expression".to_owned());

            ParseError::new(message)
        })
}

fn parser<'source>() -> impl Parser<'source, &'source [u8], Expr, extra::Err<Rich<'source, u8>>> {
    let expression = recursive(|expression| {
        let operator = |byte: u8| just(byte).padded();

        let identifier = any()
            .filter(|byte: &u8| byte.is_ascii_alphabetic() || matches!(byte, b'_' | b'.' | b'$'))
            .then(
                any()
                    .filter(|byte: &u8| {
                        byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'.' | b'$')
                    })
                    .repeated(),
            )
            .to_slice()
            .map(slice_text)
            .map(Expr::Symbol);

        let local = just(b'!')
            .ignore_then(
                any()
                    .filter(|byte: &u8| byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'.'))
                    .repeated()
                    .at_least(1)
                    .to_slice(),
            )
            .map(|name| format!("!{}", slice_text(name)))
            .map(Expr::Symbol);

        let decimal = any()
            .filter(u8::is_ascii_digit)
            .repeated()
            .at_least(1)
            .to_slice()
            .try_map(|digits, span| parse_number(digits, 10, span));

        let hexadecimal = choice((just(b'$'), just(b'&')))
            .ignore_then(
                any()
                    .filter(u8::is_ascii_hexdigit)
                    .repeated()
                    .at_least(1)
                    .to_slice(),
            )
            .try_map(|digits, span| parse_number(digits, 16, span));

        let binary_literal = just(b'%')
            .ignore_then(
                any()
                    .filter(|byte: &u8| matches!(byte, b'0' | b'1'))
                    .repeated()
                    .at_least(1)
                    .to_slice(),
            )
            .try_map(|digits, span| parse_number(digits, 2, span));

        let text_character = choice((
            just(b'"').then(just(b'"')).to(b'"'),
            any().filter(|byte: &u8| *byte != b'"'),
        ));

        let text = just(b'"')
            .ignore_then(text_character.repeated().collect::<Vec<u8>>())
            .then_ignore(just(b'"'))
            .map(|bytes| Expr::Text(bytes.into_iter().map(char::from).collect()));

        let parenthesized = just(b'(')
            .ignore_then(expression.clone())
            .then_ignore(just(b')').or_not());

        let atom = choice((
            parenthesized,
            just(b'*').to(Expr::ProgramCounter),
            text,
            hexadecimal,
            binary_literal,
            decimal,
            local,
            identifier,
        ))
        .boxed()
        .padded();

        let expression = atom.pratt((
            prefix(6, operator(b'-'), |_, right, _| {
                Expr::Negated(Box::new(right))
            }),
            prefix(0, operator(b'>'), |_, right, _| {
                Expr::LowByte(Box::new(right))
            }),
            prefix(0, operator(b'<'), |_, right, _| {
                Expr::HighByte(Box::new(right))
            }),
            infix(left(5), operator(b'*'), |left, _, right, _| {
                binary(BinaryOp::Multiply, left, right)
            }),
            infix(left(5), operator(b'/'), |left, _, right, _| {
                binary(BinaryOp::Divide, left, right)
            }),
            infix(left(4), operator(b'+'), |left, _, right, _| {
                binary(BinaryOp::Add, left, right)
            }),
            infix(left(4), operator(b'-'), |left, _, right, _| {
                binary(BinaryOp::Subtract, left, right)
            }),
            infix(left(3), just(&b"<>"[..]).padded(), |left, _, right, _| {
                binary(BinaryOp::NotEqual, left, right)
            }),
            infix(left(3), operator(b'='), |left, _, right, _| {
                binary(BinaryOp::Equal, left, right)
            }),
            infix(left(3), operator(b'<'), |left, _, right, _| {
                binary(BinaryOp::Less, left, right)
            }),
            infix(left(3), operator(b'>'), |left, _, right, _| {
                binary(BinaryOp::Greater, left, right)
            }),
            infix(left(2), operator(b'&'), |left, _, right, _| {
                binary(BinaryOp::And, left, right)
            }),
            infix(left(1), operator(b'!'), |left, _, right, _| {
                binary(BinaryOp::Or, left, right)
            }),
            infix(left(1), operator(b'~'), |left, _, right, _| {
                binary(BinaryOp::Xor, left, right)
            }),
        ));

        expression
    });

    let range_assertion = just(b'[')
        .ignore_then(expression.clone())
        .then(just(b',').or_not())
        .then(expression.clone())
        .then(just(b']').or_not())
        .ignored();

    let suffix = choice((
        range_assertion.ignored(),
        any().filter(|byte: &u8| *byte != b'[').ignored(),
        end(),
    ));

    expression
        .padded()
        .then(suffix)
        .map(|(expression, _)| expression)
        .then_ignore(any().repeated())
}

fn parse_number<'source>(
    digits: &[u8],
    radix: u32,
    span: SimpleSpan,
) -> Result<Expr, Rich<'source, u8>> {
    let digits = std::str::from_utf8(digits).unwrap_or("");

    i64::from_str_radix(digits, radix)
        .map(Expr::Number)
        .map_err(|error| Rich::custom(span, error.to_string()))
}

fn slice_text(bytes: &[u8]) -> String {
    std::str::from_utf8(bytes).unwrap_or("0").to_owned()
}

fn binary(operator: BinaryOp, left: Expr, right: Expr) -> Expr {
    Expr::Binary(operator, Box::new(left), Box::new(right))
}
