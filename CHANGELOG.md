# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-08-29

Repositioned from a general skills collection to a guardrails toolkit, and fixed
two hooks that never worked.

### Security

- **`guard-secrets` and `guard-force-push` now actually block.** Both previously
  used `exit 1`, which does not block a tool call: they printed a refusal and the
  write or push proceeded anyway. They now emit
  `hookSpecificOutput.permissionDecision`, and each has a test that fails if that
  regresses.
- `guard-force-push` now catches `--force-with-lease`, `--force-if-includes`, the
  `+refspec` spelling, and a global flag before the subcommand (`git -C path push
  --force`). Previously only `-f` and `--force` were matched.

### Added

- `hooks/hooks.json`, so installing the plugin wires every hook through
  `${CLAUDE_PLUGIN_ROOT}` with no `settings.json` editing.
- `hooks/lib/common.sh` with `deny`, `ask`, `add_context`, `warn`, and `allow`,
  so no hook hand-rolls the decision JSON.
- Five hooks: `guard-destructive`, `guard-prod-config`, `guard-dependency-add`,
  `audit-log`, `context-brief`.
- 59 bats tests covering every hook and the shared library.
- `scripts/doctor.sh`, which audits any repository's Claude Code setup and finds
  the exit-1 bug class, `mcpServers` in the wrong file, overly broad permission
  rules, and BSD-only date arithmetic.
- Permission policy profiles: `strict`, `balanced`, `solo`.
- Three skills: `/harden-setup`, `/hook-authoring`, `/permission-policy`.
- A complete, correct reference for all 32 hook events.
- Issue and PR templates, `SECURITY.md`, `.gitignore`, and a VHS tape for the
  README demo.

### Changed

- Split into two plugins under one marketplace: `guardrails` and
  `team-power-pack`. The safety hooks can now be installed without the skills.
- All 20 skills gained `allowed-tools`; previously none had it, including ones
  that ran destructive commands.
- Skill descriptions rewritten in the third person the description matcher
  expects.
- The six slash commands became skills with `disable-model-invocation: true`.
  `commands/` is the legacy form.
- Agent frontmatter modernized: `color`, `model: inherit`, `disallowedTools` on
  the ten read-only reviewers, and `maxTurns`.
- `changelog` and `release-notes` merged; they were roughly 70% the same
  procedure with contradictory stated audiences.
- CI now runs bats, `doctor.sh`, a link check, an emoji check, and frontmatter
  validation, and verifies every wired hook exists.

### Fixed

- The `standup` skill used `date -v-1d`, which is BSD-only and failed on Linux
  and in CI.
- `docs/mcp.md` said MCP servers are configured in `settings.json`. They are not,
  and the key is ignored silently. It also recommended
  `@modelcontextprotocol/server-fetch`, which does not exist on npm, and several
  archived reference servers.
- `docs/hooks.md` said any non-zero exit blocks and the reason comes from stdout.
  Only exit 2 blocks, the reason comes from stderr, and blocking is not
  `PreToolUse`-only. It listed 8 of 32 events.
- `docs/concepts.md` described skills as user-invoked, which inverts their
  defining property, and gave the agent at-mention as `@code-reviewer` rather
  than `@agent-code-reviewer`.
- `/plugin install <git-url>` documented in two places is not a valid form.
- Plugin command namespacing documented as collision-triggered; it is
  unconditional.
- The claim that `/output-style` was deprecated. It was not.
- `settings.example.json` pinned the superseded `claude-sonnet-4-6`. The key is
  now omitted.
- Emoji removed from shipped files, per the repository's own contributing rule.

### Removed

- `commit`, `code-review`, and `pr-description` skills. Anthropic ships
  `commit-commands`, `code-review`, and `pr-review-toolkit` first-party.
- `explain`, `user-story`, `oncall-handoff`, and `onboard` skills, which restated
  default model behavior.
- `docs/mcp.md`'s curated server list. Such lists age badly; the doc now points
  at the registry and vendor-run servers instead.

## [0.1.0] - 2026-04-18

Initial release: 19 skills, 12 agents, 6 slash commands, 8 hooks, 4 output
styles, a status line, and a single-plugin manifest.
