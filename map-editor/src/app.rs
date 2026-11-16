use std::collections::VecDeque;
use std::path::Path;

use eframe::egui::{
    self, pos2, vec2, Align2, Color32, FontId, Key, PointerButton, Rect, Sense, Stroke,
    TextureHandle, TextureOptions, Vec2,
};

use crate::data::{Map, Project};
use crate::render;

const MIN_ZOOM: f32 = 0.25;
const MAX_ZOOM: f32 = 8.0;
const HISTORY_LIMIT: usize = 100;

struct MapState {
    textures: Vec<TextureHandle>,
    atlas: TextureHandle,
    original: Vec<u8>,
    undo: VecDeque<Vec<u8>>,
    redo: VecDeque<Vec<u8>>,
    dirty: bool,
}

pub struct EditorApp {
    project: Project,
    states: Vec<MapState>,
    io_path: String,
    current: usize,
    selected: u8,
    search: String,
    zoom: f32,
    pan: Vec2,
    grid: bool,
    fit_requested: bool,
    painting: bool,
    last_cell: Option<(usize, usize)>,
    notice: String,
    close_dialog: bool,
    allow_close: bool,
}

fn build_states(context: &eframe::CreationContext<'_>, project: &Project) -> Vec<MapState> {
    let mut states = Vec::with_capacity(project.maps.len());
    for map in &project.maps {
        let mut textures = Vec::new();
        for (chunk, first_strip) in (0..map.width).step_by(render::CHUNK_STRIPS).enumerate() {
            let strip_count = render::CHUNK_STRIPS.min(map.width - first_strip);
            textures.push(context.egui_ctx.load_texture(
                format!("map-{}-{chunk}", map.label),
                render::map_chunk_image(map, &project.blocks, first_strip, strip_count),
                TextureOptions::NEAREST,
            ));
        }
        let atlas = context.egui_ctx.load_texture(
            format!("atlas-{}", map.label),
            render::atlas_image(map, &project.blocks),
            TextureOptions::NEAREST,
        );
        states.push(MapState {
            textures,
            atlas,
            original: map.original.clone(),
            undo: VecDeque::new(),
            redo: VecDeque::new(),
            dirty: false,
        });
    }
    states
}

fn build_states_from_context(context: &egui::Context, project: &Project) -> Vec<MapState> {
    let mut states = Vec::with_capacity(project.maps.len());
    for map in &project.maps {
        let mut textures = Vec::new();
        for (chunk, first_strip) in (0..map.width).step_by(render::CHUNK_STRIPS).enumerate() {
            let strip_count = render::CHUNK_STRIPS.min(map.width - first_strip);
            textures.push(context.load_texture(
                format!("map-{}-{chunk}", map.label),
                render::map_chunk_image(map, &project.blocks, first_strip, strip_count),
                TextureOptions::NEAREST,
            ));
        }
        let atlas = context.load_texture(
            format!("atlas-{}", map.label),
            render::atlas_image(map, &project.blocks),
            TextureOptions::NEAREST,
        );
        states.push(MapState {
            textures,
            atlas,
            original: map.original.clone(),
            undo: VecDeque::new(),
            redo: VecDeque::new(),
            dirty: false,
        });
    }
    states
}

impl EditorApp {
    pub fn new(context: &eframe::CreationContext<'_>, project: Project) -> Self {
        let states = build_states(context, &project);
        let current = project
            .maps
            .iter()
            .position(|map| map.label == "map_g")
            .unwrap_or(0);
        let selected = project.maps[current]
            .terrain
            .iter()
            .copied()
            .find(|block| *block != 0)
            .unwrap_or(0);
        let io_path = project.world_path.display().to_string();

        Self {
            project,
            states,
            io_path,
            current,
            selected,
            search: String::new(),
            zoom: 2.0,
            pan: vec2(16.0, 16.0),
            grid: true,
            fit_requested: false,
            painting: false,
            last_cell: None,
            notice: String::new(),
            close_dialog: false,
            allow_close: false,
        }
    }

    fn map(&self) -> &Map {
        &self.project.maps[self.current]
    }

