#!/usr/bin/env bash
# PreToolUse(Edit|Write): block secrets, lock files, licences, and edits that disable CI.
. "$(dirname "$0")/lib.sh"
f="$(jget .tool_input.file_path)"
[ -z "$f" ] && exit 0
b="$(basename "$f")"
case "$b" in
  .env|.env.*|*.pem|*.key|id_rsa*|secrets.*|credentials*) deny "secret file '$b'" ;;
  LICENSE*|COPYING*) deny "licence file '$b' (licences change only on the user's say-so)" ;;
  Cargo.lock) [ -n "${ALLOW_LOCK_EDIT:-}" ] || deny "Cargo.lock is changed by cargo (dependency update tasks: set ALLOW_LOCK_EDIT=1)" ;;
esac
case "$f" in
  *.kicad_pcb|*.kicad_pro) deny "board file: inputs are read-only, write outputs to out/" ;;
  */.github/workflows/*)
    new="$(jget .tool_input.new_string)$(jget .tool_input.content)"
    printf '%s' "$new" | grep -Eq 'ci\.sh' || deny "workflow edit that does not call ./ci.sh (CI must run the same gate)" ;;
esac
exit 0
