use eframe::egui::ColorImage;
use eframe::egui::{pos2, Rect};

use crate::data::{BlockTables, Map};

const NES_PALETTE: [u32; 64] = [
    0x7C7C7C, 0x0000FC, 0x0000BC, 0x4428BC, 0x940084, 0xA80020, 0xA81000, 0x881400, 0x503000,
    0x007800, 0x006800, 0x005800, 0x004058, 0x000000, 0x000000, 0x000000, 0xBCBCBC, 0x0078F8,
    0x0058F8, 0x6844FC, 0xD800CC, 0xE40058, 0xF83800, 0xE45C10, 0xAC7C00, 0x00B800, 0x00A800,
    0x00A844, 0x008888, 0x000000, 0x000000, 0x000000, 0xF8F8F8, 0x3CBCFC, 0x6888FC, 0x9878F8,
    0xF878F8, 0xF85898, 0xF87858, 0xFCA044, 0xF8B800, 0xB8F818, 0x58D854, 0x58F898, 0x00E8D8,
    0x000000, 0x000000, 0x000000, 0xFCFCFC, 0xA4E4FC, 0xB8B8F8, 0xD8B8F8, 0xF8B8F8, 0xF8A4C0,
    0xF0D0B0, 0xFCE0A8, 0xF8D878, 0xD8F878, 0xB8F8B8, 0xB8F8D8, 0x00FCFC, 0x000000, 0x000000,
    0x000000,
];

pub const CHUNK_STRIPS: usize = 64;

pub fn map_chunk_image(
    map: &Map,
    blocks: &BlockTables,
    first_strip: usize,
    strip_count: usize,
) -> ColorImage {
    let width = strip_count * 16;
    let height = Map::HEIGHT * 16;
    let mut rgba = vec![0u8; width * height * 4];

    for strip in 0..strip_count {
        for row in 0..Map::HEIGHT {
            let block = map.terrain[(first_strip + strip) * Map::HEIGHT + row];
            draw_block(&mut rgba, width, strip * 16, row * 16, block, map, blocks);
        }
    }

    ColorImage::from_rgba_unmultiplied([width, height], &rgba)
}

pub fn block_image(map: &Map, blocks: &BlockTables, block: u8) -> ColorImage {
    let mut rgba = vec![0u8; 16 * 16 * 4];
    draw_block(&mut rgba, 16, 0, 0, block, map, blocks);
    ColorImage::from_rgba_unmultiplied([16, 16], &rgba)
}

pub fn atlas_image(map: &Map, blocks: &BlockTables) -> ColorImage {
    let mut rgba = vec![0u8; 256 * 256 * 4];
    for block in 0..=255u8 {
        let x = (block as usize % 16) * 16;
        let y = (block as usize / 16) * 16;
        draw_block(&mut rgba, 256, x, y, block, map, blocks);
    }
    ColorImage::from_rgba_unmultiplied([256, 256], &rgba)
}

pub fn entity_image(chr: &[u8], palette: &[u8; 4], tiles: &[u8], cols: usize) -> ColorImage {
    let cols = cols.max(1);
    let rows = (tiles.len() + cols - 1) / cols;
    let width = cols * 8;
    let height = rows * 8;
    let mut rgba = vec![0u8; width * height * 4];
    for (index, tile) in tiles.iter().enumerate() {
        let x = (index % cols) * 8;
        let y = (index / cols) * 8;
        draw_tile_colours(&mut rgba, width, x, y, *tile, chr, palette);
    }
    ColorImage::from_rgba_unmultiplied([width, height], &rgba)
}

fn draw_tile_colours(
    pixels: &mut [u8],
    stride: usize,
    x: usize,
    y: usize,
    tile: u8,
    chr: &[u8],
    palette: &[u8; 4],
) {
    let offset = tile as usize * 16;
    for row in 0..8 {
        let plane0 = chr[offset + row];
        let plane1 = chr[offset + 8 + row];
        for column in 0..8 {
            let bit = 7 - column;
            let color = (((plane1 >> bit) & 1) << 1) | ((plane0 >> bit) & 1);
            let nes_index = palette[color as usize] & 0x3F;
            let rgb = NES_PALETTE[nes_index as usize];
            let pixel = ((y + row) * stride + x + column) * 4;
            pixels[pixel] = (rgb >> 16) as u8;
            pixels[pixel + 1] = (rgb >> 8) as u8;
            pixels[pixel + 2] = rgb as u8;
            pixels[pixel + 3] = 255;
        }
    }
}

pub fn atlas_uv(block: u8) -> Rect {
    let x = (block % 16) as f32 * 16.0 / 256.0;
    let y = (block / 16) as f32 * 16.0 / 256.0;
    Rect::from_min_max(pos2(x, y), pos2(x + 16.0 / 256.0, y + 16.0 / 256.0))
}

fn draw_block(
    pixels: &mut [u8],
    stride: usize,
    x: usize,
    y: usize,
    block: u8,
    map: &Map,
    blocks: &BlockTables,
) {
    let palette_index = (blocks.attributes[block as usize] >> 2) as usize & 3;
    let palette_base = palette_index * 4;

    draw_tile(
        pixels,
        stride,
        x,
        y,
        blocks.top_left[block as usize],
        map,
        palette_base,
    );
    draw_tile(
        pixels,
        stride,
        x + 8,
        y,
        blocks.top_right[block as usize],
        map,
        palette_base,
    );
    draw_tile(
        pixels,
        stride,
        x,
        y + 8,
        blocks.bottom_left[block as usize],
        map,
        palette_base,
    );
    draw_tile(
        pixels,
        stride,
        x + 8,
        y + 8,
        blocks.bottom_right[block as usize],
        map,
        palette_base,
    );
}

fn draw_tile(
    pixels: &mut [u8],
    stride: usize,
    x: usize,
    y: usize,
    tile: u8,
    map: &Map,
    palette_base: usize,
) {
    let tile = tile as usize;
    let offset = tile * 16;
    for row in 0..8 {
        let plane0 = map.chr[offset + row];
        let plane1 = map.chr[offset + 8 + row];
        for column in 0..8 {
            let bit = 7 - column;
            let color = (((plane1 >> bit) & 1) << 1) | ((plane0 >> bit) & 1);
            let nes_index = map.palette[palette_base + color as usize] & 0x3F;
            let rgb = NES_PALETTE[nes_index as usize];
            let pixel = ((y + row) * stride + x + column) * 4;
            pixels[pixel] = (rgb >> 16) as u8;
            pixels[pixel + 1] = (rgb >> 8) as u8;
            pixels[pixel + 2] = rgb as u8;
            pixels[pixel + 3] = 255;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renders_every_map_without_panicking() {
        let root = crate::data::find_root().unwrap();
        let project = crate::data::Project::load(&root).unwrap();

        for map in &project.maps {
            let image = map_chunk_image(map, &project.blocks, 0, map.width.min(CHUNK_STRIPS));
            assert_eq!(image.size[1], 224);
            assert!(image.pixels.iter().any(|pixel| pixel.a() != 0));
            let atlas = atlas_image(map, &project.blocks);
            assert_eq!(atlas.size, [256, 256]);
        }
    }

    #[test]
    fn atlas_uv_covers_one_cell() {
        let uv = atlas_uv(0x9C);
        assert!((uv.min.x - 12.0 / 16.0).abs() < f32::EPSILON);
        assert!((uv.min.y - 9.0 / 16.0).abs() < f32::EPSILON);
    }
}
