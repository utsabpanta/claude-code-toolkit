#!/usr/bin/env bash
# Shared helpers for the guardrails hook test suites.

HOOKS_DIR="${BATS_TEST_DIRNAME}/../plugins/guardrails/hooks"
export HOOKS_DIR

# run_hook <script> <json>  — feed a payload on stdin, capture stdout.
run_hook() {
  local script="$1" payload="$2"
  printf '%s' "$payload" | "${HOOKS_DIR}/${script}"
}

# pretooluse <tool> <input-json-object>
pretooluse() {
  printf '{"hook_event_name":"PreToolUse","session_id":"test","cwd":"%s","tool_name":"%s","tool_input":%s}' \
    "${BATS_TEST_TMPDIR:-/tmp}" "$1" "$2"
}

posttooluse() {
  printf '{"hook_event_name":"PostToolUse","session_id":"test","cwd":"%s","tool_name":"%s","tool_input":%s}' \
    "${BATS_TEST_TMPDIR:-/tmp}" "$1" "$2"
}

# Assert the hook denied the call. This is the regression test that matters:
# a hook that merely prints a refusal and exits 1 does NOT block anything.
assert_denied() {
  local out="$1"
  [ -n "$out" ] || { echo "expected a deny payload, got empty output"; return 1; }
  local decision
  decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty')"
  [ "$decision" = "deny" ] || { echo "expected permissionDecision=deny, got '${decision:-none}' in: $out"; return 1; }
  local reason
  reason="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // empty')"
  [ -n "$reason" ] || { echo "deny payload carried no reason: $out"; return 1; }
}

assert_asked() {
  local out="$1" decision
  decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty')"
  [ "$decision" = "ask" ] || { echo "expected permissionDecision=ask, got '${decision:-none}' in: $out"; return 1; }
}

assert_allowed() {
  local out="$1" decision
  decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)"
  [ -z "$decision" ] || { echo "expected no permission decision, got '$decision'"; return 1; }
}

assert_context() {
  local out="$1" ctx
  ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // empty')"
  [ -n "$ctx" ] || { echo "expected additionalContext, got: $out"; return 1; }
}