    fn title(&self) -> String {
        format!(
            "Super Robin Hood Map Editor - {}{}",
            self.map().title(),
            if self.states[self.current].dirty {
                " *"
            } else {
                ""
            }
        )
    }

    fn any_dirty(&self) -> bool {
        self.states.iter().any(|state| state.dirty)
    }

    fn refresh_texture(&mut self, index: usize) {
        let map = &self.project.maps[index];
        let chunk_count = self.states[index].textures.len();
        for chunk in 0..chunk_count {
            let first_strip = chunk * render::CHUNK_STRIPS;
            let strip_count = render::CHUNK_STRIPS.min(map.width - first_strip);
            let image =
                render::map_chunk_image(map, &self.project.blocks, first_strip, strip_count);
            self.states[index].textures[chunk].set(image, TextureOptions::NEAREST);
        }
    }

    fn set_cell(&mut self, strip: usize, row: usize, block: u8) -> bool {
        let map = &mut self.project.maps[self.current];
        if strip >= map.width || row >= Map::HEIGHT {
            return false;
        }

        let index = strip * Map::HEIGHT + row;
        if map.terrain[index] == block {
            return false;
        }
        map.terrain[index] = block;

        let chunk = strip / render::CHUNK_STRIPS;
        let local_strip = strip % render::CHUNK_STRIPS;
        let image = render::block_image(map, &self.project.blocks, block);
        self.states[self.current].textures[chunk].set_partial(
            [local_strip * 16, row * 16],
            image,
            TextureOptions::NEAREST,
        );
        self.states[self.current].dirty = true;
        true
    }

    fn begin_stroke(&mut self) {
        if self.painting {
            return;
        }
        let state = &mut self.states[self.current];
        state
            .undo
            .push_back(self.project.maps[self.current].terrain.clone());
        if state.undo.len() > HISTORY_LIMIT {
            state.undo.pop_front();
        }
        state.redo.clear();
        self.painting = true;
        self.last_cell = None;
    }

    fn stroke_to(&mut self, cell: (usize, usize), block: u8) {
        self.begin_stroke();

        if let Some(previous) = self.last_cell {
            for point in line_cells(previous, cell) {
                self.set_cell(point.0, point.1, block);
            }
        } else {
            self.set_cell(cell.0, cell.1, block);
        }

        self.last_cell = Some(cell);
    }

    fn undo(&mut self) {
        let terrain = self.project.maps[self.current].terrain.clone();
        let state = &mut self.states[self.current];
        let Some(previous) = state.undo.pop_back() else {
            self.notice = "Nothing to undo".to_owned();
            return;
        };
        state.redo.push_back(terrain);
        self.project.maps[self.current].terrain = previous;
        state.dirty = true;
        self.refresh_texture(self.current);
        self.notice = "Undo".to_owned();
    }

    fn redo(&mut self) {
        let terrain = self.project.maps[self.current].terrain.clone();
        let state = &mut self.states[self.current];
        let Some(next) = state.redo.pop_back() else {
            self.notice = "Nothing to redo".to_owned();
            return;
        };
        state.undo.push_back(terrain);
        self.project.maps[self.current].terrain = next;
        state.dirty = true;
        self.refresh_texture(self.current);
        self.notice = "Redo".to_owned();
    }

    fn revert(&mut self) {
        let original = self.states[self.current].original.clone();
        self.project.maps[self.current].terrain = original;
        let state = &mut self.states[self.current];
        state.undo.clear();
        state.redo.clear();
        state.dirty = false;
        self.refresh_texture(self.current);
        self.notice = "Reverted map".to_owned();
    }

    fn save(&mut self) -> bool {
        match self.project.save() {
            Ok(path) => {
                for state in &mut self.states {
                    state.dirty = false;
                }
                self.io_path = path.display().to_string();
                self.notice = format!("Saved {}", path.display());
                true
            }
            Err(error) => {
                self.notice = format!("Save failed: {error}");
                false
            }
        }
    }

    fn save_all(&mut self) -> bool {
        self.save()
    }

