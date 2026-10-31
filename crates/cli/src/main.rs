//! `autolayout` command line: a thin wrapper over [`autolayout_engine::run`].
//! Commands and flags are documented in the engine crate's module docs.

use std::io::Write as _;
use std::process::ExitCode;

fn main() -> ExitCode {
  let args: Vec<String> = std::env::args().skip(1).collect();
  match autolayout_engine::run(&args) {
    Ok(true) => ExitCode::SUCCESS,
    Ok(false) => ExitCode::FAILURE,
    Err(msg) => {
      let _ = writeln!(std::io::stderr(), "{msg}");
      ExitCode::from(2)
    }
  }
}
