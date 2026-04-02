mod bank;
mod expression;
mod project;
mod source;
mod transpiler;

use std::path::PathBuf;

use anyhow::{bail, Result};
use clap::Parser;

use crate::transpiler::Transpiler;

#[derive(Parser)]
struct Arguments {
    #[arg(default_value = "../pds_src/src")]
    source: PathBuf,
    #[arg(default_value = "out")]
    output: PathBuf,
}

fn main() -> Result<()> {
    let arguments = Arguments::parse();

    if !arguments.source.is_dir() {
        bail!("source directory not found: {}", arguments.source.display());
    }

    let transpiled = Transpiler::new(&arguments.source).run();
    project::write(&arguments.output, &transpiled)?;

    for warning in transpiled.warnings() {
        eprintln!("warning: {warning}");
    }

    println!(
        "wrote {} bank file(s) to {}",
        transpiled.bank_count(),
        arguments.output.display()
    );

    Ok(())
}
