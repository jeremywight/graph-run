#!/usr/bin/env bash
# Deterministic gate for /graph-run.
# Wired to the Stop hook: while graph/.active exists, Claude cannot finish
# until every command in .claude/gate-commands exits 0.
# After MAX_ATTEMPTS blocked stops it lets Claude stop, so failures get
# reported instead of looping forever.
set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RUN_DIR="$ROOT/graph"
MARKER="$RUN_DIR/.active"
CONF="$ROOT/.claude/gate-commands"
COUNTER="$RUN_DIR/.gate_attempts"
LOG="$RUN_DIR/gate-log.md"
MAX_ATTEMPTS="${GATE_MAX_ATTEMPTS:-3}"

cat >/dev/null 2>&1 || true   # consume hook JSON from stdin

# Not in a graph run: do nothing.
[ -f "$MARKER" ] || exit 0

ts() { date '+%Y-%m-%d %H:%M:%S'; }

if [ ! -f "$CONF" ]; then
  echo "Gate: .claude/gate-commands is missing. Write the acceptance checks there (one command per line) or delete graph/.active if the run is over." >&2
  exit 2
fi

cd "$ROOT" || exit 0
failed=""
report=""
while IFS= read -r cmd || [ -n "$cmd" ]; do
  case "$cmd" in ''|'#'*) continue ;; esac
  out="$(bash -c "$cmd" </dev/null 2>&1)"   # a check must not read the rest of gate-commands
  code=$?
  if [ $code -ne 0 ]; then
    failed="$failed\n- $cmd (exit $code)"
    report="$report\n### \`$cmd\` exit $code\n$(printf '%s' "$out" | tail -n 40)\n"
  fi
done < "$CONF"

if [ -z "$failed" ]; then
  rm -f "$COUNTER"
  printf -- "- %s gate PASS\n" "$(ts)" >> "$LOG"
  exit 0
fi

n="$(cat "$COUNTER" 2>/dev/null || true)"
case "$n" in ''|*[!0-9]*) n=0 ;; esac   # digits only: never evaluate the file as code
n=$(( 10#$n + 1 ))
echo "$n" > "$COUNTER"
printf -- "- %s gate FAIL (attempt %s/%s):%b\n" "$(ts)" "$n" "$MAX_ATTEMPTS" "$failed" >> "$LOG"

if [ "$n" -gt "$MAX_ATTEMPTS" ]; then
  # Let Claude stop; the failure stays recorded in gate-log.md.
  rm -f "$COUNTER"
  exit 0
fi

{
  printf "Gate failed (attempt %s of %s). Do not finish yet.\n" "$n" "$MAX_ATTEMPTS"
  printf "Failing checks:%b\n" "$failed"
  printf "%b\n" "$report"
  printf "Send the failure back to the node that produced it (fix that node only). Do not weaken any check. If it cannot be fixed, record it as fail in graph/checks.md and graph/progress.md, then delete graph/.active.\n"
} >&2
exit 2