    fn import(&mut self, context: &egui::Context, path: &Path) {
        match Project::load_from(&self.project.root, path) {
            Ok(project) => {
                self.states = build_states_from_context(context, &project);
                let current = project
                    .maps
                    .iter()
                    .position(|map| map.label == "map_g")
                    .unwrap_or(0);
                let selected = project.maps[current]
                    .terrain
                    .iter()
                    .copied()
                    .find(|block| *block != 0)
                    .unwrap_or(0);
                self.project = project;
                self.current = current;
                self.selected = selected;
                self.io_path = path.display().to_string();
                self.notice = format!("Imported {}", path.display());
            }
            Err(error) => self.notice = format!("Import failed: {error}"),
        }
    }

    fn export(&mut self, path: &Path) {
        match self.project.export(path) {
            Ok(path) => self.notice = format!("Exported {}", path.display()),
            Err(error) => self.notice = format!("Export failed: {error}"),
        }
    }

    fn switch_map(&mut self, index: usize) {
        if index == self.current || index >= self.project.maps.len() {
            return;
        }
        self.current = index;
        self.painting = false;
        self.last_cell = None;
        self.pan = vec2(16.0, 16.0);
        self.zoom = 2.0;
        self.notice = format!("Opened {}", self.map().title());
    }

    fn toolbar(&mut self, ui: &mut egui::Ui) {
        egui::Panel::top("toolbar").show(ui, |ui| {
            ui.add_space(3.0);
            ui.horizontal(|ui| {
                ui.heading("Super Robin Hood");
                ui.separator();

                let mut selected_map = self.current;
                egui::ComboBox::from_id_salt("map-select")
                    .selected_text(self.map().title())
                    .width(250.0)
                    .show_ui(ui, |ui| {
                        for (index, map) in self.project.maps.iter().enumerate() {
                            ui.selectable_value(&mut selected_map, index, map.title());
                        }
                    });
                if selected_map != self.current {
                    self.switch_map(selected_map);
                }

                ui.separator();
                if ui
                    .add_enabled(self.states[self.current].dirty, egui::Button::new("Save"))
                    .clicked()
                {
                    self.save();
                }
                if ui.button("Revert").clicked() {
                    self.revert();
                }
                ui.separator();
                if ui
                    .add_enabled(
                        !self.states[self.current].undo.is_empty(),
                        egui::Button::new("Undo"),
                    )
                    .clicked()
                {
                    self.undo();
                }
                if ui
                    .add_enabled(
                        !self.states[self.current].redo.is_empty(),
                        egui::Button::new("Redo"),
                    )
                    .clicked()
                {
                    self.redo();
                }
                ui.separator();
                if ui.button("Fit").clicked() {
                    self.fit_requested = true;
                }
                ui.checkbox(&mut self.grid, "Grid");
            });
            ui.horizontal(|ui| {
                ui.label("JSON");
                ui.add(
                    egui::TextEdit::singleline(&mut self.io_path)
                        .desired_width(280.0)
                        .hint_text("path to world.json"),
                );
                let mut import = false;
                let mut export = false;
                if ui.button("Import").clicked() {
                    import = true;
                }
                if ui.button("Export").clicked() {
                    export = true;
                }
                if import {
                    let path = std::path::PathBuf::from(self.io_path.trim());
                    self.import(ui.ctx(), &path);
                }
                if export {
                    let path = std::path::PathBuf::from(self.io_path.trim());
                    self.export(&path);
                }
            });
            ui.add_space(3.0);
        });
    }

