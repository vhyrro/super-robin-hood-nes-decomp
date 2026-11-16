use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{anyhow, bail, Context, Result};
use serde_json::Value;

pub const HEIGHT: usize = 14;

#[derive(Clone, Debug)]
pub struct BlockTables {
    pub top_left: Vec<u8>,
    pub top_right: Vec<u8>,
    pub bottom_left: Vec<u8>,
    pub bottom_right: Vec<u8>,
    pub attributes: Vec<u8>,
    pub solid: Vec<u8>,
}

#[derive(Clone, Debug)]
pub struct Map {
    pub label: String,
    pub name: String,
    pub width: usize,
    pub offset: u8,
    pub terrain: Vec<u8>,
    pub original: Vec<u8>,
    pub palette: [u8; 16],
    pub chr: Vec<u8>,
    pub alphabet: Vec<(char, u8)>,
}

impl Map {
    pub const HEIGHT: usize = HEIGHT;

    pub fn letter(&self) -> char {
        self.label.chars().last().unwrap_or('?')
    }

    pub fn title(&self) -> String {
        format!(
            "Map {} - {} ({}x{})",
            self.letter().to_ascii_uppercase(),
            self.name,
            self.width,
            HEIGHT
        )
    }
}

pub struct Project {
    pub blocks: BlockTables,
    pub maps: Vec<Map>,
    pub root: PathBuf,
    pub world_path: PathBuf,
    world: Value,
}

#[derive(Clone, Debug)]
struct ChrSource {
    source: String,
    destination: usize,
}

struct MapInfo {
    label: String,
    width: usize,
    offset: u8,
    palette: String,
    character_set: String,
}

impl Project {
    pub fn load(root: &Path) -> Result<Self> {
        Self::load_from(root, &root.join("rewrite/maps/world.json"))
    }

