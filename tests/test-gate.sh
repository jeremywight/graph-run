#!/usr/bin/env bash
# Tests for .claude/hooks/gate.sh and install.sh. Run: bash tests/test-gate.sh
set -u
KIT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$KIT/.claude/hooks/gate.sh"
pass=0; fail=0
check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1 (expected $2, got $3)"; fi
}

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/graph" "$T/.claude"
run_gate() { echo '{}' | CLAUDE_PROJECT_DIR="$T" bash "$GATE" >/dev/null 2>"$T/stderr"; echo $?; }

# 1. No marker: the gate does nothing.
check "no graph/.active -> exit 0" 0 "$(run_gate)"

# 2. Marker but no gate-commands: block with a clear message.
touch "$T/graph/.active"
check "missing gate-commands -> exit 2" 2 "$(run_gate)"

# 3. All checks pass: allow, log PASS.
printf '# comment\n\ntrue\n' > "$T/.claude/gate-commands"
check "passing checks -> exit 0" 0 "$(run_gate)"
check "PASS logged" 1 "$(grep -c 'gate PASS' "$T/graph/gate-log.md")"

# 4. Failing check blocks for attempts 1-3 and reports the command.
printf 'true\nfalse\n' > "$T/.claude/gate-commands"
for i in 1 2 3; do check "failing check attempt $i -> exit 2" 2 "$(run_gate)"; done
check "stderr names the failing command" 1 "$(grep -c -- '- false (exit 1)' "$T/stderr")"

# 5. Attempt 4: allow the stop so the failure gets reported; counter resets.
check "attempt 4 -> exit 0 (stop allowed)" 0 "$(run_gate)"
check "counter reset after cap" no "$( [ -f "$T/graph/.gate_attempts" ] && echo yes || echo no )"
check "failures logged" 4 "$(grep -c 'gate FAIL' "$T/graph/gate-log.md")"

# 6. A pass after failures resets the counter.
check "fail again -> exit 2" 2 "$(run_gate)"
printf 'true\n' > "$T/.claude/gate-commands"
check "then pass -> exit 0" 0 "$(run_gate)"
check "counter cleared on pass" no "$( [ -f "$T/graph/.gate_attempts" ] && echo yes || echo no )"

# 6b. A check that reads stdin must not swallow the checks after it.
printf 'cat >/dev/null\nfalse\n' > "$T/.claude/gate-commands"
check "stdin-reading check does not skip later checks -> exit 2" 2 "$(run_gate)"

# 6c. A tampered counter is never evaluated as code, and still counts from 1.
# shellcheck disable=SC2016  # the $(...) is meant to stay literal
printf 'a[$(touch %s/PWNED)]\n' "$T" > "$T/graph/.gate_attempts"
check "tampered counter -> still blocks" 2 "$(run_gate)"
check "tampered counter is not executed" no "$( [ -e "$T/PWNED" ] && echo yes || echo no )"
check "tampered counter restarts at 1" 1 "$(cat "$T/graph/.gate_attempts")"
printf 'true\n' > "$T/.claude/gate-commands"; run_gate >/dev/null

# 6d. Settings: the gate's own inputs need the owner's approval or are off limits.
if command -v python3 >/dev/null; then
  perms() { python3 -c "import json,sys; p=json.load(open(sys.argv[1]))['permissions']; print('yes' if sys.argv[3] in p[sys.argv[2]] else 'no')" "$KIT/.claude/settings.json" "$1" "$2"; }
  check "settings: gate-commands edits ask" yes "$(perms ask 'Edit(.claude/gate-commands)')"
  check "settings: gate-commands edits not auto-allowed" no "$(perms allow 'Edit(.claude/gate-commands)')"
  check "settings: counter edits denied" yes "$(perms deny 'Edit(graph/.gate_attempts)')"
  check "settings: no unscoped Read allow" no "$(perms allow 'Read')"
fi

# 7. settings.json is valid JSON.
if command -v python3 >/dev/null; then
  python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$KIT/.claude/settings.json" && r=valid || r=invalid
  check "settings.json is valid JSON" valid "$r"
fi

