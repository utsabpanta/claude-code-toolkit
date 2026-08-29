#!/usr/bin/env bash
# common.sh — shared helpers for guardrails hooks.
#
# Source this at the top of every hook:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# Why this exists: Claude Code blocks a tool call only on exit code 2, or on a
# JSON stdout payload carrying hookSpecificOutput.permissionDecision = "deny".
# Exiting 1 prints a message and lets the action through. Hand-rolling that JSON
# in every hook is how a "security" hook silently becomes a no-op, so every hook
# in this plugin goes through deny() / warn() / add_context() instead.
#
# Reference: https://code.claude.com/docs/en/hooks

# Read stdin exactly once. Every hook needs the payload, and stdin is not seekable.
HOOK_INPUT="$(cat)"
export HOOK_INPUT

# hook_field <jq-filter> [default]
# Query the payload. Returns the default (empty by default) when jq is missing,
# the filter does not match, or the value is null.
hook_field() {
  local filter="$1" default="${2-}" out
  if ! command -v jq >/dev/null 2>&1; then
    printf '%s' "$default"
    return 0
  fi
  out="$(printf '%s' "$HOOK_INPUT" | jq -r "$filter // empty" 2>/dev/null)" || out=""
  printf '%s' "${out:-$default}"
}

# hook_event — the firing event name, e.g. PreToolUse.
hook_event() { hook_field '.hook_event_name' "PreToolUse"; }

# json_string <text> — encode text as a JSON string literal, quotes included.
json_string() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -Rs .
  else
    # Minimal fallback: escape backslash, quote, and newline.
    printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' ' ')"
  fi
}

# deny <reason>
# Block the tool call and tell Claude why. Emits the documented JSON payload and
# exits 0; exit 2 with the reason on stderr is the documented fallback for hosts
# that do not parse JSON, so we do both and let the JSON win.
deny() {
  local reason="$1" event
  event="$(hook_event)"
  printf '{"hookSpecificOutput":{"hookEventName":%s,"permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(json_string "$event")" "$(json_string "$reason")"
  exit 0
}

# ask <reason> — require an explicit human approval prompt instead of blocking outright.
ask() {
  local reason="$1" event
  event="$(hook_event)"
  printf '{"hookSpecificOutput":{"hookEventName":%s,"permissionDecision":"ask","permissionDecisionReason":%s}}\n' \
    "$(json_string "$event")" "$(json_string "$reason")"
  exit 0
}

# add_context <text> — inject text into the conversation without blocking anything.
add_context() {
  local text="$1" event
  event="$(hook_event)"
  printf '{"hookSpecificOutput":{"hookEventName":%s,"additionalContext":%s}}\n' \
    "$(json_string "$event")" "$(json_string "$text")"
  exit 0
}

# warn <text> — advisory only. Goes to stderr, never blocks.
warn() { printf '%s\n' "$1" >&2; }

# allow — explicit no-op, for readability at the end of a hook.
allow() { exit 0; }

# require_jq — fail open when jq is absent rather than breaking the session.
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    warn "guardrails: jq not found; hook skipped. Install jq to enable this guardrail."
    exit 0
  fi
}
