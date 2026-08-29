#!/usr/bin/env bash
# pre-commit-lint.sh
#
# PreToolUse hook: when Claude is about to run `git commit`, lint the staged
# files first. If the linter reports errors, block the commit and surface them.
#
# Supports eslint (JS/TS), ruff (Python), golangci-lint (Go), shellcheck (shell).
# Silently no-ops if no linter is configured for a staged file.
#
# Wired automatically by hooks/hooks.json when this plugin is enabled.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq
input="$HOOK_INPUT"
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
  deny "Linter errors in staged files. Fix them, or unstage the offending files, then retry the commit. Do not pass --no-verify.

$(printf '%s' "$failures" | sed 's/^/  /')"
fi

exit 0
