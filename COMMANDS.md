# Slash commands

Commands are quick prompt templates you invoke with `/<name> [args]`. They're simpler than skills — one prompt, argument substitution via `$ARGUMENTS`, no multi-step process.

See [CONCEPTS.md](CONCEPTS.md#commands-vs-skills) for the command vs. skill distinction.

## Included commands

| Command | For | What it does |
|---|---|---|
| [`/tldr`](.claude/commands/tldr.md) | Everyone | 3-bullet summary of a file, function, or diff |
| [`/blame-why`](.claude/commands/blame-why.md) | Engineers | Explain why a line exists — git blame + commit context |
| [`/5-whys`](.claude/commands/5-whys.md) | EMs, engineers | Root-cause analysis walk-through |
| [`/tradeoff`](.claude/commands/tradeoff.md) | Engineers, architects | Structured tradeoff matrix between options |
| [`/what-changed`](.claude/commands/what-changed.md) | Everyone | Summarize git changes since a ref or date |
| [`/rubber-duck`](.claude/commands/rubber-duck.md) | Engineers | Help the user think — without solving for them |

## Usage

```
/tldr src/auth/session.ts
/blame-why src/billing/invoice.ts:142
/5-whys the deploy pipeline took 40 min when it usually takes 8
/tradeoff Postgres vs DynamoDB for the reports service
/what-changed main
/rubber-duck
```

## Install

Copy into your user-level commands folder:

```bash
mkdir -p ~/.claude/commands
cp .claude/commands/*.md ~/.claude/commands/
```

Or let the installer do it:

```bash
./install.sh --commands
```

> **Note:** Every `.md` file in `~/.claude/commands/` becomes a slash command. Don't drop a `README.md` in there — Claude Code would try to register it as a `/README` command. Keep docs at the top level (like this file) or one directory up.

## Command vs. skill — the quick version

- **Command** — one prompt, takes `$ARGUMENTS`, returns one result. Use for shortcuts.
- **Skill** — multi-step process (gather data → analyze → produce artifact). Use for workflows.

Both are invoked with `/<name>`. If you're torn, start with a command — promote to a skill if the prompt grows a process.

## Writing your own

```markdown
---
description: One-line summary for the picker
argument-hint: [what args you expect]
---

The prompt template. Reference user input with $ARGUMENTS.
```

Save to `~/.claude/commands/my-command.md`. It appears in the `/` menu immediately.
