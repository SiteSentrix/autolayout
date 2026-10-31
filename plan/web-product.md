# Web product (M9): upload a KiCad board, get it placed and routed

Status: **plan only, nothing built.** "Quilter-style" here means the workflow
(upload → automatic layout → review → download), not their code, UI, artwork,
wording or name (AGENTS.md rule 6; black-box use of public pages only). Pick our
own product name before any public page exists.

## What it is
A Rust web service in this repo. A user uploads a `.kicad_pcb` (+ its `.kicad_pro`, which
the router needs for rules; it refuses without them), picks options, and gets back a new
`.kicad_pcb` plus a report. The engine is the existing place/route/grade crates; the web
layer adds no layout logic.

## What it cannot honestly claim yet
- Layout quality is research-stage (ROADMAP "Honest assessment"): 141 open connections over
  the 37-board corpus, fine-pitch MCU escape unsolved.
- Server-side numbers come from our own verifier, **not KiCad**. Every report labels them so.
  KiCad DRC grading stays an external step (Windows) until someone decides to host it.
- Big boards route for minutes (up to ~430 s measured), so jobs are asynchronous.

## Design (defaults; changeable until M9.2 starts)
- `crates/engine` (new lib): the place/route/grade orchestration now inside `crates/cli/src/main.rs`
  (1 093 lines, no library API). `cli` becomes a thin wrapper. `crates/web` sits beside `cli`;
  dependency rule unchanged (lower crates never depend on higher).
- `crates/web`: axum + tokio, MIT/Apache deps only. Jobs run as **subprocesses** of the CLI with a
  wall-clock limit and memory cap, so a bad board or a panic cannot take the server down.
- Storage: one directory per job on disk (input read-only, outputs new paths). No database until
  a feature needs one.
- API first, UI second: `POST /api/jobs` (multipart), `GET /api/jobs/{id}`, `GET /api/jobs/{id}/board`,
  `GET /api/jobs/{id}/report`. Every user-visible action is an endpoint a test can call.
- UI: server-rendered HTML plus a small own-code SVG board viewer (before/after, unconnected
  highlighted). A headless Playwright screenshot command is added with it and documented in AGENTS.md.
- Determinism: same upload + options + seed → same output bytes; seed shown in the report.
- Untrusted input: size and count caps on upload (files, bytes, parse depth already capped in `sexpr`),
  per-IP job limits, no path from user data to a filesystem path, upload fuzz test.

## Tasks (one issue = one PR each)
| id | task | done when |
|----|------|-----------|
| M9.1 | Extract `crates/engine`; `cli` calls it | CLI output bytes identical on the fixture and corpus boards; `./ci.sh` green |
| M9.2 | `crates/web` API + job runner (subprocess, limits) | curl a board in, get a routed board out; limits tested; upload fuzz test |
| M9.3 | Report: unconnected, verifier violations, wirelength, seed, "not KiCad-graded" | numbers equal `autolayout grade`/`verify` on the written file |
| M9.4 | Browser UI + board viewer + headless screenshot command | screenshot taken by script in CI-able form |
| M9.5 | Optional external KiCad grading hook (Windows worker posts DRC result) | report shows KiCad numbers when present |

## Needs the owner's decision (stop-and-ask list)
Accounts/auth, payments, hosting provider and cost, public name and copy, data retention for
uploaded boards (customer designs are confidential), whether the service is public or private.
Until decided: no auth, no payments, local-only, nothing deployed.
