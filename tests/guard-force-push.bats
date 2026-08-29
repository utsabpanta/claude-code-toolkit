#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
load helper

@test "denies git push --force" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"git push --force origin main"}')"
  assert_denied "$output"
}

@test "denies git push -f" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"git push -f origin main"}')"
  assert_denied "$output"
}

@test "denies git push --force-with-lease" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"git push --force-with-lease"}')"
  assert_denied "$output"
}

@test "denies a plus-refspec force push" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"git push origin +main:main"}')"
  assert_denied "$output"
}

@test "denies a force push with a global git flag before the subcommand" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"git -C /repo push --force origin main"}')"
  assert_denied "$output"
}

@test "allows an ordinary push" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"git push origin main"}')"
  assert_allowed "$output"
}

@test "allows an unrelated command that contains the word force" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"grep -r force ./src"}')"
  assert_allowed "$output"
}

@test "allows git pull" {
  run -0 run_hook guard-force-push.sh "$(pretooluse Bash '{"command":"git pull --rebase"}')"
  assert_allowed "$output"
}
