mod app;
mod data;
mod render;

use anyhow::Result;

fn main() -> Result<()> {
    let root = data::find_root()?;
    let project = data::Project::load(&root)?;
    let options = eframe::NativeOptions {
        viewport: eframe::egui::ViewportBuilder::default()
            .with_inner_size([1400.0, 900.0])
            .with_min_inner_size([900.0, 600.0]),
        ..Default::default()
    };
    eframe::run_native(
        "Super Robin Hood Map Editor",
        options,
        Box::new(move |context| Ok(Box::new(app::EditorApp::new(context, project)))),
    )
    .map_err(|error| anyhow::anyhow!(error.to_string()))?;
    Ok(())
}
