# Guidance for Claude

This repo is a collection of skills, agents, and settings meant to be shared with other teams.

## What this repo is

- `.claude/skills/*/SKILL.md` — slash commands (skills)
- `.claude/agents/*.md` — specialized sub-agents
- `settings.example.json` — a template settings file
- `README.md`, `INSTALL.md` — docs for humans

## How to work here

When the user asks you to add or modify a skill or agent:

- **Keep each skill focused on one job.** If a request implies two jobs, suggest splitting into two skills.
- **Write the skill in second person ("you"), addressed to Claude.** That's the convention the harness expects.
- **Frontmatter matters.** `name:` must match the folder name. `description:` is what Claude uses to decide when to activate the skill — write it as a trigger sentence, not a marketing blurb.
- **Don't add examples that reference secrets, internal URLs, or specific people.** This is public.
- **Prefer editing an existing skill over creating a new one** if the request is a refinement.

When modifying `settings.example.json`:

- Keep it minimal and commented. This file is read by humans deciding what to merge, not by a parser — comments are fine *as long as they live in an adjacent `.md` doc*, since `settings.json` itself must be valid JSON. If you want inline annotations, use a separate README.
- Never add a permission that could run destructive commands unattended (e.g. `rm -rf`, `git push --force`, `gh pr merge`).

## Conventions

- Markdown files use ATX headers (`#`), not Setext.
- Skills address Claude as "you".
- READMEs address humans.
- Agents have their own frontmatter spec — see existing agents for the pattern.
