#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
load helper

# These test the helper that every hook depends on. If deny() regresses,
# every "security" hook in the plugin silently stops blocking.

@test "deny emits a well-formed deny payload and exits 0" {
  run -0 bash -c 'echo "{\"hook_event_name\":\"PreToolUse\"}" | { source '"$HOOKS_DIR"'/lib/common.sh; deny "nope"; }'
  assert_denied "$output"
}

@test "deny carries the reason verbatim" {
  run -0 bash -c 'echo "{\"hook_event_name\":\"PreToolUse\"}" | { source '"$HOOKS_DIR"'/lib/common.sh; deny "specific reason here"; }'
  run -0 bash -c "printf '%s' '$output' | jq -r '.hookSpecificOutput.permissionDecisionReason'"
  [ "$output" = "specific reason here" ]
}

@test "deny echoes back the firing event name" {
  run -0 bash -c 'echo "{\"hook_event_name\":\"PostToolBatch\"}" | { source '"$HOOKS_DIR"'/lib/common.sh; deny "x"; }'
  run -0 bash -c "printf '%s' '$output' | jq -r '.hookSpecificOutput.hookEventName'"
  [ "$output" = "PostToolBatch" ]
}

@test "reasons containing quotes and newlines stay valid JSON" {
  run -0 bash -c 'echo "{\"hook_event_name\":\"PreToolUse\"}" | { source '"$HOOKS_DIR"'/lib/common.sh; deny "he said \"no\"
on a second line"; }'
  run -0 bash -c "printf '%s' '$output' | jq -e . >/dev/null && echo ok"
  [ "$output" = "ok" ]
}

@test "ask emits an ask decision" {
  run -0 bash -c 'echo "{\"hook_event_name\":\"PreToolUse\"}" | { source '"$HOOKS_DIR"'/lib/common.sh; ask "confirm?"; }'
  assert_asked "$output"
}

@test "add_context emits additionalContext" {
  run -0 bash -c 'echo "{\"hook_event_name\":\"PostToolUse\"}" | { source '"$HOOKS_DIR"'/lib/common.sh; add_context "note"; }'
  assert_context "$output"
}

@test "hook_field returns a default when the key is absent" {
  run -0 bash -c 'echo "{}" | { source '"$HOOKS_DIR"'/lib/common.sh; hook_field ".missing" "fallback"; }'
  [ "$output" = "fallback" ]
}

@test "allow produces no output" {
  run -0 bash -c 'echo "{}" | { source '"$HOOKS_DIR"'/lib/common.sh; allow; }'
  [ -z "$output" ]
}
