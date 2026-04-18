#!/usr/bin/env bash
# block-env-writes.sh
#
# PreToolUse hook: refuses Write/Edit operations against files that commonly hold secrets.
# Prevents Claude from overwriting your .env file or leaking credentials into code.
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PreToolUse": [
#         {
#           "matcher": "Edit|Write",
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/block-env-writes.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
[ -z "$file" ] && exit 0

# Normalize to basename for matching
base=$(basename "$file")

# Patterns to block — tweak for your environment
case "$base" in
  .env|.env.*|*.env)
    echo "Blocked: refuses to modify env file ($file). If you really want to, edit it yourself."
    exit 1
    ;;
  id_rsa|id_ed25519|id_ecdsa|*.pem|*.key|*.p12|*.pfx)
    echo "Blocked: refuses to modify key material ($file)."
    exit 1
    ;;
  credentials|credentials.json|service-account*.json)
    echo "Blocked: refuses to modify credentials file ($file)."
    exit 1
    ;;
esac

# Also catch anything under a secrets/ directory
case "$file" in
  */secrets/*|*/private/*)
    echo "Blocked: refuses to modify files under secrets/ or private/ ($file)."
    exit 1
    ;;
esac

exit 0
