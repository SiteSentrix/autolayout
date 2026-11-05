#!/usr/bin/env bash
# Stop: run the quick gate; if it fails, block stopping once so the agent fixes it.
. "$(dirname "$0")/lib.sh"
[ "$(jget .stop_hook_active)" = "true" ] && exit 0   # already retried once: give up
cd "$ROOT" 2>/dev/null || exit 0
[ -f ci.sh ] || exit 0
# Only gate when Rust or the gate itself changed (docs-only sessions stop freely).
git status --porcelain 2>/dev/null | grep -Eq '\.(rs|toml)$|ci\.sh' || exit 0
out="$(timeout 300 bash ci.sh --quick 2>&1)" && exit 0
printf 'Quick gate (./ci.sh --quick) failed; fix before stopping:\n%s\n' "$(printf '%s' "$out" | tail -30)" >&2
exit 2
