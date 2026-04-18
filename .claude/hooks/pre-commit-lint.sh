#!/usr/bin/env bash
# pre-commit-lint.sh
#
# PreToolUse hook: when Claude is about to run `git commit`, lint the staged
# files first. If the linter reports errors, block the commit and surface them.
#
# Supports eslint (JS/TS), ruff (Python), golangci-lint (Go), shellcheck (shell).
# Silently no-ops if no linter is configured for a staged file.
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PreToolUse": [
#         {
#           "matcher": "Bash",
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/pre-commit-lint.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only act on git commit commands
if ! echo "$cmd" | grep -qE '^\s*git\s+commit(\s|$)'; then
  exit 0
fi

# Get staged files
staged=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")
[ -z "$staged" ] && exit 0

failures=""
record_failure() {
  failures+="$1"$'\n'
}

while IFS= read -r file; do
  [ -z "$file" ] && continue
  [ ! -f "$file" ] && continue

  case "$file" in
    *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs)
      repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
      if command -v npx >/dev/null 2>&1 && [ -n "$repo_root" ] && [ -f "$repo_root/package.json" ]; then
        if ! output=$(cd "$repo_root" && npx --no-install eslint "$file" 2>&1); then
          record_failure "eslint: $file"$'\n'"$output"
        fi
      fi
      ;;
    *.py)
      if command -v ruff >/dev/null 2>&1; then
        if ! output=$(ruff check "$file" 2>&1); then
          record_failure "ruff: $file"$'\n'"$output"
        fi
      fi
      ;;
    *.go)
      if command -v golangci-lint >/dev/null 2>&1; then
        if ! output=$(golangci-lint run "$file" 2>&1); then
          record_failure "golangci-lint: $file"$'\n'"$output"
        fi
      fi
      ;;
    *.sh|*.bash)
      if command -v shellcheck >/dev/null 2>&1; then
        if ! output=$(shellcheck "$file" 2>&1); then
          record_failure "shellcheck: $file"$'\n'"$output"
        fi
      fi
      ;;
  esac
done <<< "$staged"

if [ -n "$failures" ]; then
  # Exit code 2 = block the tool call; stderr is shown to the user
  echo "" >&2
  echo "✗ pre-commit-lint: linter errors in staged files. Fix these or unstage the offending files, then retry:" >&2
  echo "" >&2
  echo "$failures" | sed 's/^/  /' >&2
  echo "" >&2
  echo "To skip this hook for a specific commit: git commit --no-verify (harness hook is separate and still applies)." >&2
  exit 2
fi

exit 0
