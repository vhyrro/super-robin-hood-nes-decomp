use crate::bank::Bank;
use crate::expression;
use crate::source::line::Line;
use crate::source::syntax;

use super::Transpiler;

const OPCODES: &[&str] = &[
    "ADC", "AND", "ASL", "BCC", "BCS", "BEQ", "BIT", "BMI", "BNE", "BPL", "BRK", "BVC", "BVS",
    "CLC", "CLD", "CLI", "CLV", "CMP", "CPX", "CPY", "DEC", "DEX", "DEY", "EOR", "INC", "INX",
    "INY", "JMP", "JSR", "LDA", "LDX", "LDY", "LSR", "NOP", "ORA", "PHA", "PHP", "PLA", "PLP",
    "ROL", "ROR", "RTI", "RTS", "SBC", "SEC", "SED", "SEI", "STA", "STX", "STY", "TAX", "TAY",
    "TSX", "TXA", "TXS", "TYA",
];

const IGNORED_DIRECTIVES: &[&str] = &[
    "BANK",
    "SEND",
    "DLOAD",
    "DOWNLOAD",
    "LIST",
    "LST",
    "LLIST",
    "LLST",
    "LISTOPT",
    "LSTOPT",
    "PRINTER",
    "PAGE",
    "TITLE",
    "TTL",
    "SUBTITLE",
    "SUBTTL",
    "STITLE",
    "WIDTH",
    "SKP",
    "EJECT",
    "FREE",
    "SKIP",
    "RADIX",
    "ASK",
    "QUERY",
    "OPTION",
    "PATH",
    "DEBUGSKIP",
];

#[derive(Clone, Copy)]
enum DataKind {
    Bytes,
    Dc,
    Cbm,
    String,
}

