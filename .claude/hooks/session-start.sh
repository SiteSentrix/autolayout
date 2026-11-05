#!/usr/bin/env bash
# SessionStart(compact): re-print the rules a long session forgets.
cat <<'TXT'
autolayout — after compaction, remember (full text: AGENTS.md):
1. Session start order: ROADMAP.md "Honest assessment" -> plan/STATUS.md -> the task -> only the docs it needs.
2. No task given: oldest open `claude-queue` issue, else top of the ROADMAP gap list.
3. Loop: orient, plan (one task = one branch claude/issue-N or claude/M1.3-name), implement+test, verify, PR, record. Protocol: plan/execution-plan.md.
4. Gate: `./ci.sh` before every commit (`./ci.sh --quick` between edits). Never skip or delete a failing test.
5. Commit messages start with the task ID ("M1.3: ..."). Commits are authored by the user only: no Co-Authored-By, no AI attribution.
6. Board files are read-only inputs; outputs go to out/. Never panic on input (no unwrap/expect outside tests).
7. Ask the part, not the name: no net-name / refdes / pin-number literals in code.
8. Every number in docs/commits names the board, command, measured vs estimated. Report the unconnected count.
9. Clean room: never read or copy KiCad / Freerouting source or any competitor's code, assets or wording.
10. STOP and ask (unattended: comment on the issue, take the next task) for: irreversible actions, deleting data, paid services, non-permissive dependencies, auth/security changes, public-facing copy, anything conflicting with these rules.
TXT
exit 0
