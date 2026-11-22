#!/usr/bin/env bash
# Install or update the graph-run kit in a target repository.
#
# Usage:
#   ./install.sh /path/to/your-repo                  first install; never overwrites anything
#   ./install.sh --update /path/to/your-repo         bring the kit's own files up to date
#   ./install.sh --graph-dir .graph /path/to/repo    keep run files in another folder (default: graph)
#
# The kit's own files are the /graph-run command, the two agents and the gate hook.
# --update replaces those (backing up any that differ) and never touches your
# settings.json, gate-commands, or any other agent or file.
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
UPDATE=0
GRAPH_DIR="graph"
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --update) UPDATE=1; shift ;;
    --graph-dir) GRAPH_DIR="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "Usage: $0 [--update] [--graph-dir DIR] /path/to/your-repo" >&2
  exit 1
fi
case "$GRAPH_DIR" in ''|/*|*..*|*' '*) echo "--graph-dir must be a relative folder name, such as .graph" >&2; exit 1 ;; esac
TARGET="$(cd "$TARGET" && pwd)"

OWNED=(.claude/commands/graph-run.md .claude/agents/graph-implementer.md .claude/agents/graph-verifier.md .claude/hooks/gate.sh)

# The kit file as it should stand in this repo: run-file paths moved to GRAPH_DIR.
render() { # render <relative path> <output file>
  if [ "$GRAPH_DIR" = "graph" ]; then
    cp "$KIT/$1" "$2"
  else
    GRAPH_DIR="$GRAPH_DIR" perl -pe 's#(?<![\w.])graph/#$ENV{GRAPH_DIR}/#g; s#"\$ROOT/graph"#"\$ROOT/$ENV{GRAPH_DIR}"#g' "$KIT/$1" > "$2"
  fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".claude/graph-run-backup/$STAMP"
skipped=(); updated=0

place() { # place <relative path>: add if missing; with --update, replace if different
  local rel="$1" dst="$TARGET/$1" new="$TMP/new"
  render "$rel" "$new"
  mkdir -p "$(dirname "$dst")"
  if [ ! -e "$dst" ]; then
    cp "$new" "$dst"; echo "  added   $rel"
  elif cmp -s "$new" "$dst"; then
    echo "  current $rel"
  elif [ "$UPDATE" = 1 ]; then
    mkdir -p "$TARGET/$BACKUP/$(dirname "$rel")"
    cp "$dst" "$TARGET/$BACKUP/$rel"
    cp "$new" "$dst"; echo "  updated $rel"; updated=$((updated + 1))
  else
    skipped+=("$rel")
  fi
}

if [ "$UPDATE" = 1 ]; then echo "Updating graph-run kit in $TARGET"; else echo "Installing graph-run kit into $TARGET"; fi
for rel in "${OWNED[@]}"; do place "$rel"; done
chmod +x "$TARGET/.claude/hooks/gate.sh"

if [ "$UPDATE" = 0 ]; then
  if [ -e "$TARGET/.claude/gate-commands" ]; then skipped+=(.claude/gate-commands); else cp "$KIT/.claude/gate-commands" "$TARGET/.claude/gate-commands"; echo "  added   .claude/gate-commands"; fi
  if [ -e "$TARGET/.claude/settings.json" ]; then
    cp "$KIT/.claude/settings.json" "$TARGET/.claude/settings.graph-run.json"
    echo "  added   .claude/settings.graph-run.json  (merge it into your settings.json by hand, then delete it)"
  else
    cp "$KIT/.claude/settings.json" "$TARGET/.claude/settings.json"; echo "  added   .claude/settings.json"
  fi
fi

mkdir -p "$TARGET/$GRAPH_DIR"
touch "$TARGET/.gitignore"
ignores=("$GRAPH_DIR/.active" "$GRAPH_DIR/.gate_attempts")
[ "$updated" -gt 0 ] && ignores+=(".claude/graph-run-backup/")
for line in "${ignores[@]}"; do
  grep -qxF "$line" "$TARGET/.gitignore" || { echo "$line" >> "$TARGET/.gitignore"; echo "  ignored $line"; }
done

if [ ${#skipped[@]} -gt 0 ]; then
  echo "Skipped (already present and different; run with --update to replace the kit's own files):"
  printf '  %s\n' "${skipped[@]}"
fi

if [ "$UPDATE" = 1 ]; then
  if [ "$updated" -gt 0 ]; then
    echo
    echo "Previous versions saved in $BACKUP/. Review the changes with:"
    echo "  diff -ru \"$TARGET/$BACKUP/.claude\" \"$TARGET/.claude\" | less"
  fi
  echo "Your settings.json, gate-commands and other agents were not touched."
  echo "Start a new Claude Code session in the repo so the updated command and agents load."
  exit 0
fi

cat <<'EOF'

Next:
  1. Edit the Edit(...) and Bash(...) allow rules in .claude/settings.json to match your stack and scope.
  2. Expert reviewers: /graph-run proposes them at plan approval. To write one yourself, copy
     templates/agents/domain-reviewer.md or security-reviewer.md into .claude/agents/.
  3. In Claude Code, run:  /graph-run <task, deliverable, checks, scope, limit>
EOF
