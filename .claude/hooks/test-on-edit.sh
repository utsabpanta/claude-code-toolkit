#!/usr/bin/env bash
# test-on-edit.sh
#
# PostToolUse hook: when Claude edits a source file, run the nearest test file
# (if one exists). Tight feedback loop — you'll see failures as Claude introduces them.
#
# Opt-in per project. Disable when you don't want test runs on every edit by setting
# CLAUDE_SKIP_TEST_ON_EDIT=1 in your shell environment.
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PostToolUse": [
#         {
#           "matcher": "Edit|Write",
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/test-on-edit.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

[ "${CLAUDE_SKIP_TEST_ON_EDIT:-}" = "1" ] && exit 0

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')

[ -z "$file" ] && exit 0
[ ! -f "$file" ] && exit 0

dir=$(dirname "$file")
base=$(basename "$file")
name="${base%.*}"
ext="${base##*.}"

# Find a nearby test file. Heuristic — prefer explicit test matching the source.
find_test() {
  case "$ext" in
    js|jsx|ts|tsx|mjs|cjs)
      # Same-dir __tests__/name.test.ext, or name.test.ext, or name.spec.ext
      for candidate in \
        "$dir/__tests__/$name.test.$ext" \
        "$dir/$name.test.$ext" \
        "$dir/$name.spec.$ext" \
        "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)/test/${name}.test.$ext" ; do
        [ -f "$candidate" ] && echo "$candidate" && return 0
      done
      ;;
    py)
      for candidate in \
        "$dir/test_${name}.py" \
        "$dir/${name}_test.py" \
        "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)/tests/test_${name}.py" ; do
        [ -f "$candidate" ] && echo "$candidate" && return 0
      done
      ;;
    go)
      [ -f "${dir}/${name}_test.go" ] && echo "${dir}/${name}_test.go" && return 0
      ;;
    rs)
      # Rust tests are usually inline — run cargo test for the crate
      ;;
    rb)
      for candidate in \
        "$dir/${name}_spec.rb" \
        "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)/spec/${name}_spec.rb" ; do
        [ -f "$candidate" ] && echo "$candidate" && return 0
      done
      ;;
  esac
  return 1
}

test_file=$(find_test || true)

run_and_report() {
  local cmd="$1"
  local desc="$2"
  echo "" >&2
  echo "▶ test-on-edit: $desc" >&2
  # Run with a 30s timeout so a runaway test suite doesn't block the session
  if output=$(timeout 30 bash -c "$cmd" 2>&1); then
    echo "  ✓ passed" >&2
  else
    echo "  ✗ failed:" >&2
    echo "$output" | tail -20 | sed 's/^/    /' >&2
  fi
  echo "" >&2
}

# Dispatch based on file type
case "$ext" in
  js|jsx|ts|tsx|mjs|cjs)
    if [ -n "$test_file" ]; then
      repo_root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "")
      if command -v npx >/dev/null 2>&1 && [ -n "$repo_root" ] && [ -f "$repo_root/package.json" ]; then
        # Detect which runner the project uses — do NOT fall back between them,
        # or a real test failure in one will be masked by the other "passing."
        if [ -d "$repo_root/node_modules/jest" ] || grep -q '"jest"' "$repo_root/package.json" 2>/dev/null; then
          run_and_report "cd '$repo_root' && npx --no-install jest '$test_file'" "jest $test_file"
        elif [ -d "$repo_root/node_modules/vitest" ] || grep -q '"vitest"' "$repo_root/package.json" 2>/dev/null; then
          run_and_report "cd '$repo_root' && npx --no-install vitest run '$test_file'" "vitest $test_file"
        fi
      fi
    fi
    ;;
  py)
    if [ -n "$test_file" ] && command -v pytest >/dev/null 2>&1; then
      run_and_report "pytest -x -q '$test_file'" "pytest $test_file"
    fi
    ;;
  go)
    if [ -n "$test_file" ] && command -v go >/dev/null 2>&1; then
      run_and_report "cd '$dir' && go test -run '.' -count=1 ./..." "go test $dir"
    fi
    ;;
  rb)
    if [ -n "$test_file" ] && command -v rspec >/dev/null 2>&1; then
      run_and_report "rspec '$test_file'" "rspec $test_file"
    fi
    ;;
esac

exit 0