    pub fn load_from(root: &Path, world_path: &Path) -> Result<Self> {
        let world: Value = serde_json::from_str(
            &fs::read_to_string(world_path)
                .with_context(|| format!("reading {}", world_path.display()))?,
        )
        .with_context(|| format!("parsing {}", world_path.display()))?;
        let world_maps = world
            .get("maps")
            .and_then(Value::as_array)
            .ok_or_else(|| anyhow!("{} has no maps array", world_path.display()))?;

        let template_path = root.join("rewrite/maps/mapdata_template.s");
        let template = read_lines(&template_path)?;
        let blocks = BlockTables {
            top_left: section_bytes(&template, "block_strip_top_left")?,
            top_right: section_bytes(&template, "block_strip_top_right")?,
            bottom_left: section_bytes(&template, "block_strip_bottom_left")?,
            bottom_right: section_bytes(&template, "block_strip_bottom_right")?,
            attributes: section_bytes(&template, "block_strip_attributes")?,
            solid: section_bytes(&template, "solidchrs")?,
        };
        for (name, table) in [
            ("block_strip_top_left", &blocks.top_left),
            ("block_strip_top_right", &blocks.top_right),
            ("block_strip_bottom_left", &blocks.bottom_left),
            ("block_strip_bottom_right", &blocks.bottom_right),
            ("block_strip_attributes", &blocks.attributes),
            ("solidchrs", &blocks.solid),
        ] {
            if table.len() != 256 {
                bail!("{name} has {} bytes, expected 256", table.len());
            }
        }

        let (palette_offsets, palettes) = parse_palettes(&template)?;
        let character_sets = parse_character_sets(&template)?;
        let compacted = parse_compacted_chars(root)?;
        let sources = parse_chr_sources(root)?;
        let infos = parse_map_info(root)?;
        let info_by_label: HashMap<_, _> = infos
            .into_iter()
            .map(|info| (info.label.clone(), info))
            .collect();
        let global_blocks = parse_blocks(world.get("blocks"))?;

        let mut cache: HashMap<String, Vec<u8>> = HashMap::new();
        let mut maps = Vec::with_capacity(world_maps.len());
        for (index, entry) in world_maps.iter().enumerate() {
            let label = entry
                .get("label")
                .and_then(Value::as_str)
                .ok_or_else(|| anyhow!("map {index} has no label"))?;
            let info = info_by_label
                .get(label)
                .ok_or_else(|| anyhow!("{label} is not in mapinfo"))?;
            let name = entry
                .get("name")
                .and_then(Value::as_str)
                .unwrap_or(label)
                .to_owned();
            let width = entry
                .get("width")
                .and_then(Value::as_u64)
                .ok_or_else(|| anyhow!("{label} has no width"))? as usize;
            if width != info.width {
                bail!(
                    "{label} width {width} does not match mapinfo width {}",
                    info.width
                );
            }
            let alphabet = parse_alphabet(entry.get("alphabet"))?;
            let rows = entry
                .get("rows")
                .and_then(Value::as_array)
                .ok_or_else(|| anyhow!("{label} has no rows"))?;
            if rows.len() != HEIGHT {
                bail!("{label} has {} rows, expected {HEIGHT}", rows.len());
            }
            let terrain = decode_rows(rows, width, &alphabet, &global_blocks, label)?;
            let original = section_bytes(&template, label)?;
            if original.len() != width * HEIGHT {
                bail!(
                    "{label} template has {} bytes, expected {}",
                    original.len(),
                    width * HEIGHT
                );
            }

            let palette_offset = *palette_offsets
                .get(&info.palette)
                .ok_or_else(|| anyhow!("unknown palette {}", info.palette))?;
            let mut palette = [0u8; 16];
            palette.copy_from_slice(
                palettes
                    .get(palette_offset..palette_offset + 16)
                    .ok_or_else(|| anyhow!("palette {} out of range", info.palette))?,
            );

            let mut chr = vec![0u8; 4096];
            let set = character_sets
                .get(&info.character_set)
                .ok_or_else(|| anyhow!("unknown character set {}", info.character_set))?;
            for source_name in set {
                let entry = compacted
                    .get(source_name)
                    .ok_or_else(|| anyhow!("unknown character descriptor {source_name}"))?;
                let path = sources
                    .get(&entry.source)
                    .ok_or_else(|| anyhow!("no PP1 source for {}", entry.source))?;
                let decoded = match cache.get(&entry.source) {
                    Some(bytes) => bytes.clone(),
                    None => {
                        let packed = fs::read(path)
                            .with_context(|| format!("reading {}", path.display()))?;
                        let bytes = decode_pp1(&packed)?;
                        cache.insert(entry.source.clone(), bytes.clone());
                        bytes
                    }
                };
                let start = entry.destination * 16;
                let end = start + decoded.len();
                if end > chr.len() {
                    bail!("{} overruns CHR memory", entry.source);
                }
                chr[start..end].copy_from_slice(&decoded);
            }

            maps.push(Map {
                label: label.to_owned(),
                name,
                width,
                offset: info.offset,
                terrain,
                original,
                palette,
                chr,
                alphabet,
            });
        }

        if maps.is_empty() {
            bail!("no maps found");
        }

        Ok(Self {
            blocks,
            maps,
            root: root.to_owned(),
            world_path: world_path.to_owned(),
            world,
        })
    }

    pub fn save(&mut self) -> Result<PathBuf> {
        self.sync_rows()?;
        fs::write(
            &self.world_path,
            serde_json::to_string_pretty(&self.world)? + "\n",
        )
        .with_context(|| format!("writing {}", self.world_path.display()))?;
        Ok(self.world_path.clone())
    }

    pub fn export(&mut self, path: &Path) -> Result<PathBuf> {
        self.sync_rows()?;
        fs::write(path, serde_json::to_string_pretty(&self.world)? + "\n")
            .with_context(|| format!("writing {}", path.display()))?;
        Ok(path.to_owned())
    }

    fn sync_rows(&mut self) -> Result<()> {
        let entries = self
            .world
            .get_mut("maps")
            .and_then(Value::as_array_mut)
            .ok_or_else(|| anyhow!("world has no maps array"))?;
        if entries.len() != self.maps.len() {
            bail!("map count changed");
        }
        for (entry, map) in entries.iter_mut().zip(&self.maps) {
            entry["rows"] = Value::Array(encode_rows(map).into_iter().map(Value::String).collect());
        }
        Ok(())
    }
}

