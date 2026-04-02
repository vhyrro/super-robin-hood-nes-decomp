use super::Symbols;

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Expr {
    Number(i64),
    Symbol(String),
    ProgramCounter,
    Text(String),
    LowByte(Box<Expr>),
    HighByte(Box<Expr>),
    Negated(Box<Expr>),
    Binary(BinaryOp, Box<Expr>, Box<Expr>),
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum BinaryOp {
    Or,
    Xor,
    And,
    Equal,
    NotEqual,
    Greater,
    Less,
    Add,
    Subtract,
    Multiply,
    Divide,
}

impl BinaryOp {
    pub const fn precedence(self) -> u8 {
        match self {
            Self::Or | Self::Xor => 1,
            Self::And => 2,
            Self::Equal | Self::NotEqual | Self::Greater | Self::Less => 3,
            Self::Add | Self::Subtract => 4,
            Self::Multiply | Self::Divide => 5,
        }
    }

    pub const fn spelling(self) -> &'static str {
        match self {
            Self::Or => "|",
            Self::Xor => "^",
            Self::And => "&",
            Self::Equal => "=",
            Self::NotEqual => "<>",
            Self::Greater => ">",
            Self::Less => "<",
            Self::Add => "+",
            Self::Subtract => "-",
            Self::Multiply => "*",
            Self::Divide => "/",
        }
    }
}

impl Expr {
    pub fn evaluate(&self, symbols: &Symbols) -> Option<i64> {
        Some(match self {
            Self::Number(value) => *value,
            Self::ProgramCounter => return None,
            Self::Text(text) => {
                let bytes = text.as_bytes();
                let low = *bytes.first()? as i64;
                let high = bytes.get(1).map_or(0, |byte| *byte as i64);
                low | (high << 8)
            }
            Self::Symbol(name) => *symbols.get(&super::sanitize(name))?,
            Self::LowByte(expression) => expression.evaluate(symbols)? & 0xff,
            Self::HighByte(expression) => (expression.evaluate(symbols)? >> 8) & 0xff,
            Self::Negated(expression) => (-expression.evaluate(symbols)?) & 0xffff,
            Self::Binary(operator, left, right) => {
                let left = left.evaluate(symbols)?;
                let right = right.evaluate(symbols)?;

                match operator {
                    BinaryOp::Add => left.wrapping_add(right) & 0xffff,
                    BinaryOp::Subtract => left.wrapping_sub(right) & 0xffff,
                    BinaryOp::Multiply => left.wrapping_mul(right) & 0xffff,
                    BinaryOp::Divide => {
                        if right == 0 {
                            return None;
                        }
                        (left / right) & 0xffff
                    }
                    BinaryOp::And => left & right,
                    BinaryOp::Or => left | right,
                    BinaryOp::Xor => left ^ right,
                    BinaryOp::Equal => i64::from(left == right),
                    BinaryOp::NotEqual => i64::from(left != right),
                    BinaryOp::Greater => i64::from(left > right),
                    BinaryOp::Less => i64::from(left < right),
                }
            }
        })
    }

    pub fn render(&self) -> String {
        self.render_precedence(0)
    }

    fn render_precedence(&self, parent_precedence: u8) -> String {
        match self {
            Self::Number(value) if *value < 0 => format!("({value})"),
            Self::Number(value) => value.to_string(),
            Self::Symbol(name) => super::sanitize(name),
            Self::ProgramCounter => "*".to_owned(),
            Self::Text(text) => format!("\"{}\"", text.replace('"', "\"\"")),
            Self::LowByte(expression) => format!("<({})", expression.render()),
            Self::HighByte(expression) => format!(">({})", expression.render()),
            Self::Negated(expression) => format!("(-{})", expression.render()),
            Self::Binary(operator, left, right) => {
                let precedence = operator.precedence();
                let rendered = format!(
                    "{} {} {}",
                    left.render_precedence(precedence),
                    operator.spelling(),
                    right.render_precedence(precedence + 1)
                );

                if precedence < parent_precedence {
                    format!("({rendered})")
                } else {
                    rendered
                }
            }
        }
    }
}