    fn blocks_panel(&mut self, ui: &mut egui::Ui) {
        egui::Panel::right("blocks")
            .default_size(320.0)
            .min_size(240.0)
            .show(ui, |ui| {
                ui.add_space(6.0);
                ui.heading("Blocks");
                ui.label(format!("Map offset: {} strips", self.map().offset));
                ui.horizontal(|ui| {
                    let atlas = &self.states[self.current].atlas;
                    let (rect, _) = ui.allocate_exact_size(vec2(64.0, 64.0), Sense::hover());
                    ui.painter().image(
                        atlas.id(),
                        rect,
                        render::atlas_uv(self.selected),
                        Color32::WHITE,
                    );
                    ui.vertical(|ui| {
                        ui.label(format!("Selected: ${:02X}", self.selected));
                        ui.label(format!("Decimal: {}", self.selected));
                        if ui.button("Erase block ($00)").clicked() {
                            self.selected = 0;
                        }
                    });
                });

                ui.add_space(4.0);
                egui::TextEdit::singleline(&mut self.search)
                    .hint_text("Filter: $9C, 9C, or 156")
                    .desired_width(f32::INFINITY)
                    .show(ui);

                ui.separator();
                let filter = block_filter(&self.search);
                egui::ScrollArea::vertical().show(ui, |ui| {
                    ui.horizontal_wrapped(|ui| {
                        for block in 0..=255u8 {
                            if !filter(block) {
                                continue;
                            }
                            let atlas = &self.states[self.current].atlas;
                            let (rect, response) =
                                ui.allocate_exact_size(vec2(38.0, 38.0), Sense::click());
                            ui.painter().image(
                                atlas.id(),
                                rect,
                                render::atlas_uv(block),
                                Color32::WHITE,
                            );
                            if block == self.selected {
                                ui.painter().rect_stroke(
                                    rect,
                                    1.0,
                                    Stroke::new(2.0, Color32::YELLOW),
                                    egui::StrokeKind::Inside,
                                );
                            }
                            let label_position = rect.right_bottom() + vec2(-2.0, -1.0);
                            ui.painter().text(
                                label_position + vec2(1.0, 1.0),
                                Align2::RIGHT_BOTTOM,
                                format!("{block:02X}"),
                                FontId::monospace(8.0),
                                Color32::BLACK,
                            );
                            ui.painter().text(
                                label_position,
                                Align2::RIGHT_BOTTOM,
                                format!("{block:02X}"),
                                FontId::monospace(8.0),
                                Color32::WHITE,
                            );
                            if response.clicked() {
                                self.selected = block;
                            }
                            response.on_hover_text(format!("Block ${block:02X} ({block})"));
                        }
                    });
                });
            });
    }