pub fn find_root() -> Result<PathBuf> {
    if let Some(root) = std::env::var_os("MAP_EDITOR_ROOT") {
        return Ok(PathBuf::from(root));
    }
    let mut directory = std::env::current_dir()?;
    loop {
        if directory.join("rewrite/maps/world.json").is_file() {
            return Ok(directory);
        }
        if !directory.pop() {
            bail!("could not find the Super Robin Hood repository root");
        }
    }
}

fn read_lines(path: &Path) -> Result<Vec<String>> {
    fs::read_to_string(path)
        .with_context(|| format!("reading {}", path.display()))
        .map(|text| text.split('\n').map(str::to_owned).collect())
}

fn section_lines<'a>(lines: &'a [String], label: &str) -> Result<&'a [String]> {
    let start = lines
        .iter()
        .position(|line| line.trim() == format!("{label}:"))
        .ok_or_else(|| anyhow!("section {label} not found"))?
        + 1;
    let end = lines[start..]
        .iter()
        .position(|line| is_label(line))
        .map_or(lines.len(), |offset| start + offset);
    Ok(&lines[start..end])
}

fn section_bytes(lines: &[String], label: &str) -> Result<Vec<u8>> {
    let mut bytes = Vec::new();
    for line in section_lines(lines, label)? {
        if let Some(values) = byte_values(line) {
            bytes.extend(values);
        }
    }
    Ok(bytes)
}

fn is_label(line: &str) -> bool {
    !line.is_empty()
        && !line.starts_with([' ', '\t'])
        && !line.trim_start().starts_with(';')
        && !line.trim_start().starts_with('*')
        && !line.trim_start().starts_with(".byte")
        && line.trim_end().ends_with(':')
}

fn byte_values(line: &str) -> Option<Vec<u8>> {
    let rest = line.trim_start().strip_prefix(".byte")?;
    let rest = rest.split(';').next().unwrap_or(rest);
    let mut values = Vec::new();
    for token in rest.split(',') {
        let token = token.trim();
        if !token.is_empty() {
            values.push(parse_number(token)?);
        }
    }
    Some(values)
}

fn tokens_after_byte(line: &str) -> Option<Vec<String>> {
    let rest = line.trim_start().strip_prefix(".byte")?;
    let rest = rest.split(';').next().unwrap_or(rest);
    Some(
        rest.split(',')
            .map(str::trim)
            .filter(|token| !token.is_empty())
            .map(str::to_owned)
            .collect(),
    )
}

fn parse_number(token: &str) -> Option<u8> {
    let token = token.trim();
    if let Some(hex) = token.strip_prefix('$') {
        u8::from_str_radix(hex, 16).ok()
    } else if let Some(binary) = token.strip_prefix('%') {
        u8::from_str_radix(binary, 2).ok()
    } else {
        token.parse().ok()
    }
}

fn angle_symbol(token: &str) -> Option<String> {
    let open = token.find('(')?;
    let close = token[open..].find(')')?;
    let inner = &token[open + 1..open + close];
    inner.split_whitespace().next().map(str::to_owned)
}

fn equate_offset(line: &str, suffix: &str) -> Option<String> {
    let (name, value) = line.split_once('=')?;
    let name = name.trim();
    if name.is_empty() || name.contains(char::is_whitespace) {
        return None;
    }
    let normalized = value.split_whitespace().collect::<Vec<_>>().join(" ");
    (normalized == format!("* - {suffix}")).then(|| name.to_owned())
}

fn parse_palettes(lines: &[String]) -> Result<(HashMap<String, usize>, Vec<u8>)> {
    let start = lines
        .iter()
        .position(|line| line.trim() == "gamepallettes:")
        .ok_or_else(|| anyhow!("gamepallettes not found"))?
        + 1;
    let mut offsets = HashMap::new();
    let mut data = Vec::new();
    for line in &lines[start..] {
        if line.trim() == "spritecolours:" {
            break;
        }
        if let Some(name) = equate_offset(line, "gamepallettes") {
            offsets.insert(name, data.len());
            continue;
        }
        if let Some(values) = byte_values(line) {
            data.extend(values);
        }
    }
    Ok((offsets, data))
}

