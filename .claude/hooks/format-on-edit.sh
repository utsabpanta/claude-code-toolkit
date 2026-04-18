#!/usr/bin/env bash
# format-on-edit.sh
#
# PostToolUse hook: runs the right formatter for whichever file Claude just edited.
# Supports JS/TS (prettier), Python (black or ruff format), Go (gofmt), Rust (rustfmt).
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PostToolUse": [
#         {
#           "matcher": "Edit|Write|NotebookEdit",
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/format-on-edit.sh" }
#           ]
#         }
#       ]
#     }
#   }
#
# Silently no-ops if no formatter is installed for the file type — safe to leave on.

set -euo pipefail

# Read the JSON event from Claude Code
input=$(cat)

# Extract the file path Claude edited
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Nothing to do if we can't find a file path
[ -z "$file" ] && exit 0
[ ! -f "$file" ] && exit 0

case "$file" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.html|*.md|*.yml|*.yaml)
    if command -v prettier >/dev/null 2>&1; then
      prettier --write "$file" >/dev/null 2>&1 || true
    fi
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file" >/dev/null 2>&1 || true
    elif command -v black >/dev/null 2>&1; then
      black --quiet "$file" 2>/dev/null || true
    fi
    ;;
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$file" 2>/dev/null || true
    ;;
  *.rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt "$file" 2>/dev/null || true
    ;;
  *.rb)
    command -v rubocop >/dev/null 2>&1 && rubocop -A "$file" >/dev/null 2>&1 || true
    ;;
esac

exit 0