    fn canvas(&mut self, ui: &mut egui::Ui) {
        egui::CentralPanel::default().show(ui, |ui| {
            let size = ui.available_size();
            let (response, painter) = ui.allocate_painter(size, Sense::click_and_drag());
            let canvas = response.rect;
            painter.rect_filled(canvas, 0.0, Color32::from_gray(24));

            let map_width = self.project.maps[self.current].width;
            let map_title = self.project.maps[self.current].title();
            let map_size = vec2(map_width as f32 * 16.0, Map::HEIGHT as f32 * 16.0);
            if self.fit_requested {
                let available = (canvas.size() - vec2(32.0, 32.0)).max(Vec2::splat(1.0));
                self.zoom = (available.x / map_size.x)
                    .min(available.y / map_size.y)
                    .clamp(MIN_ZOOM, MAX_ZOOM);
                self.pan = (canvas.size() - map_size * self.zoom) / 2.0;
                self.fit_requested = false;
            }
            let view = Rect::from_min_size(canvas.min + self.pan, map_size * self.zoom);
            let painter = painter.with_clip_rect(canvas);
            let uv = Rect::from_min_max(pos2(0.0, 0.0), pos2(1.0, 1.0));
            for (chunk, texture) in self.states[self.current].textures.iter().enumerate() {
                let first_strip = chunk * render::CHUNK_STRIPS;
                let strip_count = render::CHUNK_STRIPS.min(map_width - first_strip);
                let origin = view.min + vec2(first_strip as f32 * 16.0 * self.zoom, 0.0);
                let size = vec2(strip_count as f32 * 16.0 * self.zoom, view.height());
                painter.image(
                    texture.id(),
                    Rect::from_min_size(origin, size),
                    uv,
                    Color32::WHITE,
                );
            }

            let pointer = ui.input(|input| input.pointer.hover_pos());
            let hovered = pointer
                .and_then(|position| cell_at(position, canvas, self.pan, self.zoom, map_width));

            if self.grid && self.zoom * 16.0 >= 10.0 {
                let stroke = Stroke::new(1.0, Color32::from_black_alpha(55));
                let first_strip = ((canvas.left() - view.left()) / (16.0 * self.zoom))
                    .floor()
                    .max(0.0) as usize;
                let last_strip = ((canvas.right() - view.left()) / (16.0 * self.zoom))
                    .ceil()
                    .min(map_width as f32) as usize;
                for strip in first_strip..=last_strip.min(map_width) {
                    let x = view.left() + strip as f32 * 16.0 * self.zoom;
                    painter.line_segment([pos2(x, canvas.top()), pos2(x, canvas.bottom())], stroke);
                }
                for row in 0..=Map::HEIGHT {
                    let y = view.top() + row as f32 * 16.0 * self.zoom;
                    painter.line_segment([pos2(canvas.left(), y), pos2(canvas.right(), y)], stroke);
                }
            }

            if let Some((strip, row)) = hovered {
                let cell = Rect::from_min_size(
                    view.min + vec2(strip as f32 * 16.0, row as f32 * 16.0) * self.zoom,
                    vec2(16.0, 16.0) * self.zoom,
                );
                painter.rect_stroke(
                    cell,
                    0.0,
                    Stroke::new(2.0, Color32::YELLOW),
                    egui::StrokeKind::Inside,
                );
            }

            let pointer_position = pointer.unwrap_or(canvas.center());
            let scroll = ui.input(|input| input.smooth_scroll_delta.y);
            if response.hovered() && scroll != 0.0 {
                let world = (pointer_position - canvas.min - self.pan) / self.zoom;
                let zoom = (self.zoom * (scroll * 0.0015).exp()).clamp(MIN_ZOOM, MAX_ZOOM);
                self.pan = pointer_position - canvas.min - world * zoom;
                self.zoom = zoom;
            }

            let space = ui.input(|input| input.key_down(Key::Space));
            let panning = response.dragged_by(PointerButton::Middle)
                || (space && response.dragged_by(PointerButton::Primary));
            if panning {
                self.pan += response.drag_delta();
                self.painting = false;
                self.last_cell = None;
            }

            let primary = ui.input(|input| input.pointer.primary_down());
            let secondary = ui.input(|input| input.pointer.secondary_down());
            let alt = ui.input(|input| input.modifiers.alt);

            if primary && alt {
                if let Some((strip, row)) = hovered {
                    let block = self.project.maps[self.current].terrain[strip * Map::HEIGHT + row];
                    self.selected = block;
                    self.notice = format!("Picked ${block:02X}");
                }
            } else if (primary || secondary) && !space && !panning {
                if let Some((strip, row)) = hovered {
                    let block = if secondary { 0 } else { self.selected };
                    self.stroke_to((strip, row), block);
                }
            } else {
                self.painting = false;
                self.last_cell = None;
            }

            let hovered_text = hovered
                .map(|(strip, row)| {
                    let block = self.project.maps[self.current].terrain[strip * Map::HEIGHT + row];
                    format!("strip {strip}, row {row}  |  ${block:02X} ({block})")
                })
                .unwrap_or_else(|| "outside map".to_owned());
            painter.text(
                canvas.left_top() + vec2(8.0, 8.0),
                Align2::LEFT_TOP,
                format!(
                    "{map_title}  |  {hovered_text}  |  zoom {:.0}%",
                    self.zoom * 100.0
                ),
                FontId::proportional(13.0),
                Color32::from_gray(210),
            );
        });
    }

    fn status_bar(&mut self, ui: &mut egui::Ui) {
        egui::Panel::bottom("status").show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.label("Left: paint   Right: erase   Alt+Left: pick   Middle/Space: pan   Wheel: zoom   Ctrl+S: save   Ctrl+Z/Y: undo/redo");
                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    if !self.notice.is_empty() {
                        ui.label(&self.notice);
                    }
                });
            });
        });
    }

    fn shortcuts(&mut self, context: &egui::Context) {
        let save = context.input(|input| input.modifiers.command && input.key_pressed(Key::S));
        let undo = context.input(|input| {
            input.modifiers.command && input.key_pressed(Key::Z) && !input.modifiers.shift
        });
        let redo = context.input(|input| {
            input.modifiers.command
                && (input.key_pressed(Key::Y)
                    || (input.modifiers.shift && input.key_pressed(Key::Z)))
        });

        if save {
            if self.states[self.current].dirty {
                self.save();
            }
        } else if undo {
            self.undo();
        } else if redo {
            self.redo();
        }
    }

    fn close_confirmation(&mut self, context: &egui::Context) {
        if !self.close_dialog {
            return;
        }

        egui::Window::new("Unsaved changes")
            .collapsible(false)
            .resizable(false)
            .anchor(Align2::CENTER_CENTER, Vec2::ZERO)
            .show(context, |ui| {
                ui.label("Some maps have unsaved changes.");
                ui.horizontal(|ui| {
                    if ui.button("Save all and quit").clicked() && self.save_all() {
                        self.allow_close = true;
                        self.close_dialog = false;
                        context.send_viewport_cmd(egui::ViewportCommand::Close);
                    }
                    if ui.button("Discard and quit").clicked() {
                        self.allow_close = true;
                        self.close_dialog = false;
                        context.send_viewport_cmd(egui::ViewportCommand::Close);
                    }
                    if ui.button("Cancel").clicked() {
                        self.close_dialog = false;
                    }
                });
            });
    }
}

