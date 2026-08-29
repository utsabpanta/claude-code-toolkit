#!/usr/bin/env bash
# guard-secrets.sh — PreToolUse(Edit|Write|NotebookEdit)
#
# Blocks writes to files that hold credentials: .env files, private keys,
# service-account JSON, and anything under secrets/ or private/.
#
# Wired automatically by hooks/hooks.json when this plugin is enabled.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

file="$(hook_field '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path')"
[ -z "$file" ] && allow

base="$(basename "$file")"

case "$base" in
  .env|.env.*|*.env)
    deny "Refused to modify the env file $file. Environment files hold live credentials and are not safe for an agent to rewrite. Edit it yourself, or move the value into a template such as .env.example." ;;
  id_rsa|id_dsa|id_ed25519|id_ecdsa|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore)
    deny "Refused to modify key material at $file. Private keys must be rotated through your key management process, not edited in place." ;;
  credentials|credentials.json|.netrc|.pgpass|service-account*.json|*-service-account.json)
    deny "Refused to modify the credentials file $file. Rotate these through your secret manager instead." ;;
  .npmrc|.pypirc|.dockercfg|.docker-config.json)
    deny "Refused to modify $file. Package-registry config files commonly carry auth tokens." ;;
esac

case "$file" in
  */secrets/*|secrets/*|*/private/*|private/*|*/.aws/*|*/.ssh/*|*/.gnupg/*)
    deny "Refused to modify $file. Paths under secrets/, private/, .aws/, .ssh/, or .gnupg/ are treated as credential stores." ;;
esac

allow
