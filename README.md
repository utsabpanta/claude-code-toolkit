# Claude Code Toolkit

**Safety hooks for Claude Code that actually block — plus the specialist review agents worth delegating to.**

[![CI](https://github.com/utsabpanta/claude-code-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/utsabpanta/claude-code-toolkit/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/hook%20tests-59%20passing-brightgreen)](tests/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-2.1%2B-8A63D2)](https://claude.com/claude-code)

```
/plugin marketplace add utsabpanta/claude-code-toolkit
/plugin install guardrails@claude-code-toolkit
```

That is the whole setup. No `settings.json` editing, no absolute paths to hand-write.

<!--
  DEMO GIF: run `vhs demo/toolkit.tape` (see demo/README.md), commit
  demo/toolkit.gif, then delete the code block below and uncomment this:

<p align="center">
  <img src="demo/toolkit.gif" alt="Claude Code refusing a write to .env and a force push" width="800">
</p>
-->

```console
$ echo '{"tool_name":"Write","tool_input":{"file_path":"/app/.env"}}' | guard-secrets.sh
{"permissionDecision":"deny","permissionDecisionReason":"Refused to modify the env
 file /app/.env. Environment files hold live credentials and are not safe for an
 agent to rewrite."}

$ echo '{"tool_input":{"command":"git push origin +main:main"}}' | guard-force-push.sh
{"permissionDecision":"deny","permissionDecisionReason":"Refused to force-push.
 This rewrites remote history and can destroy commits your teammates already
 pulled."}

$ bats tests/
59 tests, 0 failures
```

---

## Why this exists

Most published Claude Code hooks do not work.

A hook blocks a tool call by exiting `2`, or by emitting a `deny` decision on stdout. Exiting `1` prints your refusal message and **lets the action through**. It looks identical in the terminal. Nothing warns you.

This repository shipped that exact bug until v1.0.0: two hooks written to block secret writes and force pushes both used `exit 1`. They had been no-ops the entire time.

So every hook here is covered by a test that asserts the *decision*, not the exit code — and `scripts/doctor.sh` will find the same bug in your setup.

```bash
$ ./scripts/doctor.sh .

== Hook scripts ==
ERROR   .claude/hooks/block-writes.sh looks like a blocking hook but uses 'exit 1'.
        Exit 1 does NOT block a tool call: use exit 2, or emit
        hookSpecificOutput.permissionDecision="deny".

== settings.json ==
ERROR   .claude/settings.json contains an 'mcpServers' key. settings.json does not
        configure MCP servers: use .mcp.json at the project root.
```

## What you get

### `guardrails` — the flagship

13 hooks, wired on install, every one tested.

| Hook | Fires on | Behavior |
|---|---|---|
| `guard-secrets` | Edit, Write | **Denies** writes to `.env`, private keys, service-account JSON, `secrets/` |
| `guard-force-push` | Bash | **Denies** force pushes — `-f`, `--force`, `--force-with-lease`, `+refspec`. One-shot override |
| `guard-destructive` | Bash | **Denies** `rm -rf /`, `mkfs`, `curl \| sh`. **Asks** before `git reset --hard`, `DROP TABLE`, `DELETE` without `WHERE` |
| `guard-prod-config` | Edit, Write | **Asks** before production infra and CI workflow edits. **Denies** hand-edits to Terraform state |
| `pre-commit-lint` | Bash | Lints staged files before `git commit`, denies on failure |
| `format-on-edit` | after edits | Runs prettier, ruff, gofmt, rustfmt, or rubocop |
| `auto-gitignore` | after edits | Flags a sensitive new file git is not ignoring |
| `guard-dependency-add` | after edits | Prompts a supply-chain check when a manifest changes |
| `audit-log` | session, tools | Local JSONL trail: what changed, where, when |
| `context-brief` | session start | Injects branch, divergence, and open-PR state |

Plus `session-summary`, `notify-on-idle`, and `test-on-edit` (shipped, deliberately unwired).

Three skills come with it: **`/harden-setup`** audits any repo's Claude Code config, **`/hook-authoring`** writes a correct hook with its test, **`/permission-policy`** designs an allowlist from your repo's actual scripts.

And three permission profiles — `strict`, `balanced`, `solo` — in [`policies/`](plugins/guardrails/policies).

### `team-power-pack` — specialists

12 agents, each running in its own context window so they see your code without seeing your conclusions.

`security-auditor` · `sql-reviewer` · `migration-review`'s counterpart `api-contract-guardian` · `a11y-auditor` · `dockerfile-reviewer` · `performance-analyst` · `architect` · `code-reviewer` · `test-engineer` · `doc-writer` · `incident-commander` · `onboarding-buddy`

17 skills, including `/migration-review` (lock risk, backfill safety, the three-deploy `NOT NULL` sequence), `/api-design`, `/incident`, `/release-notes`, `/dependency-check`, `/tradeoff`, `/5-whys`.

4 output styles: `terse`, `teacher`, `senior-reviewer`, `pair-programmer`. And a git-aware status line.

## What this deliberately does not do

Anthropic ships first-party plugins for commits, code review, and PR review. They are good, they are maintained by the people who build Claude Code, and duplicating them would waste your context window:

| For this | Use |
|---|---|
| Commits | `commit-commands` (first-party) |
| PR review | `pr-review-toolkit`, `code-review` (first-party) |
| Building plugins | `plugin-dev` (first-party) |
| Creating hooks from a session | `hookify` (first-party) |

Earlier versions of this repo shipped worse copies of all four. They were deleted in v1.0.0.

## Install

```
/plugin marketplace add utsabpanta/claude-code-toolkit
/plugin install guardrails@claude-code-toolkit
/plugin install team-power-pack@claude-code-toolkit
```

For a whole team, commit this to `.claude/settings.json` and everyone who opens the repo is covered:

```json
{
  "extraKnownMarketplaces": {
    "claude-code-toolkit": {
      "source": { "source": "github", "repo": "utsabpanta/claude-code-toolkit" }
    }
  },
  "enabledPlugins": ["guardrails@claude-code-toolkit"]
}
```

Other paths — script install, cherry-picking single files, uninstall — are in [docs/install.md](docs/install.md).

## Verify it works

Do not take the claim on faith. In a scratch repo, ask Claude to write to `.env`:

```
I can't write to .env - the guardrails hook refuses modifications to
environment files. I've added the key to .env.example instead.
```

The word that matters is *refuses*. Then audit your own setup:

```bash
./scripts/doctor.sh .
```

## The 30-second concept map

| Feature | In plain English | Who triggers it |
|---|---|---|
| **Skill** | A folder with a procedure, plus `references/` loaded only when needed | Claude, by matching your request to its `description` — or you, via `/name` |
| **Agent** | A specialist with its own context window that reports back | Claude, or you by name |
| **Hook** | A script the harness runs on an event. The only thing that can *stop* Claude | The harness, automatically |
| **Output style** | A tone preset that replaces part of the system prompt | You, via `/output-style` |
| **Plugin** | A bundle of the above, installed from a marketplace | You |
| **MCP server** | An external process exposing new tools | Claude, as tools |

Slash commands still work, but they have merged into skills. Write a skill with `disable-model-invocation: true` instead. Long version: [docs/concepts.md](docs/concepts.md).

## Docs

| Doc | What is in it |
|---|---|
| [concepts.md](docs/concepts.md) | Skill vs. agent vs. hook, and when to reach for each |
| [examples.md](docs/examples.md) | What each piece actually outputs |
| [hooks.md](docs/hooks.md) | The exit-code contract, all 32 events, the hook catalog |
| [install.md](docs/install.md) | Every install path, plus troubleshooting |
| [plugins.md](docs/plugins.md) | Publishing your own plugin and marketplace |
| [settings.md](docs/settings.md) | Permissions, precedence, and the policy profiles |
| [mcp.md](docs/mcp.md) | Where MCP config actually lives, and the CLI |
| [commands.md](docs/commands.md) | The legacy command form and migrating off it |
| [output-styles.md](docs/output-styles.md) | Writing your own style |

## Design principles

1. **A guardrail that does not block is worse than none** — it produces false confidence. Hence the tests.
2. **Fail open.** No `jq`? The hook skips itself. A guardrail that breaks your session gets uninstalled, and then it protects nothing.
3. **`ask` beats `deny` for anything legitimate.** Block `git reset --hard` outright and the whole thing gets turned off by Friday.
4. **Do not duplicate first-party plugins.** Context is finite.
5. **Everything is a plain file.** Read it before you install it.

## Contributing

New hooks need a bats suite. CI runs shellcheck, the tests, frontmatter validation, and `doctor.sh` on every push. See [CONTRIBUTING.md](CONTRIBUTING.md).

```bash
bats tests/
shellcheck -S warning -x plugins/guardrails/hooks/*.sh
./scripts/doctor.sh .
```

## License

MIT. See [LICENSE](LICENSE).
