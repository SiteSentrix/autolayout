#!/usr/bin/env bash
# PostToolUse(Edit|Write): format the edited file. Never blocks.
. "$(dirname "$0")/lib.sh"
f="$(jget .tool_input.file_path)"
case "$f" in
  *.rs) PATH="$HOME/.cargo/bin:$PATH" rustfmt --edition 2021 "$f" >/dev/null 2>&1 ;;
esac
exit 0
