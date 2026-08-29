# Slash commands (legacy)

Slash commands have merged into skills. A file at `.claude/commands/deploy.md`
and a skill at `.claude/skills/deploy/SKILL.md` both produce `/deploy` and behave
identically. The `commands/` form still works, but it is the older shape and
gains nothing.

**Write a skill instead.** This repository shipped six slash commands through
v0.1.0; all six are now skills.

## Migrating a command to a skill

Move the file into a folder named for the command, rename it `SKILL.md`, and add
three frontmatter fields:

```bash
mkdir -p .claude/skills/tldr
git mv .claude/commands/tldr.md .claude/skills/tldr/SKILL.md
```

```yaml
---
name: tldr                      # must match the folder name
description: This skill should be used when the user types /tldr, or asks for a
  three-bullet summary of a file, a function, or a diff.
argument-hint: '[file path, git ref, or "staged"]'
disable-model-invocation: true  # keeps it slash-only, like a command
allowed-tools: Bash(git:*), Read, Grep, Glob
---
```

`disable-model-invocation: true` is what preserves the old behavior: the skill
runs only when you type `/tldr`, never because Claude decided it was relevant.
Drop that line and Claude will also invoke it on its own when your request
matches the `description` — which is usually what you want, and is the reason to
migrate at all.

`allowed-tools` is worth adding while you are there. Three of this repo's six
commands ran `git` and declared nothing, so every use produced a permission
prompt.

## Frontmatter

Skills and the legacy command form accept the same fields:

| Field | Purpose |
|---|---|
| `name` | Required for skills. Must match the folder name |
| `description` | Required. What Claude matches against to decide relevance |
| `argument-hint` | Shown in the `/` menu as a usage hint |
| `allowed-tools` | Restricts which tools this skill may use |
| `model` | `sonnet`, `opus`, `haiku`, `fable`, or a full model id |
| `disable-model-invocation` | `true` makes it slash-only |

## Argument and interpolation syntax

Unchanged by the migration:

- `$ARGUMENTS` — everything the user typed after the command name.
- `$1`, `$2`, … — positional arguments.
- `` !`command` `` — runs a shell command and substitutes the output before
  Claude sees the prompt. Requires a matching `allowed-tools: Bash(...)` entry.
- `@path/to/file` — inlines a file's contents.

Subdirectories namespace the command: `.claude/skills/frontend/build/SKILL.md`
becomes `/frontend:build`. Skills from a plugin are namespaced
`/plugin-name:skill-name` **always**, not only when a name collides.

## The commands in this repository

All six migrated, and live in `team-power-pack`:

| Command | Now at |
|---|---|
| `/tldr` | [`skills/tldr`](../plugins/team-power-pack/skills/tldr/SKILL.md) |
| `/blame-why` | [`skills/blame-why`](../plugins/team-power-pack/skills/blame-why/SKILL.md) |
| `/5-whys` | [`skills/5-whys`](../plugins/team-power-pack/skills/5-whys/SKILL.md) |
| `/tradeoff` | [`skills/tradeoff`](../plugins/team-power-pack/skills/tradeoff/SKILL.md) |
| `/what-changed` | [`skills/what-changed`](../plugins/team-power-pack/skills/what-changed/SKILL.md) |
| `/rubber-duck` | [`skills/rubber-duck`](../plugins/team-power-pack/skills/rubber-duck/SKILL.md) |

## Related

- [concepts.md](concepts.md) — skill vs. agent vs. hook
- Anthropic's `plugin-dev` plugin ships a `skill-development` skill covering
  authoring in depth
