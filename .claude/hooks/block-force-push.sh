#!/usr/bin/env bash
# block-force-push.sh
#
# PreToolUse hook: blocks `git push --force` and related variants unless an explicit
# override file exists. Protects against Claude overwriting remote history.
#
# Override: create ~/.claude/allow-force-push for 10 minutes, then the hook allows it once.
#   touch ~/.claude/allow-force-push
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PreToolUse": [
#         {
#           "matcher": "Bash",
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/block-force-push.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Match: --force, -f, --force-with-lease on a push
if echo "$cmd" | grep -qE 'git[[:space:]]+push([[:space:]].*)?([[:space:]]-f([[:space:]]|$)|[[:space:]]--force([[:space:]]|$|=)|[[:space:]]--force-with-lease)'; then
  override=~/.claude/allow-force-push
  if [ -f "$override" ]; then
    # Honor override only if recent (within 10 minutes) and consume it
    if [ -n "$(find "$override" -mmin -10 2>/dev/null)" ]; then
      rm -f "$override"
      exit 0
    fi
  fi
  echo "Blocked: git push --force requires explicit user approval. If you really want this, ask the user to run: touch ~/.claude/allow-force-push"
  exit 1
fi

exit 0
