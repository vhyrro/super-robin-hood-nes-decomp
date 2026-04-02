mod emit;
mod macros;

use std::collections::{BTreeMap, HashMap};
use std::path::{Path, PathBuf};

use crate::bank::Bank;
use crate::expression::{self, Symbols};
use crate::project::{Layout, SourceFile};
use crate::source::{
    line::Line,
    parser::{self, Condition, Statement},
    syntax, text,
};

pub struct Transpiler<'a> {
    source_dir: &'a Path,
    output: BTreeMap<Bank, Vec<String>>,
    symbols: Symbols,
    macros: HashMap<String, Macro>,
    warnings: Vec<String>,
    halted: bool,
    exit_macro: bool,
    expansion: usize,
    ram_origin: Option<i64>,
}

#[derive(Clone)]
struct Macro {
    parameters: Vec<String>,
    body: Vec<String>,
}

pub struct Transpiled {
    banks: BTreeMap<Bank, Vec<String>>,
    warnings: Vec<String>,
}

impl Transpiled {
    pub fn bank_source(&self, bank: Bank) -> String {
        self.banks
            .get(&bank)
            .map_or_else(String::new, |lines| lines.join("\n"))
    }

    pub fn bank_count(&self) -> usize {
        self.banks.len()
    }

    pub fn warnings(&self) -> &[String] {
        &self.warnings
    }
}

impl<'a> Transpiler<'a> {
    pub fn new(source_dir: &'a Path) -> Self {
        Self {
            source_dir,
            output: BTreeMap::new(),
            symbols: Symbols::new(),
            macros: HashMap::new(),
            warnings: Vec::new(),
            halted: false,
            exit_macro: false,
            expansion: 0,
            ram_origin: None,
        }
    }

    pub fn run(mut self) -> Transpiled {
        for file in crate::project::FILES {
            if self.halted {
                break;
            }
            self.process_source_file(file);
        }

        Transpiled {
            banks: self.output,
            warnings: self.warnings,
        }
    }

    fn process_source_file(&mut self, file: &SourceFile) {
        self.push(file.bank, format!("; ==== {} ====", file.name));

        let path = self.source_dir.join(file.name);

        if !path.exists() {
            self.warn(format!("missing source {}", path.display()));
            return;
        }

        match file.layout {
            Layout::Source => self.file(&path, file.bank, 0),
            Layout::SplitAtBank14 => self.process_split_file(&path),
        }
    }

    fn process_split_file(&mut self, path: &Path) {
        let statements = parser::parse(&text::lines(path));
        let split = statements
            .iter()
            .position(is_bank15_origin)
            .unwrap_or(statements.len());

        self.process_statements(&statements[..split], Bank::Prg14, 0);

        if split < statements.len() {
            self.process_statements(&statements[split..], Bank::Prg15, 0);
        }
    }

    fn file(&mut self, path: &Path, bank: Bank, depth: usize) {
        if depth > 16 {
            self.warn("include nesting too deep".to_owned());
            return;
        }

        self.ram_origin = None;
        let statements = parser::parse(&text::lines(path));
        self.process_statements(&statements, bank, depth);
    }

