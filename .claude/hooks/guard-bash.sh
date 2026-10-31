#!/usr/bin/env bash
# PreToolUse(Bash): block destructive commands. Exit 2 = block; anything else = allow.
. "$(dirname "$0")/lib.sh"
cmd="$(jget .tool_input.command)"
[ -z "$cmd" ] && exit 0
cmd="${cmd%%<<*}"                                   # ignore heredoc bodies
scan="$(printf '%s' "$cmd" | sed -E 's/git[[:space:]]+rm[[:space:]]/git-rm /g')"   # git rm is not rm
# recursive rm unless every target is a build/temp dir
while IFS= read -r seg; do
  [ -z "$seg" ] && continue
  for t in $(printf '%s' "$seg" | sed -E 's/^[^r]*rm[[:space:]]+//; s/(^|[[:space:]])-[a-zA-Z-]+//g'); do
    case "$t" in
      target|target/*|./target|./target/*|out|out/*|./out|./out/*|/tmp/*) ;;
      *) deny "recursive rm outside build/temp dirs (target/, out/, /tmp): '$t'" ;;
    esac
  done
done < <(printf '%s' "$scan" | grep -oE '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)[^;&|]*')
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^;&|]*(--force|[[:space:]]-f([[:space:]]|$))' && deny "git push --force"
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard'; then
  br="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  case "$br" in main|master) deny "git reset --hard on $br" ;; esac
fi
printf '%s' "$cmd" | grep -Eiq '(drop|truncate)[[:space:]]+(table|database|schema)' && deny "DROP/TRUNCATE (no database in this repo; ask the user)"
# Disabling CI through the shell (use Edit; the guard-edit hook checks the content)
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])(rm|mv|truncate|sed -i)[^;&|]*(\.github/workflows|ci\.sh)' && deny "shell edit of CI (.github/workflows, ci.sh); use Edit and keep the gate intact"
printf '%s' "$cmd" | grep -Eq -- '--no-verify' && deny "--no-verify"
exit 0
