#!/usr/bin/env bash
# auto-gitignore.sh
#
# PostToolUse hook: if Claude writes or edits a file whose path looks sensitive
# (e.g. .env, *.pem, credentials.json), print a warning and a suggested
# .gitignore entry. Does NOT auto-modify .gitignore — it just nudges the user.
#
# Safe to leave on: only emits to stderr, never blocks the tool call.
#
# Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PostToolUse": [
#         {
#           "matcher": "Edit|Write|NotebookEdit",
#           "hooks": [
#             { "type": "command", "command": "/absolute/path/to/auto-gitignore.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')

[ -z "$file" ] && exit 0

# Relative path for matching against .gitignore
repo_root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null || echo "")
[ -z "$repo_root" ] && exit 0  # not in a git repo, nothing to ignore

# Portable relative path (BSD realpath on macOS lacks --relative-to).
# Strip the repo root prefix; fall back to the absolute path if $file is outside it.
case "$file" in
  "$repo_root"/*) rel="${file#"$repo_root"/}" ;;
  *)              rel="$file" ;;
esac
base=$(basename "$file")

# Patterns that are almost always sensitive or noise
suspicious=""
case "$base" in
  # Order matters: specific filenames must come before wildcards that would swallow them
  # (e.g. `*.db` would match `Thumbs.db`).
  .DS_Store|Thumbs.db)                             suspicious="OS metadata file" ;;
  id_rsa|id_ed25519)                               suspicious="private key file" ;;
  credentials.json|service-account.json|*-key.json) suspicious="credential file" ;;
  .env|.env.*|*.env)                               suspicious=".env files typically contain secrets" ;;
  *.pem|*.key)                                     suspicious="private key file" ;;
  *.sqlite|*.sqlite3|*.db)                         suspicious="local database file" ;;
esac

[ -z "$suspicious" ] && exit 0

# Already in .gitignore?
gitignore="$repo_root/.gitignore"
if [ -f "$gitignore" ] && git -C "$repo_root" check-ignore --quiet "$rel" 2>/dev/null; then
  exit 0
fi

# Nudge the user (stderr — visible in Claude Code's hook output, does not block)
echo "" >&2
echo "⚠  auto-gitignore: '$rel' looks sensitive ($suspicious)." >&2
echo "   It is NOT currently ignored by git." >&2
echo "   Consider adding to .gitignore:" >&2
echo "     $base" >&2
echo "" >&2

exit 0