fn parse_character_sets(lines: &[String]) -> Result<HashMap<String, Vec<String>>> {
    let start = lines
        .iter()
        .position(|line| line.trim() == "mapchrsdefs:")
        .ok_or_else(|| anyhow!("mapchrsdefs not found"))?
        + 1;
    let end = lines[start..]
        .iter()
        .position(|line| line.trim() == "gamepallettes:")
        .map_or(lines.len(), |offset| start + offset);
    let mut sets = HashMap::new();
    let mut name = None;
    let mut current = Vec::new();
    for line in &lines[start..end] {
        if let Some(found) = equate_offset(line, "mapchrsdefs") {
            if let Some(previous) = name.replace(found) {
                sets.insert(previous, std::mem::take(&mut current));
            }
            continue;
        }
        let Some(tokens) = tokens_after_byte(line) else {
            continue;
        };
        for token in tokens {
            if token == "$FF" {
                if let Some(finished) = name.take() {
                    sets.insert(finished, std::mem::take(&mut current));
                }
            } else if let Some(symbol) = angle_symbol(&token) {
                current.push(symbol);
            }
        }
    }
    Ok(sets)
}

fn parse_compacted_chars(root: &Path) -> Result<HashMap<String, ChrSource>> {
    let path = root.join("rewrite/bank3/unpack_rou.s");
    let lines = read_lines(&path)?;
    let start = lines
        .iter()
        .position(|line| line.trim() == "compactedchrstable:")
        .ok_or_else(|| anyhow!("compactedchrstable not found"))?
        + 1;
    let mut sources = HashMap::new();
    let mut pending = None;
    let mut fields = Vec::new();
    for line in &lines[start..] {
        if is_label(line) {
            break;
        }
        if let Some((name, _)) = line.split_once('=') {
            if line.contains("compactedchrstable") {
                pending = Some(name.trim().to_owned());
                fields.clear();
                continue;
            }
        }
        let Some(tokens) = tokens_after_byte(line) else {
            continue;
        };
        fields.extend(tokens);
        if fields.len() < 4 || pending.is_none() {
            continue;
        }
        let source = angle_symbol(&fields[0])
            .ok_or_else(|| anyhow!("bad compacted character source: {:?}", fields))?;
        let destination = parse_number(&fields[2])
            .ok_or_else(|| anyhow!("bad compacted character destination: {:?}", fields))?
            as usize;
        sources.insert(
            pending.take().unwrap(),
            ChrSource {
                source,
                destination,
            },
        );
        fields.clear();
    }
    Ok(sources)
}

fn parse_chr_sources(root: &Path) -> Result<HashMap<String, PathBuf>> {
    let mut sources = HashMap::new();
    for relative in ["rewrite/bank2/chrsets_chr.s", "rewrite/bank2/cmlogo_rou.s"] {
        let path = root.join(relative);
        let lines = read_lines(&path)?;
        let mut label = None;
        for line in &lines {
            let trimmed = line.trim();
            if let Some(name) = trimmed.strip_suffix(':') {
                if !name.contains(char::is_whitespace) {
                    label = Some(name.to_owned());
                }
                continue;
            }
            if let Some(rest) = trimmed.strip_prefix(".incbin") {
                let Some(name) = &label else { continue };
                let file = rest.trim().trim_matches('"').replace('\\', "/");
                let path = PathBuf::from(file);
                let path = if path.is_absolute() {
                    path
                } else {
                    root.join("rewrite").join(path)
                };
                sources.insert(name.clone(), path);
            }
        }
    }
    Ok(sources)
}

