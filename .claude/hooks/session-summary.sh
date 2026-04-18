#!/usr/bin/env bash
# session-summary.sh
#
# Stop hook: appends a one-line record to ~/.claude/session.log every time Claude stops.
# Useful to see what you worked on across sessions.
#
# Log format:
#   2025-10-15T14:22:01  /path/to/repo  <session-id>
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "Stop": [
#         {
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/session-summary.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)

log=~/.claude/session.log
mkdir -p "$(dirname "$log")"

printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$cwd" "$session_id" >> "$log"

# Keep the log small: last 500 lines
if [ -f "$log" ]; then
  tail -n 500 "$log" > "$log.tmp" && mv "$log.tmp" "$log"
fi

exit 0
