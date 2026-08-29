#!/usr/bin/env bash
# auto-gitignore.sh
#
# PostToolUse hook: if Claude writes or edits a file whose path looks sensitive
# (e.g. .env, *.pem, credentials.json), print a warning and a suggested
# .gitignore entry. Does NOT auto-modify .gitignore — it just nudges the user.
#
# Safe to leave on: only emits to stderr, never blocks the tool call.
#
# Wired automatically by hooks/hooks.json when this plugin is enabled.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq
input="$HOOK_INPUT"
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

add_context "The file just written, '$rel', looks sensitive ($suspicious) and is not currently ignored by git. Suggest adding '$base' to .gitignore before it is committed, and confirm it has not already been staged."
