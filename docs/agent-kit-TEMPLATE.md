# Agent kit template

Copy into a new repo, fill the `<PLACEHOLDERS>`, delete what doesn't apply. Principle: **lean**.
Every line must be something an agent cannot discover alone. Target AGENTS.md < 150 lines;
a session start reads < 400 lines. Reference implementation: this repo.

## Files
| file | purpose |
|---|---|
| `AGENTS.md` | single source of truth. `CLAUDE.md` is one line: `@AGENTS.md` |
| `ROADMAP.md` | "Honest assessment" (top, ~40 lines), gap list, milestones with IDs, shipped list |
| `plan/STATUS.md` | where we are now; < 40 lines; updated every session |
| `plan/execution-plan.md` | "Autonomous protocol" (below) |
| `<GATE>` | ONE command: format, lint (warnings as errors), type-check, tests, build; plus `--quick` if > ~3 min |
| `.github/workflows/ci.yml` | calls `<GATE>` and nothing else |
| `ASSETS.md` + `<CHECK_ASSETS>` | row per non-code asset (source, licence); script fails the gate if missing |
| `.claude/settings.json`, `.claude/hooks/*.sh` | guards and gates (below) |
| nested `AGENTS.md` | only where a subfolder has its own conventions |

## AGENTS.md skeleton (in this order)
1. Overview paragraph + product family (`<WHAT, LANGUAGE, LICENCE, SIBLING REPOS>`).
2. SESSION START: ROADMAP "Honest assessment" → `plan/STATUS.md` → the task (issue or plan) → only the docs it needs. No task: oldest open `claude-queue` issue, else top ROADMAP gap.
3. THE LOOP → `plan/execution-plan.md` § Autonomous protocol.
4. QUALITY GATE: `<GATE>`, "run before every commit", runtime `<N> s`, never gate on a pipe.
5. RULES, one line each: clean room (no copying competitors' code/assets/wording, no GPL into permissive repos) · assets in ASSETS.md · never crash on untrusted input (validate, cap, fuzz importers/parsers) · every user-visible thing is a command/endpoint, plus a headless screenshot command if there is a UI (`<SCREENSHOT_CMD>`) · no secrets/.env/large binaries · commits authored by `<OWNER>` only, no Co-Authored-By/AI lines · parallel agents: own branch/worktree, own build dir, minimal folders.
6. PROJECT MAP: one line per non-obvious folder.
7. PITFALLS: from git history, issues, TODO/FIXME, failing tests. Domain rules the code cannot show.

## Autonomous protocol (copy verbatim into plan/execution-plan.md)
1. Orient: read the session-start files.
2. Plan: ONE task (one issue = one branch = one PR). Branch `claude/issue-N` or `claude/M1.3-short-name`.
3. Implement + test: tests alongside the code.
4. Verify: run the gate. Fix failures; never skip or delete a failing test.
5. Open a PR referencing the issue: short summary + how tested. Commits start with the task ID ("M1.3: ...").
6. Merge only when the gate and CI checks are green (respect branch protection; no force-push, no bypass).
7. Pull main, run the gate on main. If red, fixing main is the next task.
8. Record: ROADMAP.md (milestone row, shipped, gaps) and `plan/STATUS.md` in the same PR.
9. Next task.

STOP and ask (unattended: comment on the issue, take the next task) for: irreversible actions, deleting data, new paid services or non-permissive dependencies, auth/payments/security, branding or public copy, anything conflicting with the rules.

## Hooks (all fail safe: internal error ⇒ allow; `lib.sh` reads JSON with jq, else python3)
| event / matcher | script | does |
|---|---|---|
| PreToolUse Bash | `guard-bash.sh` | blocks recursive `rm` outside build/temp dirs, `git push --force`, `git reset --hard` on main, DROP/TRUNCATE, shell edits of CI/gate, `--no-verify`. Exit 2 = block. Ignores heredoc bodies and `git rm`. |
| PreToolUse Edit\|Write | `guard-edit.sh` | blocks `.env*`, keys, `LICENSE*`, lock files (unless `ALLOW_LOCK_EDIT=1`), `<PROTECTED_INPUTS>`, workflow edits that stop calling `<GATE>` |
| PostToolUse Edit\|Write | `format.sh` | formats the edited file with `<FORMATTER>`; always exit 0 |
| PostToolUse Edit\|Write, async | `check.sh` | fast lint/type-check, errors fed back (exit 2) |
| Stop | `stop-gate.sh` | runs `<GATE> --quick` if source changed; exit 2 blocks stopping; **if `stop_hook_active` is true, exit 0** (one retry, no loop) |
| SessionStart `compact` | `session-start.sh` | prints the 10 rules a long session forgets |

`settings.json` also keeps `"includeCoAuthoredBy": false` and empty `attribution`.
Hook commands use `$CLAUDE_PROJECT_DIR`. Test each hook by piping JSON into it
(`echo '{"tool_input":{"command":"rm -rf /"}}' | bash .claude/hooks/guard-bash.sh; echo $?`).

## Per-ecosystem gate
Rust `./ci.sh` (fmt, clippy -D warnings, test) · Node `npm run ci` · Python `make ci` (ruff, mypy, pytest) · Go `make ci` (gofmt, vet, test). Same command locally and in CI.

## Setup checklist
- [ ] fill AGENTS.md; CLAUDE.md = `@AGENTS.md`
- [ ] ROADMAP honest assessment seeded from the code's *behaviour*, not its size
- [ ] gate + `--quick`, CI workflow calls it, time it
- [ ] ASSETS.md + check wired into the gate
- [ ] hooks tested once each; undo the test edits
- [ ] label `claude-queue` created; dry-run the session start and count lines
- [ ] one PR, not merged
