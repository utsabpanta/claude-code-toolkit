# Slash commands

Slash commands are quick prompt templates you invoke with `/<name> [args]`. They're simpler than skills — one prompt, argument substitution via `$ARGUMENTS`, no multi-step process.

> **Status:** Slash commands are **not deprecated** — they still work and are first-class. But for any non-trivial workflow, [skills](.claude/skills/) are now the recommended primary mechanism. The commands in this repo are kept intentionally light: each is a one-shot shortcut that earns its place by being shorter than typing the equivalent prompt.

See [CONCEPTS.md](CONCEPTS.md#slash-commands-vs-skills) for the command-vs-skill distinction.

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

Pick one:

```bash
# Plugin (recommended) — gets all skills, agents, commands, and styles in one go:
#   inside Claude Code:
#   /plugin marketplace add utsabpanta/claude-code-toolkit
#   /plugin install team-power-pack@claude-code-toolkit

# Just commands, manually:
mkdir -p ~/.claude/commands
cp .claude/commands/*.md ~/.claude/commands/

# Or via the script:
./install.sh --commands
```

> **Note:** Every `.md` file in `~/.claude/commands/` becomes a slash command. Don't drop a `README.md` in there — Claude Code would try to register it as a `/README` command. Keep docs at the top level (like this file) or one directory up.

## Slash command vs. skill — the quick version

- **Slash command** — one prompt, takes `$ARGUMENTS`, returns one result. Use for shortcuts.
- **Skill** — multi-step process (gather data → analyze → produce artifact). Use for workflows. **Default to this for new things.**

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

### Frontmatter fields

| Field | Required | What it does |
|---|---|---|
| `description` | Recommended | Shown in the `/` menu and used by Claude to recognize when the command applies |
| `argument-hint` | Optional | Placeholder shown after `/<name>` in autocomplete |
| `allowed-tools` | Optional | Pre-approve specific tools (space-separated, e.g. `Read Bash Glob`) |
| `model` | Optional | Override the session model for this command |

### Tips

- **Be specific in `argument-hint`.** `<file>` beats `[args]` — users see it in the picker.
- **Cover edge cases inside the prompt.** "If the argument is missing, ask one brief question" is a useful instruction.
- **Don't reinvent skills.** If your command grows numbered steps and "do X then Y," make it a skill.
- **One job per command.** A `/review-and-fix` command implies two things; split it.