    fn process_statements(&mut self, statements: &[Statement], bank: Bank, depth: usize) {
        for statement in statements {
            if self.halted || self.exit_macro {
                return;
            }

            match statement {
                Statement::Line(line, raw) => self.process_line(line, raw, bank, depth),
                Statement::Conditional {
                    kind,
                    args,
                    body,
                    alternative,
                } => {
                    let condition = match kind {
                        Condition::If => self.evaluate(args).unwrap_or(0) != 0,
                        Condition::Ifs => syntax::bracket_groups(args)
                            .split_first()
                            .is_some_and(|(first, rest)| rest.iter().any(|group| group == first)),
                        Condition::Iff => self.evaluate(args).is_some(),
                    };

                    self.process_statements(
                        if condition { body } else { alternative },
                        bank,
                        depth,
                    );
                }
                Statement::Do {
                    label,
                    args,
                    body,
                    until,
                } => {
                    if let Some(label) = label {
                        self.emit_label(bank, label);
                    }

                    match until {
                        Some(condition) => self.repeat_until(body, condition, bank, depth),
                        None => {
                            let count = self.evaluate(args).unwrap_or(1).max(1) as u32;
                            self.repeat(body, count, bank, depth);
                        }
                    }
                }
                Statement::Macro {
                    name,
                    parameters,
                    body,
                    raw,
                } => {
                    if name.is_empty() {
                        self.warn(format!("MACRO without name near line {raw:?}"));
                    } else {
                        self.macros.insert(
                            name.clone(),
                            Macro {
                                parameters: parameters.clone(),
                                body: body.clone(),
                            },
                        );
                    }
                }
                Statement::Repeat { args, line } => {
                    let count = self.evaluate(args).unwrap_or(1).max(1) as u32;

                    if let Some((line, raw)) = line {
                        for _ in 0..count {
                            self.process_line(line, raw, bank, depth);

                            if self.exit_macro || self.halted {
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    fn process_line(&mut self, line: &Line, raw: &str, bank: Bank, depth: usize) {
        let command = line
            .command()
            .map(|(name, args)| (name.to_ascii_uppercase(), args));

        if let Some((name, args)) = &command {
            match name.as_str() {
                "ELSE" | "ENDIF" | "ENDM" => return,
                "EXITM" => {
                    self.exit_macro = true;
                    return;
                }
                "INCLUDE" => {
                    let include = args.trim().trim_matches('"');

                    match self.resolve(include) {
                        Some(path) => self.file(&path, bank, depth + 1),
                        None => self.warn(format!("INCLUDE not found: {include}")),
                    }

                    return;
                }
                "END" => {
                    self.halted = true;
                    return;
                }
                _ => {}
            }
        }

        if let Some((name, args)) = &command {
            if let Some(definition) = self.macros.get(name).cloned() {
                if let Some(label) = line.label() {
                    self.emit_label(bank, label);
                }

                self.expand_macro(&definition, args, bank, depth);
                return;
            }
        }

        self.emit_line(bank, line, raw);
    }

    fn repeat(&mut self, body: &[Statement], count: u32, bank: Bank, depth: usize) {
        for _ in 0..count {
            self.process_statements(body, bank, depth);

            if self.exit_macro || self.halted {
                break;
            }
        }
    }

    fn repeat_until(&mut self, body: &[Statement], condition: &str, bank: Bank, depth: usize) {
        let mut iterations = 0u32;

        loop {
            self.process_statements(body, bank, depth);

            if self.exit_macro || self.halted {
                break;
            }

            iterations += 1;

            if self.evaluate(condition) == Some(1) || iterations > 1_000_000 {
                break;
            }
        }
    }

    fn evaluate(&self, source: &str) -> Option<i64> {
        expression::evaluate(source, &self.symbols)
    }

    fn emit_label(&mut self, bank: Bank, label: &str) {
        self.push(bank, format!("{}:", expression::sanitize(label)));
    }

    fn resolve(&self, name: &str) -> Option<PathBuf> {
        let normalized = name.replace('\\', "/");
        let file_name = normalized.rsplit('/').next().unwrap_or(&normalized);

        [file_name.to_owned(), file_name.to_ascii_uppercase()]
            .into_iter()
            .map(|candidate| self.source_dir.join(candidate))
            .find(|candidate| candidate.exists())
    }

    fn push(&mut self, bank: Bank, line: String) {
        self.output.entry(bank).or_default().push(line);
    }

    fn warn(&mut self, warning: String) {
        self.warnings.push(warning);
    }
}

fn is_bank15_origin(statement: &Statement) -> bool {
    match statement {
        Statement::Line(Line::Command { name, args, .. }, _) => {
            name.eq_ignore_ascii_case("ORG") && args.to_ascii_lowercase().contains("c004")
        }
        _ => false,
    }
}
