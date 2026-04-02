use std::fs;
use std::path::Path;

pub fn read(path: &Path) -> String {
    fs::read(path)
        .unwrap_or_default()
        .into_iter()
        .filter_map(decode)
        .collect()
}

pub fn lines(path: &Path) -> Vec<String> {
    read(path)
        .lines()
        .map(|line| line.trim_end_matches('\r').to_owned())
        .collect()
}

fn decode(byte: u8) -> Option<char> {
    match byte {
        0x01 | 0x02 | 0x1a => None,
        b'\r' => Some('\n'),
        b'\t' => Some('\t'),
        byte if byte < 0x20 && byte != b'\n' => None,
        byte => Some(byte as char),
    }
}
