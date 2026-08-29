#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
load helper

@test "prompts a supply-chain check when package.json changes" {
  run -0 run_hook guard-dependency-add.sh "$(posttooluse Edit '{"file_path":"/repo/package.json"}')"
  assert_context "$output"
}

@test "prompts a supply-chain check when go.mod changes" {
  run -0 run_hook guard-dependency-add.sh "$(posttooluse Edit '{"file_path":"/repo/go.mod"}')"
  assert_context "$output"
}

@test "prompts a supply-chain check when Cargo.toml changes" {
  run -0 run_hook guard-dependency-add.sh "$(posttooluse Write '{"file_path":"/repo/Cargo.toml"}')"
  assert_context "$output"
}

@test "stays quiet for an ordinary source file" {
  run -0 run_hook guard-dependency-add.sh "$(posttooluse Edit '{"file_path":"/repo/src/main.rs"}')"
  [ -z "$output" ]
}

@test "stays quiet for package-lock.json, which is generated" {
  run -0 run_hook guard-dependency-add.sh "$(posttooluse Edit '{"file_path":"/repo/package-lock.json"}')"
  [ -z "$output" ]
}
