#!/usr/bin/env bash
# Custom Claude Code status line.
#
# Shows: <model> | <cwd basename> | <git branch><dirty-marker><ahead/behind> | <session cost>
#
# Example:
#   sonnet-4-6 | my-app | main* ↑2 | $0.42
#
# To install:
#   1. Copy to a stable location:
#        mkdir -p ~/.claude/statusline
#        cp statusline.sh ~/.claude/statusline/
#        chmod +x ~/.claude/statusline/statusline.sh
#
#   2. Register in ~/.claude/settings.json:
#        {
#          "statusLine": {
#            "type": "command",
#            "command": "/absolute/path/to/statusline.sh"
#          }
#        }
#
#   3. Restart Claude Code.
#
# The harness pipes a JSON blob to stdin each time it redraws the status line:
#   {
#     "model": { "display_name": "..." },
#     "workspace": { "current_dir": "..." },
#     "session_id": "...",
#     "cost": { "total_cost_usd": 0.42 }   # may not always be present
#   }

set -euo pipefail

input=$(cat)

# --- Parse fields from the JSON input ---
model=$(printf '%s' "$input"    | jq -r '.model.display_name // .model.id // "claude"')
cwd=$(printf '%s' "$input"      | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd=$(pwd)
cost=$(printf '%s' "$input"     | jq -r '.cost.total_cost_usd // empty')

cwd_base=$(basename "$cwd")

# --- Git info (optional) ---
git_info=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
           || echo "?")
  dirty=""
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    dirty="*"
  fi

  # ahead/behind upstream
  ab=""
  upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  if [ -n "$upstream" ]; then
    read -r ahead behind < <(git -C "$cwd" rev-list --left-right --count "$upstream"...HEAD 2>/dev/null | awk '{print $2, $1}')
    [ "${ahead:-0}" -gt 0 ] && ab="${ab}↑${ahead}"
    [ "${behind:-0}" -gt 0 ] && ab="${ab}↓${behind}"
  fi

  git_info="${branch}${dirty}${ab:+ $ab}"
fi

# --- Cost formatting ---
cost_str=""
if [ -n "$cost" ] && [ "$cost" != "null" ]; then
  cost_str=$(printf '$%.2f' "$cost")
fi

# --- Compose output ---
parts=("$model" "$cwd_base")
[ -n "$git_info" ] && parts+=("$git_info")
[ -n "$cost_str" ] && parts+=("$cost_str")

printf '%s' "${parts[0]}"
for p in "${parts[@]:1}"; do
  printf ' | %s' "$p"
done
