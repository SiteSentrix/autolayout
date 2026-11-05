# Shared by the hooks. Every hook fails safe: on any internal error, allow.
# jget <jq-path>  reads the hook's JSON from $INPUT (jq, else python3, else empty).
INPUT="$(cat 2>/dev/null || true)"
jget() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    for k in sys.argv[1].strip(".").split("."):
        d=d.get(k) if isinstance(d,dict) else None
    print("" if d is None else d)
except Exception:
    pass' "$1" 2>/dev/null || true
  fi
}
deny() { echo "BLOCKED by .claude/hooks: $1" >&2; exit 2; }
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
