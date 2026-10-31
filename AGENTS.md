# autolayout — instructions for agents

autolayout is an open-source placement and routing engine for KiCad boards, in
Rust (MIT OR Apache-2.0). It reads a `.kicad_pcb`, places and routes it, and
writes a `.kicad_pcb` that KiCad opens unchanged except for what we meant to
change. Headless CLI; KiCad is needed only to grade (`kicad-cli`). Placement
comes first: Freerouting routes parts where you left them, so placement is where
we can beat free tools. Overview and results: [README.md](README.md).

**Product family:** autolayout (this repo, public engine) · Portcullis (private,
AGPL access-control controller; supplies the board corpus and the domain docs;
never copy its code).

## SESSION START (fixed order)
1. [`ROADMAP.md`](ROADMAP.md) section "Honest assessment" (top ~40 lines only; the file is long).
2. [`plan/STATUS.md`](plan/STATUS.md).
3. The task: a GitHub issue, or [`plan/execution-plan.md`](plan/execution-plan.md). With no task given, take the oldest open `claude-queue` issue; if none, the top item of the ROADMAP gap list (detail in [`docs/gaps.md`](docs/gaps.md)).
4. Only the docs that task needs. `docs/windows-handoff.md` (1100 lines) and `docs/m7-results/` are archives: grep them, never read them whole.

## THE LOOP
Orient → plan → implement + test → verify → PR → record. Exact steps and the
stop-and-ask list: [`plan/execution-plan.md`](plan/execution-plan.md) § "Autonomous protocol".

## QUALITY GATE
`./ci.sh` (asset check, fmt, clippy `-D warnings`, tests; 16 s from a fresh clone, 32 s on first run; measured
2026-10-31 in the cloud). Run it before every commit. `./ci.sh --quick` (assets, fmt, clippy, seconds)
between edits. CI calls the same `./ci.sh`.
Gate on its exit status, never on a pipe (`ci.sh | tail && git commit` committed a red tree once,
594157d): `bash ci.sh > out/ci_last.txt 2>&1; echo "exit=$?"`.
Without `AUTOLAYOUT_CORPUS`/KiCad, corpus and cross-check steps print `SKIPPED`. A skip is never a pass.
`./ci.sh --kicad-full` (~20 min, Windows only) after touching courtyard geometry.

## RULES (non-negotiable)
1. **Never damage a board.** Inputs are read-only; output to a new path (refuse to overwrite input). parse → write with no edits is byte-exact (tested on every corpus board). Unknown nodes pass through untouched.
2. **Ask the part, not the name.** Never decide from a net name, refdes or pin number; use pintype, net class, footprint attributes, connectivity, geometry. If a name is the only signal it is a config override, never a literal in code.
3. **We do not grade our own work.** Improvement claims come from `kicad-cli pcb drc` or `autolayout grade` read back from the written file. Always report the **unconnected count**; "the router stopped" is not "routed".
4. **Deterministic.** Same input + options + seed → same bytes. Randomness takes an explicit seed, printed in the report.
5. **Never crash on input.** Board files are untrusted. Return `Result`; no `unwrap/expect/panic!/todo!/unimplemented!/unreachable!` outside tests (lints enforce). Use `.get(i)` for data-derived indices, cap sizes/depths read from input, check floats are finite. Parsers keep their fuzz tests (`fuzz:` line in the gate).
6. **Clean room.** Never read or copy KiCad or Freerouting source (GPL-3), any GPL/AGPL code, or any competitor's (Quilter's etc.) code, artwork, wording or data. Behaviour comes from public docs (dev-docs.kicad.org, papers, textbooks), cited by URL in the module docstring. KiCad/Freerouting may be *run* as external programs.
7. **Every number has a source.** Docs and commits name the board, the command, and measured vs estimated. Half an answer is recorded as half.
8. **Assets.** Every non-code asset has a row in `ASSETS.md` (source, licence); `tools/check_assets.sh` fails the gate otherwise. Corpus boards, generated boards, secrets, `.env` and files over 1 MB are never committed.
9. **Everything user-visible is a CLI command** (`autolayout --help`). There is no UI, so no screenshot step; agents drive and test the CLI directly.
10. **Commits are authored by the user only** (`Bruce Wattendorf <bwattendorf@gmail.com>`): no `Co-Authored-By`, no AI attribution lines in commits or PRs. Commit messages start with the task ID (`M7.5: ...`). One task per commit.
11. **Parallel agents:** one issue, one branch/worktree each, touch only the crates the issue needs, own `CARGO_TARGET_DIR`, delete it when done.

