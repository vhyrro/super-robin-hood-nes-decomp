mod ast;
mod parser;

use std::collections::HashMap;

pub use ast::{BinaryOp, Expr};
pub use parser::parse;

pub type Symbols = HashMap<String, i64>;

pub fn evaluate(source: &str, symbols: &Symbols) -> Option<i64> {
    parse(source).ok()?.evaluate(symbols)
}

pub fn render(source: &str) -> Option<String> {
    parse(source).ok().map(|expression| expression.render())
}

pub fn sanitize(name: &str) -> String {
    match name.strip_prefix('!').or_else(|| name.strip_prefix('@')) {
        Some(rest) if !rest.is_empty() => format!("@{}", sanitize_chars(rest)),
        _ => sanitize_chars(name),
    }
}

fn sanitize_chars(name: &str) -> String {
    let mut symbol: String = name
        .chars()
        .map(|character| {
            if character.is_ascii_alphanumeric() || character == '_' {
                character.to_ascii_uppercase()
            } else {
                '_'
            }
        })
        .collect();

    if symbol.is_empty() || symbol.as_bytes()[0].is_ascii_digit() {
        symbol.insert(0, '_');
    }

    symbol
}

pub fn sanitize_raw(text: &str) -> String {
    text.chars()
        .map(|character| if character == '&' { '$' } else { character })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn symbols() -> Symbols {
        Symbols::new()
    }

    #[test]
    fn operator_precedence() {
        assert_eq!(evaluate("10-2*3", &symbols()), Some(4));
        assert_eq!(evaluate("2+3*6", &symbols()), Some(20));
    }

    #[test]
    fn byte_operators_span_the_whole_expression() {
        assert_eq!(evaluate(">$1234", &symbols()), Some(0x34));
        assert_eq!(evaluate("<$1234", &symbols()), Some(0x12));
        assert_eq!(evaluate(">$065f+((10/2)*$80)", &symbols()), Some(0xDF));
        assert_eq!(evaluate("<$065f+((10/2)*$80)", &symbols()), Some(0x08));
    }

    #[test]
    fn logic_and_comparison() {
        assert_eq!(evaluate("1!2&0", &symbols()), Some(1));
        assert_eq!(evaluate("5>3", &symbols()), Some(1));
        assert_eq!(evaluate("3>5", &symbols()), Some(0));
        assert_eq!(evaluate("5<>3", &symbols()), Some(1));
    }

    #[test]
    fn rendering_swaps_byte_operators() {
        assert_eq!(render(">$065f+2").as_deref(), Some("<(1631 + 2)"));
        assert_eq!(render("<$065f+2").as_deref(), Some(">(1631 + 2)"));
    }

    #[test]
    fn text_literals() {
        assert_eq!(render("\"a\"\"b\"").as_deref(), Some("\"a\"\"b\""));
        assert!(parse("\"\"").is_ok());
        assert!(parse("\"unterminated").is_err());
    }

    #[test]
    fn range_assertions_and_trailing_input() {
        assert!(parse("$1234[0,255]").is_ok());
        assert!(parse("$1234[0]").is_err());
        assert_eq!(render("$1234 junk").as_deref(), Some("4660"));
        assert_eq!(render("(1+2").as_deref(), Some("1 + 2"));
    }

    #[test]
    fn local_labels_and_ampersand_hex() {
        assert_eq!(render("!loop+1").as_deref(), Some("@LOOP + 1"));
        assert_eq!(render("&ff").as_deref(), Some("255"));
    }
}
