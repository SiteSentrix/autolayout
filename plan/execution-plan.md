# Execution plan

Work items live in GitHub issues (label `claude-queue`) and in the ROADMAP gap
list (task IDs like M7.5). One issue = one branch = one PR.

## Autonomous protocol

1. **Orient:** read the session-start files (AGENTS.md → SESSION START).
2. **Plan:** pick ONE task (one issue = one branch = one PR). Branch name `claude/issue-N` or `claude/M1.3-short-name`.
3. **Implement + test:** write or update tests alongside the code.
4. **Verify:** run the quality gate (`./ci.sh`). If it fails, fix it; never skip or delete a failing test to get green.
5. **Open a PR** referencing the issue, with a short summary and how it was tested. Commit messages start with the task ID ("M1.3: ...").
6. **Merge** only when the gate is green and the CI checks pass (respect branch protection; never force-push, never bypass checks).
7. **Pull main** and run the quality gate on main again. If main is red, the next task is fixing main, before anything else.
8. **Record:** update ROADMAP.md (milestone row, shipped list, gap list) and plan/STATUS.md in the same PR.
9. **Move to the next task.**

STOP and ask the user (when unattended: leave a comment on the issue and move to the next task) only for: anything irreversible, deleting data, new paid services or new dependencies with non-permissive licenses, changes to auth/payments/security, branding or public-facing copy, and anything that conflicts with the rules in AGENTS.md.

## Repo-specific notes

- "Verify" for router/placer work also means a KiCad-graded number on a real board (AGENTS.md rule 3). The cloud has no KiCad: say so in the PR and mark the number "pending KiCad".
- Parallel agents: one issue per branch/worktree, touch only the crates the issue needs, set `CARGO_TARGET_DIR` to a per-agent dir, delete it when done.
