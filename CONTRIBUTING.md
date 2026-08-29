# Contributing

The bar here is different from most collections: **a guardrail that does not
block is worse than no guardrail**, because it produces false confidence. So
hooks need tests, and the tests assert the decision rather than the exit code.

## Before you open a PR

```bash
bats tests/
shellcheck -S warning -x plugins/guardrails/hooks/*.sh plugins/guardrails/hooks/lib/*.sh scripts/*.sh
./scripts/doctor.sh .
```

CI runs all three plus frontmatter validation, a link check, and an emoji check.

Install `bats-core`, `shellcheck`, and `jq` first (`brew install bats-core
shellcheck jq`).

## Adding a hook

1. Put it in `plugins/guardrails/hooks/`. Name a blocking hook `guard-*.sh`.
2. Source the shared library and use its helpers. **Do not hand-roll the decision
   JSON** — that is how the original bug happened:

   ```bash
   #!/usr/bin/env bash
   set -uo pipefail
   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
   require_jq
   ```

   `deny "reason"` blocks. `ask "reason"` prompts. `add_context "text"` injects
   context without blocking. `warn` writes to stderr. `allow` is an explicit
   no-op.
3. Use `set -uo pipefail`, **not** `set -euo pipefail`. Under `set -e` a `jq`
   filter that matches nothing aborts the hook before it reaches the decision.
4. Fail open. If `jq` is missing or the payload is unexpected, exit 0.
5. `chmod +x` it. A non-executable hook fails silently.
6. Wire it in `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}`, never an absolute
   path. If it should not be on by default, say why in the PR — `test-on-edit.sh`
   is the precedent.
7. **Write the tests.** At minimum one positive and one negative:

   ```bash
   @test "denies X" {
     run -0 run_hook my-hook.sh "$(pretooluse Write '{"file_path":"/x"}')"
     assert_denied "$output"
   }

   @test "allows an ordinary file" {
     run -0 run_hook my-hook.sh "$(pretooluse Write '{"file_path":"/src/a.ts"}')"
     assert_allowed "$output"
   }
   ```

   The negative test is not optional. A hook that denies everything passes every
   deny test and makes the tool unusable.
8. Add it to the README table and `docs/hooks.md`.

### deny or ask?

`deny` is for what is never intended and unrecoverable: `rm -rf /`, `mkfs`,
`curl | sh`. `ask` is for what is legitimate but destroys work: `git reset
--hard`, `DROP TABLE`, a production config edit.

Get this wrong toward `deny` and the whole plugin gets uninstalled the first
afternoon someone needs the thing you blocked.

## Adding a skill

Default to a skill over a slash command; `commands/` is the legacy form.

- One skill, one job. If a request implies two, propose two skills.
- Folder name must equal the frontmatter `name`. Lowercase and hyphenated.
- `description` in the **third person**, naming concrete triggers: "This skill
  should be used when the user asks to X, says Y, or types /z." This is the text
  Claude matches against, so it is the most important line in the file.
- Declare `allowed-tools`, scoped as narrowly as the skill allows.
- Keep `SKILL.md` under about 2,000 words. Move templates, edge cases, and long
  tables into `references/` — they cost no context until Claude opens them.
- Write the body addressed to Claude, in the imperative.
- Include runnable commands, not "grep for X". The difference between a skill and
  an essay is whether it says what to actually run.

**Do not add a skill that duplicates a first-party plugin.** Anthropic ships
commits, code review, PR review, plugin development, and hook creation. We
deleted our versions of all of these in 1.0.0.

## Adding an agent

Frontmatter: `name`, `description`, `tools`, and optionally `model`
(`sonnet`, `opus`, `haiku`, `fable`, `inherit`, or a full model id — `inherit` is
usually right), `color`, `disallowedTools`, `maxTurns`, `permissionMode`,
`effort`, `memory`, `isolation`.

Give read-only reviewers `disallowedTools: Write, Edit, NotebookEdit` so the
constraint is enforced rather than implied.

Agents run in a separate context window. That is the point: reach for one when
you want a fresh opinion, not just to organize a prompt.

## Conventions

- ATX headers (`#`), not Setext.
- Skills and agents address Claude as "you". Docs and READMEs address humans.
- **No emoji in file contents.** CI enforces this.
- No examples referencing secrets, internal URLs, or named individuals. This is
  public.
- Prefer editing an existing file to adding a new one.

## Bumping versions

Behavior changes bump `version` in the relevant
`plugins/*/.claude-plugin/plugin.json` and the matching entry in
`.claude-plugin/marketplace.json`. Keep the two in sync and add a `CHANGELOG.md`
entry. Both manifests must be valid JSON — no trailing commas, no comments.

## What will not be merged

- A hook without tests.
- A hook that blocks by exiting 1.
- A skill duplicating a first-party plugin.
- A permission rule that broadens `allow` to make one command work.
- Anything that sends hook payloads off the machine. They contain file contents
  and command strings.