## PROJECT MAP
```
crates/sexpr  lossless s-expression parser/writer     crates/place  placement
crates/board  typed board model                       crates/route  router, verifier
crates/grade  metrics re-derived from a written file  crates/engine commands as a library; crates/cli = thin binary
tools/        Python + shell helpers run by KiCad's python (pcbnew), Windows-side
plan/         STATUS.md and execution-plan.md          docs/gaps.md  ranked work list
docs/m7-results/  archived measurement records         .claude/      hooks (see settings.json)
```
Dependencies point down only: `sexpr` ← `board` ← `place`/`route`/`grade` ← `engine` ← `cli`.

## CORPUS (outside the repo, read-only)
`AUTOLAYOUT_CORPUS` → `C:/Portcullis/controller/boards/` (20 boards, 2/4-layer, 50–200 parts).
Per board: `quilter/freeplace/<sku>/<sku>.kicad_pcb` is our input (fixed parts on the outline,
rest on a staging grid); `quilter/returned/<sku>/<candidate>/` is the commercial service's
placed-and-routed result (**the bar**); `quilter/fab/{m1,emu}/` went to fab. The r and m2
boards are stale vs their netlists (missing R28/R29, R94–R97): don't grade against them.
Domain docs live in Portcullis (`CLAUDE.md`, `controller/docs/m1-layout-experiment-2026-10-10.md`).

## ENVIRONMENTS
- **Windows (owner's machine):** Rust GNU toolchain (`stable-x86_64-pc-windows-gnu`), cargo in `~/.cargo/bin` (may need adding to `PATH`); KiCad 9.0 at `C:/Program Files/KiCad/9.0/` (`kicad-cli.exe`, its python for `tools/*.py`).
- **Cloud (Ubuntu):** setup = rustup minimal + clippy,rustfmt, and `git clone --depth 1 https://github.com/bwattendorf/Portcullis.git ../Portcullis` with `AUTOLAYOUT_CORPUS` pointing at its `controller/boards`. Needs GitHub access to both private repos. No KiCad or Freerouting: router/placer results made there are "pending KiCad" until graded on Windows. Freerouting comparisons need Java 21+ and the freerouting-2.3.0 jar.

## PITFALLS
- Doc line lengths: `ROADMAP.md` and `docs/gaps.md` hold multi-thousand-character lines (M7.5 entries). Never `cat` them; `grep -n` or read by line range.
- Rotated-pad convention was measured, not assumed (rotation adds its delta to every pad/text angle, board terms). Don't "fix" it without the m1 KiCad cross-check.
- Round counts on the 37 routing boards come from `tools/m7_batch.py` on Windows (≈50 min); the local verifier's numbers are *not* KiCad's until a round confirms them.
- Planes in `tools/m7_batch.py` are poured and filled before routing; `route` therefore ignores existing fills on declared plane layers (`verify_fresh_planes`) while `verify` reads them.
- Route portfolio on big boards is slow (c4/3p5mil-candidate3 ≈ 270–430 s); don't loop it in tests.
- `__pycache__`/`.pyc` were once committed; now ignored and checked by `check_assets.sh`.
- Hooks in `.claude/` block board-file edits, `Cargo.lock` edits (set `ALLOW_LOCK_EDIT=1` for a dependency task), licence edits and non-temp `rm -rf`; a block is not a bug, change the approach.
