#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
load helper

setup() {
  export GUARDRAILS_AUDIT_LOG="${BATS_TEST_TMPDIR}/audit.jsonl"
}

@test "records a tool use as one JSON line" {
  run -0 run_hook audit-log.sh "$(posttooluse Write '{"file_path":"/repo/src/a.ts"}')"
  [ -f "$GUARDRAILS_AUDIT_LOG" ]
  run -0 jq -r '.tool' "$GUARDRAILS_AUDIT_LOG"
  [ "$output" = "Write" ]
}

@test "records the target path" {
  run_hook audit-log.sh "$(posttooluse Write '{"file_path":"/repo/src/a.ts"}')"
  run -0 jq -r '.target' "$GUARDRAILS_AUDIT_LOG"
  [ "$output" = "/repo/src/a.ts" ]
}

@test "records a bash command as the target" {
  run_hook audit-log.sh "$(posttooluse Bash '{"command":"npm test"}')"
  run -0 jq -r '.target' "$GUARDRAILS_AUDIT_LOG"
  [ "$output" = "npm test" ]
}

@test "appends rather than overwriting" {
  run_hook audit-log.sh "$(posttooluse Write '{"file_path":"/a"}')"
  run_hook audit-log.sh "$(posttooluse Write '{"file_path":"/b"}')"
  run -0 wc -l < "$GUARDRAILS_AUDIT_LOG"
  [ "${output// /}" = "2" ]
}

@test "every line carries a UTC timestamp" {
  run_hook audit-log.sh "$(posttooluse Write '{"file_path":"/a"}')"
  run -0 jq -r '.ts' "$GUARDRAILS_AUDIT_LOG"
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "never blocks the tool call" {
  run -0 run_hook audit-log.sh "$(posttooluse Write '{"file_path":"/a"}')"
  assert_allowed "$output"
}