# 8. install.sh adds files, never overwrites, and is idempotent.
R="$T/repo"; mkdir -p "$R/.claude"; echo '{"mine":true}' > "$R/.claude/settings.json"
printf 'node_modules' > "$R/.gitignore"   # no trailing newline
bash "$KIT/install.sh" "$R" >/dev/null
check "install: last .gitignore line without newline kept intact" 1 "$(grep -cxF 'node_modules' "$R/.gitignore")"
check "install: command added" yes "$( [ -f "$R/.claude/commands/graph-run.md" ] && echo yes || echo no )"
check "install: gate executable" yes "$( [ -x "$R/.claude/hooks/gate.sh" ] && echo yes || echo no )"
check "install: existing settings untouched" '{"mine":true}' "$(cat "$R/.claude/settings.json")"
check "install: settings offered for merge" yes "$( [ -f "$R/.claude/settings.graph-run.json" ] && echo yes || echo no )"
bash "$KIT/install.sh" "$R" >/dev/null
check "install: .gitignore lines not duplicated" 1 "$(grep -cxF 'graph/.active' "$R/.gitignore")"

# 9. install.sh --update replaces the kit's own files, backs up what differed, and leaves the rest.
U="$T/upd"; mkdir -p "$U/.claude"
bash "$KIT/install.sh" "$U" >/dev/null
echo "local change" >> "$U/.claude/agents/graph-verifier.md"
echo "my-check" >> "$U/.claude/gate-commands"
echo '{"mine":2}' > "$U/.claude/settings.json"
out="$(bash "$KIT/install.sh" "$U")"
check "plain install leaves a changed kit file alone" 1 "$(grep -c 'local change' "$U/.claude/agents/graph-verifier.md")"
check "plain install reports it as skipped" 1 "$(printf '%s\n' "$out" | grep -c 'graph-verifier.md')"
bash "$KIT/install.sh" --update "$U" >/dev/null
check "update replaces the kit file" yes "$(cmp -s "$KIT/.claude/agents/graph-verifier.md" "$U/.claude/agents/graph-verifier.md" && echo yes || echo no)"
check "update backs up the old version" 1 "$(cat "$U"/.claude/graph-run-backup/*/.claude/agents/graph-verifier.md | grep -c 'local change')"
check "update leaves gate-commands alone" 1 "$(grep -c 'my-check' "$U/.claude/gate-commands")"
check "update leaves settings.json alone" '{"mine":2}' "$(cat "$U/.claude/settings.json")"
before="$(ls "$U/.claude/graph-run-backup" | wc -l | tr -d ' ')"
bash "$KIT/install.sh" --update "$U" >/dev/null
check "update with nothing to change makes no backup" "$before" "$(ls "$U/.claude/graph-run-backup" | wc -l | tr -d ' ')"

# 10. --graph-dir moves every run-file path, and the gate uses the new folder.
G="$T/dotgraph"; mkdir -p "$G"
bash "$KIT/install.sh" --graph-dir .graph "$G" >/dev/null
check "graph-dir: gate uses the new folder" 1 "$(grep -c 'RUN_DIR="$ROOT/.graph"' "$G/.claude/hooks/gate.sh")"
check "graph-dir: no old run path left in the command" 0 "$(grep -cE '(^|[^[:alnum:]_.])graph/' "$G/.claude/commands/graph-run.md")"
check "graph-dir: run paths point at .graph" yes "$(grep -q '\.graph/graph\.md' "$G/.claude/commands/graph-run.md" && echo yes || echo no)"
check "graph-dir: ignore lines use the new folder" 1 "$(grep -cxF '.graph/.active' "$G/.gitignore")"
check "graph-dir: settings permissions use the new folder" 1 "$(grep -cF '"Edit(.graph/**)"' "$G/.claude/settings.json")"
check "graph-dir: no old run path left in settings" 0 "$(grep -cE '(^|[^[:alnum:]_.])graph/' "$G/.claude/settings.json")"
I="$T/inj"; mkdir -p "$I"
bash "$KIT/install.sh" --graph-dir 'g$(id)' "$I" >/dev/null 2>&1; r=$?
check "graph-dir: shell characters rejected" 1 "$r"
check "graph-dir: nothing installed after rejection" no "$( [ -e "$I/.claude" ] && echo yes || echo no )"
bash "$KIT/install.sh" "$I" --graph-dir >/dev/null 2>&1; r=$?
check "graph-dir: missing value rejected" 1 "$r"
mkdir -p "$G/.graph"; touch "$G/.graph/.active"; printf 'false\n' > "$G/.claude/gate-commands"
echo '{}' | CLAUDE_PROJECT_DIR="$G" bash "$G/.claude/hooks/gate.sh" >/dev/null 2>&1; r=$?
check "graph-dir: gate blocks on .graph/.active" 2 "$r"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