impl Transpiler<'_> {
    pub(super) fn emit_line(&mut self, bank: Bank, line: &Line, raw: &str) {
        if let Line::Command { name, args, .. } = line {
            if name.eq_ignore_ascii_case("ORG") {
                if let Some(address) = self.evaluate(args) {
                    if address < 0x800 {
                        self.ram_origin = Some(address);
                        return;
                    }

                    self.ram_origin = None;
                }
            }
        }

        if let Some(origin) = self.ram_origin {
            self.define_in_ram(bank, line, origin);
            return;
        }

        match line {
            Line::Blank => {}
            Line::Label(label) => self.emit_label(bank, label),
            Line::Assignment { target, value } => self.emit_assignment(bank, target, value, raw),
            Line::Command { label, name, args } => {
                self.emit_command(bank, label.as_deref(), name, args, raw)
            }
        }
    }

    fn define_in_ram(&mut self, bank: Bank, line: &Line, origin: i64) {
        if let Some(label) = line.label() {
            let symbol = expression::sanitize(label);
            self.push(bank, format!("{symbol} = {origin}"));
            self.symbols.insert(symbol, origin);
        }

        let reserved = line
            .command()
            .filter(|(name, _)| is_reservation(name))
            .and_then(|(_, args)| syntax::split_operands(args).into_iter().next())
            .map_or(0, |operand| self.evaluate(&operand).unwrap_or(0));

        self.ram_origin = Some(origin + reserved);
    }

    fn emit_command(&mut self, bank: Bank, label: Option<&str>, name: &str, args: &str, raw: &str) {
        let operation = if name.eq_ignore_ascii_case("JP") {
            "JMP".to_owned()
        } else {
            name.to_ascii_uppercase()
        };

        if !matches!(operation.as_str(), "EQU" | "EQUATE" | "DEFL") {
            if let Some(label) = label {
                self.emit_label(bank, label);
            }
        }

        if OPCODES.contains(&operation.as_str()) {
            let operand = self.operand(args, &operation);
            let instruction = if operand.is_empty() {
                operation
            } else {
                format!("{operation} {operand}")
            };

            self.push(bank, instruction);
            return;
        }

        match operation.as_str() {
            "EQU" | "EQUATE" | "DEFL" => self.emit_equate(bank, label, &operation, args, raw),
            "ORG" => self.emit_origin(bank, args),
            "DB" | "DEFB" | "DFB" | "BYTE" | "EQUB" | "DEFM" | "DM" | "DFM" | "ASCII" | "TEXT"
            | "ASC" | "STR" => self.emit_data(bank, args, DataKind::Bytes),
            "DC" => self.emit_data(bank, args, DataKind::Dc),
            "CBM" => self.emit_data(bank, args, DataKind::Cbm),
            "STRING" => self.emit_data(bank, args, DataKind::String),
            "DW" | "DEFW" | "DFW" | "WORD" => {
                for operand in syntax::split_operands(args) {
                    self.push(bank, format!(".word {}", self.expression_or_raw(&operand)));
                }
            }
            "DL" | "DLOW" => {
                for operand in syntax::split_operands(args) {
                    self.push(
                        bank,
                        format!(".byte <({})", self.expression_or_raw(&operand)),
                    );
                }
            }
            "DH" | "DHIGH" => {
                for operand in syntax::split_operands(args) {
                    self.push(
                        bank,
                        format!(".byte >({})", self.expression_or_raw(&operand)),
                    );
                }
            }
            "DS" | "DEFS" | "DFS" | "BLOCK" => self.emit_reservation(bank, args),
            "HEX" => self.emit_hex(bank, args),
            "INCBIN" => self.emit_incbin(bank, args),
            "ERROR" => self.push(bank, format!("; PDS ERROR: {args}")),
            operation if IGNORED_DIRECTIVES.contains(&operation) => {}
            _ => self.warn(format!("unhandled op {operation}: {raw}")),
        }
    }

    fn emit_equate(
        &mut self,
        bank: Bank,
        label: Option<&str>,
        operation: &str,
        args: &str,
        raw: &str,
    ) {
        let symbol = label.map(expression::sanitize).unwrap_or_default();

        if symbol.is_empty() {
            self.warn(format!("equate without label: {raw}"));
            return;
        }

        let value = self.expression_or_raw(args);
        let directive = if matches!(operation, "=" | "DEFL") && self.evaluate(args).is_some() {
            ".set"
        } else {
            "="
        };

        self.push(bank, format!("{symbol} {directive} {value}"));

        if let Some(value) = self.evaluate(args) {
            self.symbols.insert(symbol, value);
        }
    }

    fn emit_assignment(&mut self, bank: Bank, target: &str, value: &str, raw: &str) {
        let label = (!target.is_empty()).then_some(target);
        self.emit_equate(bank, label, "=", value, raw);
    }

    fn emit_origin(&mut self, bank: Bank, args: &str) {
        let Some(address) = self.evaluate(args) else {
            return;
        };

        if bank == Bank::Prg15 && address == 0xFFF9 {
            self.push(bank, ".segment \"VECTORS\"".to_owned());
            self.push(bank, ".org $FFF9".to_owned());
        } else if bank == Bank::Prg13 && address == 0x86DA {
            self.push(bank, ".segment \"PRG13B\"".to_owned());
        } else if address > bank.base() {
            self.warn(format!(
                "unhandled ORG ${address:04X} in bank {}",
                bank.number()
            ));
        }
    }

    fn emit_data(&mut self, bank: Bank, args: &str, kind: DataKind) {
        for operand in syntax::split_operands(args) {
            let operand = operand.trim();

            if operand.starts_with('"') {
                let text = syntax::parse_string(operand);
                let bytes = encode_text(&text, kind);

                if !bytes.is_empty() {
                    self.emit_byte_list(bank, &bytes);
                }
            } else if !operand.is_empty() {
                if let Some(value) = self.evaluate(operand) {
                    self.push(bank, format!(".byte ${:02X}", value & 0xff));
                } else {
                    let rendered = self.expression_or_raw(operand);

                    if rendered.starts_with('<') || rendered.starts_with('>') {
                        self.push(bank, format!(".byte {rendered}"));
                    } else {
                        self.push(bank, format!(".byte <({rendered})"));
                    }
                }
            }
        }
    }

    fn emit_reservation(&mut self, bank: Bank, args: &str) {
        let operands = syntax::split_operands(args);
        let count = operands
            .first()
            .map_or_else(|| "0".to_owned(), |operand| self.expression_or_raw(operand));
        let fill = operands
            .get(1)
            .map(|operand| self.expression_or_raw(operand));

        let wipes_bank = fill.as_deref() == Some("0")
            && operands
                .first()
                .and_then(|operand| self.evaluate(operand))
                .is_some_and(|size| size >= 0x4000);

        if wipes_bank {
            self.warn("skipping bank-wipe DEFS &4000,0".to_owned());
            return;
        }

        let line = match fill {
            Some(fill) => format!(".res {count}, {fill}"),
            None => format!(".res {count}"),
        };

        self.push(bank, line);
    }

    fn emit_hex(&mut self, bank: Bank, args: &str) {
        let digits: String = args.chars().filter(char::is_ascii_hexdigit).collect();

        let bytes: Vec<String> = digits
            .as_bytes()
            .chunks(2)
            .filter_map(|pair| {
                let pair = std::str::from_utf8(pair).ok()?;
                u8::from_str_radix(pair, 16)
                    .ok()
                    .map(|byte| format!("${byte:02X}"))
            })
            .collect();

        if !bytes.is_empty() {
            self.push(bank, format!(".byte {}", bytes.join(",")));
        }
    }

    fn emit_incbin(&mut self, bank: Bank, args: &str) {
        let name = args.trim().trim_matches('"');
        let path = self
            .resolve(name)
            .unwrap_or_else(|| self.source_dir.join(name));

        self.push(bank, format!(".incbin \"{}\"", absolute(&path)));
    }

    fn emit_byte_list(&mut self, bank: Bank, bytes: &[u8]) {
        let bytes: Vec<String> = bytes.iter().map(|byte| format!("${byte:02X}")).collect();
        self.push(bank, format!(".byte {}", bytes.join(",")));
    }

    fn operand(&self, args: &str, operation: &str) -> String {
        let operand = args.trim();

        if operand.is_empty() {
            return String::new();
        }

        if operand.eq_ignore_ascii_case("A") {
            return "A".to_owned();
        }

        if let Some(immediate) = operand.strip_prefix('#') {
            if let Some(value) = self.evaluate(immediate) {
                if value >= 0xff80 {
                    return format!("#(${:02X})", value & 0xff);
                }
            }

            return format!("#{}", self.expression_or_raw(immediate));
        }

        if operand.starts_with('(') {
            if let Some(index) = operand.find(",X)").or_else(|| operand.find(",x)")) {
                return format!("({},X)", self.expression_or_raw(&operand[1..index]));
            }

            if let Some(index) = operand.find("),Y").or_else(|| operand.find("),y")) {
                return format!("({}),Y", self.expression_or_raw(&operand[1..index]));
            }

            if let Some(index) = operand.rfind(')') {
                let inner = &operand[1..index];

                if operation == "JMP" {
                    return format!("({})", self.expression_or_raw(inner));
                }

                return self.expression_or_raw(inner);
            }
        }

        let lower = operand.to_ascii_lowercase();

        if lower.ends_with(",x") || lower.ends_with(",y") {
            let base = &operand[..operand.len() - 2];
            let index = operand[operand.len() - 1..].to_ascii_uppercase();
            return format!("{},{}", self.expression_or_raw(base), index);
        }

        self.expression_or_raw(operand)
    }

    fn expression_or_raw(&self, source: &str) -> String {
        let trimmed = source.trim();
        let terminated;

        let expression = if matches!(
            trimmed.chars().last(),
            Some('+' | '-' | '*' | '/' | '&' | '!' | '~')
        ) {
            terminated = format!("{trimmed}0");
            terminated.as_str()
        } else {
            trimmed
        };

        expression::render(expression).unwrap_or_else(|| expression::sanitize_raw(expression))
    }
}

fn encode_text(text: &str, kind: DataKind) -> Vec<u8> {
    match kind {
        DataKind::Bytes => text.as_bytes().to_vec(),
        DataKind::Dc => {
            let mut bytes = text.as_bytes().to_vec();

            if let Some(last) = bytes.last_mut() {
                *last |= 0x80;
            }

            bytes
        }
        DataKind::Cbm => text.bytes().map(|byte| byte & 0x3f).collect(),
        DataKind::String => {
            let mut bytes = text.as_bytes().to_vec();
            bytes.push(0);
            bytes
        }
    }
}

fn is_reservation(operation: &str) -> bool {
    matches!(
        operation.to_ascii_uppercase().as_str(),
        "DS" | "DEFS" | "DFS" | "BLOCK"
    )
}

fn absolute(path: &std::path::Path) -> String {
    path.canonicalize()
        .unwrap_or_else(|_| path.to_path_buf())
        .display()
        .to_string()
}
