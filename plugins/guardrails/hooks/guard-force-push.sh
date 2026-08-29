#!/usr/bin/env bash
# guard-force-push.sh — PreToolUse(Bash)
#
# Blocks `git push --force` and its variants, plus other remote-history rewrites.
# A force push destroys commits other people may already have pulled.
#
# One-shot override, valid for 10 minutes and consumed on use:
#   touch ~/.claude/allow-force-push

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

cmd="$(hook_field '.tool_input.command')"
[ -z "$cmd" ] && allow

is_force_push=0
if printf '%s' "$cmd" | grep -qE 'git([[:space:]][^|;&]*)?[[:space:]]push([[:space:]]|$)'; then
  if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])(-f|--force|--force-with-lease|--force-if-includes)([[:space:]]|=|$)'; then
    is_force_push=1
  fi
  # `git push remote +branch` is a force push spelled with a refspec.
  if printf '%s' "$cmd" | grep -qE '[[:space:]]\+[A-Za-z0-9_./-]+:[A-Za-z0-9_./-]+'; then
    is_force_push=1
  fi
fi

if [ "$is_force_push" -eq 1 ]; then
  override="$HOME/.claude/allow-force-push"
  if [ -f "$override" ] && [ -n "$(find "$override" -mmin -10 2>/dev/null)" ]; then
    rm -f "$override"
    warn "guardrails: force-push override consumed."
    allow
  fi
  deny "Refused to force-push. This rewrites remote history and can destroy commits your teammates already pulled. If this is genuinely intended, ask the user to run: touch ~/.claude/allow-force-push  (valid once, for 10 minutes)."
fi

allow
