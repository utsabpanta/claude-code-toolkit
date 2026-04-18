#!/usr/bin/env bash
# notify-on-idle.sh
#
# Notification hook: triggers a desktop notification + sound whenever Claude is
# waiting on the user (e.g. permission prompt, asking a question).
# Lets you tab away without missing when Claude needs attention.
#
# Works on macOS (osascript) and Linux (notify-send). Adjust for your OS.
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "Notification": [
#         {
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/notify-on-idle.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

input=$(cat)
message=$(echo "$input" | jq -r '.message // "Claude needs your attention"')
# Truncate long messages for the notification
short=${message:0:120}

case "$(uname -s)" in
  Darwin)
    # macOS: native notification + subtle sound
    osascript -e "display notification \"$short\" with title \"Claude Code\" sound name \"Glass\"" 2>/dev/null || true
    ;;
  Linux)
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "Claude Code" "$short" 2>/dev/null || true
    fi
    ;;
esac

exit 0