fn parse_map_info(root: &Path) -> Result<Vec<MapInfo>> {
    let path = root.join("rewrite/bank3/mapscrol_rou.s");
    let lines = read_lines(&path)?;
    let start = lines
        .iter()
        .position(|line| line.trim() == "mapinfo:")
        .ok_or_else(|| anyhow!("mapinfo not found"))?
        + 1;
    let end = lines[start..]
        .iter()
        .position(|line| line.trim() == "tuneforstrip:")
        .map_or(lines.len(), |offset| start + offset);
    let mut values = Vec::new();
    for line in &lines[start..end] {
        let Some(tokens) = tokens_after_byte(line) else {
            continue;
        };
        for token in tokens {
            if let Some(number) = parse_number(&token) {
                values.push((Some(number), None));
            } else if let Some(symbol) = angle_symbol(&token) {
                values.push((None, Some(symbol)));
            } else {
                bail!("cannot parse mapinfo token {token:?}");
            }
        }
    }
    if values.len() % 6 != 0 {
        bail!(
            "mapinfo has {} values, expected a multiple of 6",
            values.len()
        );
    }
    let mut infos = Vec::new();
    for entry in values.chunks(6) {
        let label = entry[0]
            .1
            .clone()
            .ok_or_else(|| anyhow!("mapinfo entry has no map label"))?;
        let offset = entry[2].0.ok_or_else(|| anyhow!("{label} has no offset"))?;
        let width = entry[3].0.ok_or_else(|| anyhow!("{label} has no width"))? as usize;
        let palette = entry[4]
            .1
            .clone()
            .ok_or_else(|| anyhow!("{label} has no palette"))?;
        let character_set = entry[5]
            .1
            .clone()
            .ok_or_else(|| anyhow!("{label} has no charset"))?;
        infos.push(MapInfo {
            label,
            width,
            offset,
            palette,
            character_set,
        });
    }
    Ok(infos)
}

fn parse_blocks(value: Option<&Value>) -> Result<HashMap<String, u8>> {
    let mut blocks = HashMap::new();
    if let Some(object) = value.and_then(Value::as_object) {
        for (name, value) in object {
            let id = value
                .as_u64()
                .ok_or_else(|| anyhow!("block {name} must be an integer"))?;
            if id > 255 {
                bail!("block {name} is outside 0..255");
            }
            blocks.insert(name.clone(), id as u8);
        }
    }
    Ok(blocks)
}

fn parse_alphabet(value: Option<&Value>) -> Result<Vec<(char, u8)>> {
    let mut alphabet = Vec::new();
    if let Some(object) = value.and_then(Value::as_object) {
        for (symbol, value) in object {
            let mut chars = symbol.chars();
            let Some(symbol) = chars.next() else { continue };
            if chars.next().is_some() {
                bail!("alphabet symbol {symbol:?} must be one character");
            }
            let id = value
                .as_u64()
                .ok_or_else(|| anyhow!("alphabet symbol {symbol:?} must map to an integer"))?;
            if id > 255 {
                bail!("alphabet symbol {symbol:?} is outside 0..255");
            }
            alphabet.push((symbol, id as u8));
        }
    }
    Ok(alphabet)
}

fn decode_rows(
    rows: &[Value],
    width: usize,
    alphabet: &[(char, u8)],
    blocks: &HashMap<String, u8>,
    label: &str,
) -> Result<Vec<u8>> {
    let mut decoded = vec![0u8; width * HEIGHT];
    for (row_index, row) in rows.iter().enumerate() {
        let row = row
            .as_str()
            .ok_or_else(|| anyhow!("{label} row {row_index} must be a string"))?;
        let values = decode_row(row, alphabet, blocks, label, row_index)?;
        if values.len() != width {
            bail!(
                "{label} row {row_index} has {} blocks, expected {width}",
                values.len()
            );
        }
        for (strip, value) in values.into_iter().enumerate() {
            decoded[strip * HEIGHT + row_index] = value;
        }
    }
    Ok(decoded)
}