impl eframe::App for EditorApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        let context = ui.ctx().clone();
        context.send_viewport_cmd(egui::ViewportCommand::Title(self.title()));

        if context.input(|input| input.viewport().close_requested())
            && self.any_dirty()
            && !self.allow_close
        {
            context.send_viewport_cmd(egui::ViewportCommand::CancelClose);
            self.close_dialog = true;
        }

        self.shortcuts(&context);
        self.toolbar(ui);
        self.status_bar(ui);
        self.blocks_panel(ui);
        self.canvas(ui);
        self.close_confirmation(&context);
    }
}

fn cell_at(
    position: egui::Pos2,
    canvas: Rect,
    pan: Vec2,
    zoom: f32,
    width: usize,
) -> Option<(usize, usize)> {
    if !canvas.contains(position) {
        return None;
    }
    let local = position - canvas.min - pan;
    let strip = (local.x / (16.0 * zoom)).floor();
    let row = (local.y / (16.0 * zoom)).floor();
    if strip < 0.0 || row < 0.0 {
        return None;
    }
    let strip = strip as usize;
    let row = row as usize;
    (strip < width && row < Map::HEIGHT).then_some((strip, row))
}

fn line_cells(from: (usize, usize), to: (usize, usize)) -> Vec<(usize, usize)> {
    let (x0, y0) = (from.0 as isize, from.1 as isize);
    let (x1, y1) = (to.0 as isize, to.1 as isize);
    let dx = (x1 - x0).abs();
    let dy = -(y1 - y0).abs();
    let sx = if x0 < x1 { 1 } else { -1 };
    let sy = if y0 < y1 { 1 } else { -1 };
    let mut error = dx + dy;
    let (mut x, mut y) = (x0, y0);
    let mut cells = Vec::new();

    loop {
        cells.push((x as usize, y as usize));
        if x == x1 && y == y1 {
            break;
        }
        let doubled = error * 2;
        if doubled >= dy {
            error += dy;
            x += sx;
        }
        if doubled <= dx {
            error += dx;
            y += sy;
        }
    }

    cells
}

fn block_filter(search: &str) -> Box<dyn Fn(u8) -> bool> {
    let search = search.trim();
    if search.is_empty() {
        return Box::new(|_| true);
    }

    let cleaned = search.strip_prefix('$').unwrap_or(search);
    let parsed = if search.starts_with('$')
        || cleaned
            .chars()
            .any(|c| c.is_ascii_hexdigit() && c.is_ascii_alphabetic())
    {
        u8::from_str_radix(cleaned, 16).ok()
    } else {
        cleaned.parse::<u8>().ok()
    };

    Box::new(move |block| parsed.is_some_and(|value| value == block))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rasterizes_a_straight_line() {
        assert_eq!(line_cells((0, 0), (2, 0)), vec![(0, 0), (1, 0), (2, 0)]);
        assert_eq!(line_cells((0, 0), (1, 1)), vec![(0, 0), (1, 1)]);
    }

    #[test]
    fn filters_hex_and_decimal_block_ids() {
        assert!(block_filter("$9c")(0x9C));
        assert!(block_filter("9c")(0x9C));
        assert!(block_filter("156")(156));
        assert!(!block_filter("156")(0x99));
    }
}
