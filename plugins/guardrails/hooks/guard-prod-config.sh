#!/usr/bin/env bash
# guard-prod-config.sh — PreToolUse(Edit|Write|NotebookEdit)
#
# Requires explicit confirmation before editing infrastructure that deploys to
# production, and before editing CI workflow files (a CI workflow edit is a
# supply-chain change: it runs with repository credentials).

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

file="$(hook_field '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path')"
[ -z "$file" ] && allow

case "$file" in
  */.github/workflows/*|.github/workflows/*)
    ask "Editing a CI workflow ($file) changes code that runs with repository credentials and can publish artifacts. Confirm the change is intended and review it before merge." ;;
esac

case "$file" in
  *prod*|*live/*)
    case "$file" in
      *.tf|*.tfvars|*.yaml|*.yml|*.json|*.toml|*.hcl)
        ask "$file looks like production infrastructure configuration. Confirm the target environment before changing it." ;;
    esac ;;
esac

base="$(basename "$file")"
case "$base" in
  terraform.tfstate|terraform.tfstate.backup)
    deny "Refused to edit $file by hand. Terraform state must be changed through terraform, not a text editor; hand edits corrupt the state file." ;;
  values-prod.yaml|values-production.yaml|values.prod.yaml)
    ask "$file is a production Helm values file. Confirm the environment and the rollout plan." ;;
esac

allow
