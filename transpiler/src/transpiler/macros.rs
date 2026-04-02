use std::collections::HashMap;

use chumsky::prelude::*;

use crate::bank::Bank;
use crate::expression;
use crate::source::syntax;

use super::{Macro, Transpiler};

impl Transpiler<'_> {
    pub(super) fn expand_macro(
        &mut self,
        definition: &Macro,
        args: &str,
        bank: Bank,
        depth: usize,
    ) {
        if depth > 12 {
            self.warn("macro recursion too deep".to_owned());
            return;
        }

        let mut positional = syntax::split_operands(args);

        if let [only] = positional.as_slice() {
            let only = only.trim();

            if only.starts_with('[') && only.ends_with(']') {
                positional = syntax::split_operands(&only[1..only.len() - 1]);
            }
        }

        let named: HashMap<String, String> = definition
            .parameters
            .iter()
            .enumerate()
            .filter_map(|(index, parameter)| {
                positional
                    .get(index)
                    .map(|value| (parameter.to_ascii_uppercase(), value.clone()))
            })
            .collect();

        self.expansion += 1;
        let uid = self.expansion;

        let body: Vec<String> = definition
            .body
            .iter()
            .map(|line| substitute(line, &positional, &named, &self.symbols))
            .map(|line| rename_locals(&line, uid))
            .collect();

        self.exit_macro = false;
        let statements = crate::source::parser::parse(&body);
        self.process_statements(&statements, bank, depth + 1);
        self.exit_macro = false;
    }
}

fn substitute(
    line: &str,
    positional: &[String],
    named: &HashMap<String, String>,
    symbols: &expression::Symbols,
) -> String {
    substitute_parser(positional, named, symbols)
        .parse(line)
        .into_result()
        .unwrap_or_default()
}

fn substitute_parser<'a>(
    positional: &'a [String],
    named: &'a HashMap<String, String>,
    symbols: &'a expression::Symbols,
) -> impl Parser<'a, &'a str, String, extra::Default> + 'a {
    let parameter = just('@')
        .then(just('@').or_not().map(|value| value.is_some()))
        .then(
            any()
                .filter(|character: &char| character.is_ascii_alphanumeric() || *character == '_')
                .repeated()
                .at_least(1)
                .to_slice(),
        )
        .map(|((_, evaluated), name): ((char, bool), &str)| (evaluated, name.to_owned()));

    choice((
        parameter.map(
            |(evaluated, name)| match parameter_value(&name, positional, named) {
                Some(value) if evaluated => expression::evaluate(&value, symbols)
                    .unwrap_or(0)
                    .to_string(),
                Some(value) => value,
                None if evaluated => format!("@@{name}"),
                None => format!("@{name}"),
            },
        ),
        any().map(|character: char| character.to_string()),
    ))
    .repeated()
    .collect::<String>()
}

fn parameter_value(
    name: &str,
    positional: &[String],
    named: &HashMap<String, String>,
) -> Option<String> {
    match name.parse::<usize>() {
        Ok(index) => Some(
            positional
                .get(index.wrapping_sub(1))
                .cloned()
                .unwrap_or_default(),
        ),
        Err(_) => named.get(&name.to_ascii_uppercase()).cloned(),
    }
}

fn rename_locals(line: &str, uid: usize) -> String {
    rename_parser(uid)
        .parse(line)
        .into_result()
        .unwrap_or_default()
}

fn rename_parser<'a>(uid: usize) -> impl Parser<'a, &'a str, String, extra::Default> {
    let local = just('!')
        .then(
            any()
                .filter(|character: &char| {
                    character.is_ascii_alphanumeric() || matches!(*character, '_' | '.')
                })
                .repeated()
                .at_least(1)
                .to_slice(),
        )
        .map(move |(_, name)| {
            format!(
                "@M{uid}_{}",
                expression::sanitize(name).trim_start_matches('@')
            )
        });

    choice((local, any().map(|character: char| character.to_string())))
        .repeated()
        .collect::<String>()
}
