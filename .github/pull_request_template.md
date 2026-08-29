## What this changes

## Why

<!-- If this adds or changes a hook, all four boxes are required. -->

## Checklist

- [ ] `bats tests/` passes
- [ ] `shellcheck -S warning -x plugins/guardrails/hooks/*.sh` is clean
- [ ] `./scripts/doctor.sh .` reports 0 errors
- [ ] New or changed hooks have a test asserting the **decision** (`assert_denied`,
      `assert_asked`, `assert_allowed`), not just the exit code
- [ ] New or changed hooks have a negative test proving they do not over-block
- [ ] No emoji in file contents
- [ ] Docs updated if behavior changed

## If this adds a hook

- [ ] It sources `hooks/lib/common.sh` rather than hand-rolling the decision JSON
- [ ] It uses `set -uo pipefail`, not `set -euo pipefail`
- [ ] It fails open when `jq` is missing
- [ ] It is wired in `plugins/guardrails/hooks/hooks.json`, or the PR says why not
- [ ] It is listed in the README table and `docs/hooks.md`
