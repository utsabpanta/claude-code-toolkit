#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
load helper

@test "denies writing a .env file" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/app/.env"}')"
  assert_denied "$output"
}

@test "denies writing an environment-suffixed env file" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/app/.env.production"}')"
  assert_denied "$output"
}

@test "denies writing a private key" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Edit '{"file_path":"/home/u/.ssh/id_ed25519"}')"
  assert_denied "$output"
}

@test "denies writing a PEM file" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/certs/server.pem"}')"
  assert_denied "$output"
}

@test "denies writing a service-account json" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/app/service-account-prod.json"}')"
  assert_denied "$output"
}

@test "denies anything under a secrets directory" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/app/secrets/token.txt"}')"
  assert_denied "$output"
}

@test "denies .npmrc which commonly holds a registry token" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/app/.npmrc"}')"
  assert_denied "$output"
}

@test "allows an ordinary source file" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/app/src/index.ts"}')"
  assert_allowed "$output"
}

@test "allows .env.example, which is a template and not a secret" {
  skip "documented limitation: .env.* is denied wholesale, including .env.example"
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{"file_path":"/app/.env.example"}')"
  assert_allowed "$output"
}

@test "allows a notebook path that is not sensitive" {
  run -0 run_hook guard-secrets.sh "$(pretooluse NotebookEdit '{"notebook_path":"/app/analysis.ipynb"}')"
  assert_allowed "$output"
}

@test "no file path in payload is a no-op" {
  run -0 run_hook guard-secrets.sh "$(pretooluse Write '{}')"
  assert_allowed "$output"
}
