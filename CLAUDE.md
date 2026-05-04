# Guidance for Claude

This repo is a collection of skills, agents, slash commands, hooks, output styles, and a status line, packaged as a Claude Code plugin and meant to be shared with other teams.

## What this repo is

- `.claude/skills/*/SKILL.md` — multi-step skills (recommended for new workflows)
- `.claude/commands/*.md` — single-prompt slash commands (still supported; use for one-shots)
- `.claude/agents/*.md` — specialized sub-agents
- `.claude/hooks/*.sh` — shell scripts wired in via `settings.json` (opt-in, not auto-installed)
- `.claude/output-styles/*.md` — tone presets activated via `/config`
- `.claude/statusline/statusline.sh` — git-aware status line script
- `.claude-plugin/plugin.json` + `marketplace.json` — packages this repo as a plugin (`/plugin install`)
- `settings.example.json` — a template settings file
- `install.sh` — copy-files alternative to plugin install
- `README.md`, `PLUGINS.md`, `INSTALL.md`, `CONCEPTS.md`, `COMMANDS.md`, `HOOKS.md`, `OUTPUT-STYLES.md`, `MCP.md` — docs for humans

## How to work here

When the user asks you to add or modify a skill or agent:

- **Default to a skill.** Slash commands are still supported, but skills are the primary mechanism for any non-trivial workflow.
- **Keep each skill focused on one job.** If a request implies two jobs, suggest splitting into two skills.
- **Write the skill in second person ("you"), addressed to Claude.** That's the convention the harness expects.
- **Frontmatter matters.** For skills: `name:` must match the folder name; `description:` is what Claude uses to decide when to activate the skill — write it as a trigger sentence, not a marketing blurb. For agents: `name`, `description`, `tools` (comma-separated), and `model` (`sonnet` or `opus`).
- **Don't add examples that reference secrets, internal URLs, or specific people.** This is public.
- **Prefer editing an existing skill over creating a new one** if the request is a refinement.

When the user adds or removes a component (skill / agent / command / output style):

- **Update the README table** for the relevant section.
- **You usually don't need to touch `plugin.json`** — `skills`, `agents`, `commands`, and `outputStyles` are pointed at directories, so new files are picked up automatically.
- If you change the directory layout, update `plugin.json` paths.

When modifying `settings.example.json`:

- Keep it minimal and commented. This file is read by humans deciding what to merge, not by a parser — comments are fine *as long as they live in an adjacent `.md` doc*, since `settings.json` itself must be valid JSON. If you want inline annotations, use a separate README.
- Never add a permission that could run destructive commands unattended (e.g. `rm -rf`, `git push --force`, `gh pr merge`).

When modifying plugin manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`):

- Bump `version` in `plugin.json` when behavior changes.
- Keep `marketplace.json` in sync if you rename or relocate the plugin.
- Both must be valid JSON — no trailing commas, no comments. Validate with `jq .`.

## Conventions

- Markdown files use ATX headers (`#`), not Setext.
- Skills and agents address Claude as "you".
- READMEs and top-level docs address humans.
- Agents have their own frontmatter spec — see existing agents for the pattern.
- No emoji in file contents unless the user explicitly asked for them.
