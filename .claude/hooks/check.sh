#!/usr/bin/env bash
# PostToolUse(Edit|Write), async: fast lint on Rust edits; errors go back to the agent.
. "$(dirname "$0")/lib.sh"
f="$(jget .tool_input.file_path)"
case "$f" in *.rs) ;; *) exit 0 ;; esac
cd "$ROOT" 2>/dev/null || exit 0
out="$(PATH="$HOME/.cargo/bin:$PATH" timeout 120 cargo clippy --workspace --all-targets --quiet -- -D warnings 2>&1)" && exit 0
printf 'clippy after editing %s:\n%s\n' "$f" "$(printf '%s' "$out" | head -40)" >&2
exit 2