fn decode_row(
    row: &str,
    alphabet: &[(char, u8)],
    blocks: &HashMap<String, u8>,
    label: &str,
    row_index: usize,
) -> Result<Vec<u8>> {
    if row.chars().any(char::is_whitespace) {
        return row
            .split_whitespace()
            .map(|token| resolve_token(token, alphabet, blocks, label))
            .collect();
    }
    let chars: Vec<char> = row.chars().collect();
    let mut values = Vec::new();
    let mut index = 0;
    while index < chars.len() {
        if chars[index] == '$' {
            if index + 2 >= chars.len() {
                bail!("{label} row {row_index} has an invalid $XX escape");
            }
            let hex: String = chars[index + 1..index + 3].iter().collect();
            values.push(
                u8::from_str_radix(&hex, 16).with_context(|| format!("{label} row {row_index}"))?,
            );
            index += 3;
            continue;
        }
        let symbol = chars[index];
        let value = alphabet
            .iter()
            .find_map(|(candidate, value)| (*candidate == symbol).then_some(*value))
            .ok_or_else(|| {
                anyhow!("{label} row {row_index} symbol {symbol:?} is not in the alphabet")
            })?;
        values.push(value);
        index += 1;
    }
    Ok(values)
}

fn resolve_token(
    token: &str,
    alphabet: &[(char, u8)],
    blocks: &HashMap<String, u8>,
    label: &str,
) -> Result<u8> {
    if let Some(hex) = token.strip_prefix('$') {
        return u8::from_str_radix(hex, 16).with_context(|| format!("{label}: {token}"));
    }
    if let Some(hex) = token.strip_prefix("0x") {
        return u8::from_str_radix(hex, 16).with_context(|| format!("{label}: {token}"));
    }
    if let Ok(value) = token.parse::<u8>() {
        return Ok(value);
    }
    if let Some((_, value)) = alphabet
        .iter()
        .find(|(symbol, _)| symbol.to_string() == token)
    {
        return Ok(*value);
    }
    blocks
        .get(token)
        .copied()
        .ok_or_else(|| anyhow!("{label}: unknown block token {token:?}"))
}

fn encode_rows(map: &Map) -> Vec<String> {
    let mut reverse = HashMap::new();
    for (symbol, value) in &map.alphabet {
        reverse.entry(*value).or_insert(*symbol);
    }
    (0..HEIGHT)
        .map(|row| {
            (0..map.width)
                .map(|strip| {
                    let value = map.terrain[strip * HEIGHT + row];
                    reverse
                        .get(&value)
                        .map(char::to_string)
                        .unwrap_or_else(|| format!("${value:02X}"))
                })
                .collect()
        })
        .collect()
}

fn decode_pp1(data: &[u8]) -> Result<Vec<u8>> {
    if data.is_empty() {
        bail!("empty PP1 file");
    }
    let count = if data[0] == 0 { 256 } else { data[0] as usize };
    let mut bits = Bits::new(data);
    let mut types = [0u8; 4];
    let mut fold1 = [0u8; 4];
    let mut fold2 = [0u8; 4];
    let mut fold3 = [0u8; 4];
    let mut output = Vec::with_capacity(count * 16);
    let mut previous = (0u8, 0u8);
    for _ in 0..count {
        if bits.bit() == 0 {
            for index in (0..4).rev() {
                let kind = bits.bits2();
                types[index] = kind;
                match kind {
                    0 => {}
                    1 => fold1[index] = type1(&mut bits, index),
                    2 => {
                        let value = type3(&mut bits, index, &mut fold1, &mut fold2);
                        if bits.bit() == 1 {
                            fold2[index] = value;
                        }
                    }
                    _ => fold3[index] = type3(&mut bits, index, &mut fold1, &mut fold2),
                }
            }
        }
        let mut plane1 = [0u8; 8];
        for slot in &mut plane1 {
            if bits.bit() == 1 {
                let (first, second) = previous;
                previous = (first, second);
            } else {
                let mut value = bits.bits2();
                let mut first = value;
                let mut second = (value >> 1) | 2;
                for _ in 0..7 {
                    match types[value as usize] {
                        1 => {
                            if bits.bit() == 0 {
                                value = fold1[value as usize];
                            }
                        }
                        2 => {
                            if bits.bit() == 0 {
                                value = if bits.bit() == 1 {
                                    fold2[value as usize]
                                } else {
                                    fold1[value as usize]
                                };
                            }
                        }
                        3 if bits.bit() == 0 => {
                            if bits.bit() == 0 {
                                value = if bits.bit() == 1 {
                                    fold3[value as usize]
                                } else {
                                    fold2[value as usize]
                                };
                            } else {
                                value = fold1[value as usize];
                            }
                        }
                        _ => {}
                    }
                    first = first.wrapping_shl(1) | (value & 1);
                    second = second.wrapping_shl(1) | (value >> 1);
                }
                previous = (first, second);
            }
            *slot = previous.1;
            output.push(previous.0);
        }
        output.extend_from_slice(&plane1);
    }
    Ok(output)
}

