#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
load helper

@test "asks before editing a CI workflow" {
  run -0 run_hook guard-prod-config.sh "$(pretooluse Edit '{"file_path":"/repo/.github/workflows/release.yml"}')"
  assert_asked "$output"
}

@test "asks before editing production terraform" {
  run -0 run_hook guard-prod-config.sh "$(pretooluse Edit '{"file_path":"/repo/infra/prod/main.tf"}')"
  assert_asked "$output"
}

@test "asks before editing a production helm values file" {
  run -0 run_hook guard-prod-config.sh "$(pretooluse Write '{"file_path":"/repo/chart/values-prod.yaml"}')"
  assert_asked "$output"
}

@test "denies hand-editing terraform state" {
  run -0 run_hook guard-prod-config.sh "$(pretooluse Edit '{"file_path":"/repo/terraform.tfstate"}')"
  assert_denied "$output"
}

@test "allows editing staging infrastructure" {
  run -0 run_hook guard-prod-config.sh "$(pretooluse Edit '{"file_path":"/repo/infra/staging/main.tf"}')"
  assert_allowed "$output"
}

@test "allows an ordinary source file" {
  run -0 run_hook guard-prod-config.sh "$(pretooluse Write '{"file_path":"/repo/src/app.ts"}')"
  assert_allowed "$output"
}
