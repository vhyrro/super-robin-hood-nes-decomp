#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd)]
pub enum Bank {
    Prg12,
    Prg13,
    Prg14,
    Prg15,
}

impl Bank {
    pub const ALL: [Self; 4] = [Self::Prg12, Self::Prg13, Self::Prg14, Self::Prg15];

    pub const fn number(self) -> u8 {
        match self {
            Self::Prg12 => 12,
            Self::Prg13 => 13,
            Self::Prg14 => 14,
            Self::Prg15 => 15,
        }
    }

    pub const fn base(self) -> i64 {
        match self {
            Self::Prg15 => 0xC004,
            Self::Prg12 | Self::Prg13 | Self::Prg14 => 0x8000,
        }
    }

    pub const fn segment(self) -> &'static str {
        match self {
            Self::Prg12 => "PRG12",
            Self::Prg13 => "PRG13",
            Self::Prg14 => "PRG14",
            Self::Prg15 => "PRG15",
        }
    }
}
