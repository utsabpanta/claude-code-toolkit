#!/usr/bin/env bash
# audit-log.sh — SessionStart | SessionEnd | PostToolUse
#
# Appends a JSONL audit trail of what the agent did. Written for teams that need
# to answer "what did Claude change, in which repo, and when" after the fact.
#
# Location: $GUARDRAILS_AUDIT_LOG, else ~/.claude/audit/<repo-name>.jsonl
# Nothing is ever sent off the machine.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

cwd="$(hook_field '.cwd')"
[ -z "$cwd" ] && cwd="$PWD"

if [ -n "${GUARDRAILS_AUDIT_LOG:-}" ]; then
  logfile="$GUARDRAILS_AUDIT_LOG"
else
  repo="$(basename "$cwd")"
  logfile="$HOME/.claude/audit/${repo}.jsonl"
fi
mkdir -p "$(dirname "$logfile")" 2>/dev/null || allow

entry="$(printf '%s' "$HOOK_INPUT" | jq -c \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
     ts: $ts,
     event: (.hook_event_name // "unknown"),
     session: (.session_id // null),
     cwd: (.cwd // null),
     tool: (.tool_name // null),
     target: (.tool_input.file_path // .tool_input.path // .tool_input.command // null)
   }' 2>/dev/null)" || allow

[ -z "$entry" ] && allow
printf '%s\n' "$entry" >> "$logfile" 2>/dev/null || true

# Keep the file bounded so it never grows without limit.
if [ -f "$logfile" ]; then
  lines="$(wc -l < "$logfile" 2>/dev/null | tr -d '[:space:]')"
  if [ -n "$lines" ] && [ "$lines" -gt 20000 ] 2>/dev/null; then
    tail -n 10000 "$logfile" > "${logfile}.tmp" 2>/dev/null && mv "${logfile}.tmp" "$logfile"
  fi
fi

allow
