# Guidance for Claude

This repo is the Claude Code guardrails toolkit: tested safety hooks, permission policies, and specialist review agents, published as a marketplace with two plugins.

## What this repo is

A marketplace shipping two plugins.

- `plugins/guardrails/` — **the flagship.** Blocking safety hooks, wired via
  `hooks/hooks.json` so `/plugin install` needs no `settings.json` editing.
  Also `policies/` (permission profiles) and three skills about Claude Code
  configuration itself.
- `plugins/team-power-pack/` — 12 specialist agents, 17 skills, 4 output styles,
  a status line.
- `.claude-plugin/marketplace.json` — lists both plugins.
- `tests/*.bats` — one suite per hook. `tests/helper.bash` has the assertions.
- `scripts/doctor.sh` — audits any repo's `.claude/` setup.
- `docs/` — long-form documentation for humans.
- `demo/toolkit.tape` — VHS script for the README GIF.
- `install.sh` — copy-files alternative to plugin install.

## How to work here

**Positioning.** This repo is the guardrails layer. It deliberately does not
ship commit, code-review, PR-description, or plugin-authoring skills, because
Anthropic ships those first-party. Do not add them back. If a request implies
one, say so and point at the first-party plugin.

**Hooks are the priority.** When adding one:

- Source `hooks/lib/common.sh` and use `deny` / `ask` / `add_context` / `allow`.
  Never hand-roll the decision JSON.
- `set -uo pipefail`, not `set -euo pipefail`.
- Exit 1 does **not** block. Only exit 2 or a `deny` payload does.
- Every hook needs a bats suite with a positive and a negative case.
- Wire it in `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}`.
- `deny` for the unrecoverable, `ask` for the merely destructive.

**Skills.**

- `description` in the third person, naming concrete triggers. It is the text
  Claude matches on.
- Always declare `allowed-tools`.
- Keep `SKILL.md` under ~2,000 words; put detail in `references/`.
- Folder name must equal the frontmatter `name`.
- Write the body addressed to Claude.

**Agents.** `name`, `description`, `tools`, plus `model` (prefer `inherit`),
`color`, and `disallowedTools` on read-only reviewers.

**When adding or removing a component:** update the README table, `docs/`, and
`CHANGELOG.md`. You usually do not need to touch `plugin.json` — `skills/`,
`agents/`, and `output-styles/` are scanned by default.

**Before finishing any change here, run:**

```bash
bats tests/ && shellcheck -S warning -x plugins/guardrails/hooks/*.sh && ./scripts/doctor.sh .
```

**Manifests** (`plugin.json`, `marketplace.json`) must be valid JSON — no
trailing commas, no comments. Validate with `jq .`. Bump `version` in both the
plugin manifest and the marketplace entry when behavior changes.

**Never add a permission that could run destructive commands unattended**
(`rm -rf`, `git push --force`, `gh pr merge`).

## Conventions

- Markdown files use ATX headers (`#`), not Setext.
- Skills and agents address Claude as "you".
- READMEs and top-level docs address humans.
- Agents have their own frontmatter spec — see existing agents for the pattern.
- No emoji in file contents. CI enforces this.
- Skill descriptions are third person ("This skill should be used when..."), which
  is what the description matcher is tuned for and what Anthropic's own
  `plugin-dev` skill prescribes. Skill and agent *bodies* stay second person.