const FC3: [u8; 4] = [3, 3, 3, 2];
const FC2: [u8; 4] = [2, 2, 1, 1];
const FC1: [u8; 4] = [1, 0, 0, 0];
const F1L: [u8; 4] = [2, 0xFF, 0, 0];
const F2H: [u8; 4] = [3, 3, 0xFF, 1];

fn type1(bits: &mut Bits<'_>, index: usize) -> u8 {
    if bits.bit() == 1 {
        FC1[index]
    } else if bits.bit() == 1 {
        FC3[index]
    } else {
        FC2[index]
    }
}

fn type3(bits: &mut Bits<'_>, index: usize, fold1: &mut [u8; 4], fold2: &mut [u8; 4]) -> u8 {
    let value = type1(bits, index) as usize;
    fold1[index] = value as u8;
    let (low, high): (&[u8; 4], &[u8; 4]) = match value {
        0 => (&FC2, &FC3),
        1 => (&F1L, &FC3),
        2 => (&FC1, &F2H),
        _ => (&FC1, &FC2),
    };
    fold2[index] = low[index];
    high[index]
}

struct Bits<'a> {
    data: &'a [u8],
    position: usize,
    value: u8,
}

impl<'a> Bits<'a> {
    fn new(data: &'a [u8]) -> Self {
        Self {
            data,
            position: 1,
            value: 0x80,
        }
    }

    fn bit(&mut self) -> u8 {
        let mut carry = self.value >> 7;
        self.value <<= 1;
        if self.value == 0 {
            self.value = self.data.get(self.position).copied().unwrap_or(0);
            self.position += 1;
            carry = self.value >> 7;
            self.value = (self.value << 1) | 1;
        }
        carry
    }

    fn bits2(&mut self) -> u8 {
        (self.bit() << 1) | self.bit()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decodes_known_pp1_block() {
        let packed = [
            0x01, 0x20, 0xA3, 0x5E, 0x53, 0x94, 0x16, 0xA9, 0xF8, 0xBF, 0xE0,
        ];
        let expected = [
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x9F, 0x6F, 0x6A, 0x6A, 0x99, 0xFA,
            0xFA, 0xFF,
        ];
        assert_eq!(decode_pp1(&packed).unwrap(), expected);
    }

    #[test]
    fn loads_every_json_map() {
        let root = find_root().unwrap();
        let project = Project::load(&root).unwrap();
        assert_eq!(project.maps.len(), 13);
        let map = project
            .maps
            .iter()
            .find(|map| map.label == "map_f")
            .unwrap();
        assert_eq!(map.width, 208);
        assert_eq!(map.terrain.len(), 208 * HEIGHT);
        assert_eq!(map.original.len(), map.terrain.len());
        assert!(map.chr.iter().any(|byte| *byte != 0));
    }

    #[test]
    fn decodes_compact_and_token_rows() {
        let alphabet = vec![('.', 0), ('#', 4)];
        assert_eq!(
            decode_row(".#$05", &alphabet, &HashMap::new(), "test", 0).unwrap(),
            vec![0, 4, 5]
        );
        assert_eq!(
            decode_row(". # $05", &alphabet, &HashMap::new(), "test", 0).unwrap(),
            vec![0, 4, 5]
        );
    }

    #[test]
    fn export_and_import_round_trip() {
        let root = find_root().unwrap();
        let mut project = Project::load(&root).unwrap();
        project.maps[0].terrain[0] = 0xA5;
        let path =
            std::env::temp_dir().join(format!("srh-map-editor-{}-world.json", std::process::id()));
        project.export(&path).unwrap();

        let reloaded = Project::load_from(&root, &path).unwrap();
        assert_eq!(reloaded.maps[0].terrain, project.maps[0].terrain);
        fs::remove_file(path).unwrap();
    }
}
