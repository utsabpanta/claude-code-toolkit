# Contributing

Thanks for considering a contribution. This repo is a curated toolkit — the bar is "would another team want to adopt this as-is?" Not every useful idea belongs here; the best additions are focused, opinionated, and self-contained.

## Before you open a PR

1. **Read an existing skill or agent** in the same category. Match its tone, structure, and level of detail.
2. **Check if your idea overlaps with something that already exists.** A refinement of an existing file is almost always better than a new one.
3. **Keep the scope tight.** One skill, one job. If your idea has two verbs in it ("review and apply"), it's two skills.

## Adding a skill

A skill is a multi-step workflow Claude executes when you type `/<name>`.

- Create `.claude/skills/<name>/SKILL.md`.
- Frontmatter is mandatory. `name:` **must** match the folder name. `description:` is what Claude uses to decide when to trigger — write it as a trigger sentence, not a marketing blurb.
- Write in second person ("you"), addressed to Claude. That's the convention.
- Structure: short preamble → numbered steps → output format → rules/calibration.
- End with an **artifact**. Every skill should produce something concrete (a review, a file, a checklist).
- Don't reference internal systems, specific people, or secrets.

## Adding an agent

An agent is a specialist Claude can delegate to, with its own fresh context.

- Create `.claude/agents/<name>.md`.
- Frontmatter: `name`, `description` (this is what Claude uses to auto-select the agent — make it a clear trigger sentence), `tools` (comma-separated), `model` (`sonnet` or `opus`).
- Agents should have a narrow mandate. "Reviews code" is too broad; "independent second opinion on a diff" is right.
- Restrict `tools:` to the minimum the agent needs. A reviewer doesn't need `Write`.

## Adding a hook

Hooks are shell scripts the Claude Code harness runs on events.

- Put shell hooks in `.claude/hooks/<name>.sh` and `chmod +x` them.
- Start with a header comment explaining: what event it hooks, what it does, and how to wire it up in `settings.json`.
- **Safe by default.** Hooks should fail open (exit 0) rather than block work unless the whole point of the hook is to block (e.g. `block-env-writes.sh`). When blocking, exit 2 and print a clear message to stderr.
- No network calls without opt-in.
- No hook that modifies user files without an explicit setting to enable it.

## Adding a command

A command is a short, argument-taking prompt shortcut — one-shot, not multi-step.

- Put it in `.claude/commands/<name>.md`.
- If your idea is multi-step, make it a skill instead.

## Adding an output style

- `.claude/output-styles/<name>.md`.
- Frontmatter: `name`, `description`.
- Keep it short — an output style is a tone preset, not a full skill.

## Style and conventions

- Markdown: ATX headers (`#`), not Setext.
- Skills and agents address Claude as "you".
- READMEs address humans.
- No emoji in file contents unless the user explicitly asked for them.
- Don't commit files containing secrets, internal URLs, or company-specific content.

## Testing your change

Before opening a PR:

- [ ] Run `./install.sh` from a clean clone and verify your skill/agent/hook installs.
- [ ] Invoke it (`/<your-skill>`) and confirm the output matches what the SKILL.md promises.
- [ ] If it's a hook, test both the success path and the failure path.
- [ ] Run the CI checks locally if you can (`shellcheck .claude/hooks/*.sh`).

## PR checklist

- [ ] New file(s) match the existing style and structure.
- [ ] Frontmatter is correct (name matches folder, description is a trigger sentence).
- [ ] No secrets, internal URLs, or company-specific content.
- [ ] Added an entry to the relevant table in `README.md`.
- [ ] If non-obvious: added a before/after example to `EXAMPLES.md`.
- [ ] CI passes.

## What won't be merged

- Skills that duplicate existing ones without meaningfully improving them.
- Skills with vague descriptions ("helps with code").
- Permissions in `settings.example.json` that could run destructive commands unattended.
- Hooks that phone home or collect telemetry.
- Additions that reference proprietary tooling only a single company uses.

Everything here is MIT-licensed. By contributing, you agree your contribution is as well.
