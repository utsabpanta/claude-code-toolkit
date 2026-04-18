# Output styles — swap Claude's personality per task

An output style is a reusable system-prompt preset. Think of it like switching modes:

- `terse` — short answers, no preamble, no bullets unless you ask
- `pair-programmer` — talks through code with you, thinks out loud
- `teacher` — explains *why*, not just *what*, at a level you pick
- `senior-reviewer` — adversarial: "have you considered…?"

You get all the normal tools either way — output styles only change how Claude talks.

Most people have no idea this exists. It's one of the biggest ergonomics wins in the product.

## Included styles

| Style | Best for |
|---|---|
| [`terse`](.claude/output-styles/terse.md) | You know what you want. Skip the explanation. |
| [`pair-programmer`](.claude/output-styles/pair-programmer.md) | Exploring a problem together; want Claude to narrate its thinking |
| [`teacher`](.claude/output-styles/teacher.md) | Learning an unfamiliar codebase, language, or pattern |
| [`senior-reviewer`](.claude/output-styles/senior-reviewer.md) | Stress-testing a design or piece of code before you commit |

## Install

Copy the files into your user-level output styles folder:

```bash
mkdir -p ~/.claude/output-styles
cp .claude/output-styles/*.md ~/.claude/output-styles/
```

Or let the installer do it:

```bash
./install.sh --output-styles
```

## How to switch styles

Two ways:

**1. Interactive** — in Claude Code, run:

```
/config
```

This opens the settings menu. Find "Output Style" and pick from the list (your custom ones appear alongside the built-ins).

**2. In `settings.json`** — edit `~/.claude/settings.json`:

```json
{
  "outputStyle": "terse"
}
```

Setting sticks across sessions. Remove the key (or set it to `"default"`) to go back.

> **Note:** The old `/output-style <name>` slash command was deprecated in a recent Claude Code release. Use `/config` or `settings.json` instead.

## How to write your own

An output style is a plain Markdown file with frontmatter:

```markdown
---
name: my-style
description: One-line description — shown in the /config menu
---

Instructions that get prepended as system prompt.
Address Claude in second person ("you").
```

Save to `~/.claude/output-styles/my-style.md`. It appears in the `/config` menu immediately — no restart needed.

## Style-writing tips

- **Be specific about tone and length.** "Be brief" is vague. "First response ≤ 2 sentences, no headers" is actionable.
- **Say what to cut, not just what to do.** "Don't apologize. Don't restate the question. Don't summarize at the end."
- **One style, one purpose.** Don't make a "do everything" style — that's the default.
- **Don't override tool behavior here.** Output styles shape conversation; they don't (and shouldn't) change what tools do.
