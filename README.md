# Claude Code — Team Power Pack

A curated, opinionated collection of **skills**, **agents**, **slash commands**, **hooks**, **output styles**, and a **custom status line** for [Claude Code](https://claude.com/claude-code) — built to make real software teams dramatically more productive.

The whole thing is packaged as a **plugin**, so you can install it with one command from inside Claude Code.

> **New to Claude Code extensibility?** Start with **[CONCEPTS.md](CONCEPTS.md)** to understand what a skill / agent / hook / output style / plugin actually is.
>
> **Want to see what it looks like in practice?** Check **[EXAMPLES.md](EXAMPLES.md)** for concrete before/after demos.

---

## The 30-second overview

| Feature | In plain English | Who triggers it |
|---|---|---|
| **Skill** | A multi-step workflow invoked with a slash command (`/code-review`, `/commit`, `/standup`). Recommended for new things. | You |
| **Slash command** | A short, argument-taking prompt template (`/tldr file.ts`, `/tradeoff A vs B`). Still works; great for one-shots. | You |
| **Agent** | A specialist sub-Claude with fresh context (code-reviewer, security-auditor, architect) | Claude (or you, by name) |
| **Hook** | A script that runs automatically on events (format-on-save, block-force-push) | Claude Code harness |
| **Output style** | A persistent tone preset (`terse`, `teacher`, `senior-reviewer`) | You, via `/config` |
| **Plugin** | A bundle of any of the above, distributed as a Git repo and installed with `/plugin install` | You |
| **MCP server** | An external process that exposes new tools to Claude (GitHub, Postgres, Sentry, …) | Claude (as tools) |

See [CONCEPTS.md](CONCEPTS.md) for the long version.

---

## Who this is for

- **Engineers** — code review, test generation, debugging, refactoring, PRs, commits, onboarding
- **Product / PMs** — user stories, release notes
- **Engineering managers** — standups, retros, incident response, on-call handoffs
- **Teams** — shared skills checked into your repo so everyone uses the same workflows

Everything here is plain Markdown + a few shell scripts. Drop it in your `~/.claude/`, restart Claude Code, done.

---

## Install — pick one

**As a plugin (recommended).** Inside Claude Code, run:

```
/plugin marketplace add utsabpanta/claude-code-toolkit
/plugin install team-power-pack@claude-code-toolkit
```

Skills, agents, slash commands, and output styles all activate immediately. Hooks stay opt-in (see below).

**As copied files (if you'd rather not use the plugin system):**

```bash
git clone https://github.com/utsabpanta/claude-code-toolkit && cd claude-code-toolkit
./install.sh --all
```

See **[PLUGINS.md](PLUGINS.md)** for plugin install details (and how to publish your own) and **[INSTALL.md](INSTALL.md)** for the script-based options (cherry-pick, project-level, manual).

---

## What's inside

### 🧠 19 skills — multi-step workflows invoked with `/<name>`

| Slash command | For | What it does |
|---|---|---|
| [`/code-review`](.claude/skills/code-review/SKILL.md) | Engineers | Reviews pending changes against a principled rubric |
| [`/pr-description`](.claude/skills/pr-description/SKILL.md) | Engineers | Writes a PR title + body from commits and diff |
| [`/test-gen`](.claude/skills/test-gen/SKILL.md) | Engineers | Tests with edge-case enumeration, not just happy paths |
| [`/debug-help`](.claude/skills/debug-help/SKILL.md) | Engineers | Hypothesis-driven systematic debugging |
| [`/commit`](.claude/skills/commit/SKILL.md) | Engineers | Smart commits — safe staging, honest messages |
| [`/adr`](.claude/skills/adr/SKILL.md) | Engineers, architects | Architecture Decision Records with tradeoffs named |
| [`/explain`](.claude/skills/explain/SKILL.md) | Engineers | Explains code at the user's level, not textbook-generic |
| [`/onboard`](.claude/skills/onboard/SKILL.md) | New team members | Map a new codebase in an hour |
| [`/migration-review`](.claude/skills/migration-review/SKILL.md) | Engineers | Checks a DB migration for lock risk, data loss, rollback safety |
| [`/api-design`](.claude/skills/api-design/SKILL.md) | Engineers | Critiques a new endpoint — contract, errors, pagination, auth |
| [`/refactor-plan`](.claude/skills/refactor-plan/SKILL.md) | Engineers | Breaks a big refactor into small, shippable steps |
| [`/changelog`](.claude/skills/changelog/SKILL.md) | Engineers, PMs | Appends a Keep-a-Changelog entry from a commit range |
| [`/dependency-check`](.claude/skills/dependency-check/SKILL.md) | Engineers | Evaluates a package before you add it — health, risk, alternatives |
| [`/user-story`](.claude/skills/user-story/SKILL.md) | PMs | Well-formed stories with acceptance criteria |
| [`/release-notes`](.claude/skills/release-notes/SKILL.md) | PMs, EMs | Customer-facing release notes from git commits |
| [`/standup`](.claude/skills/standup/SKILL.md) | EMs, engineers | Standup notes from yesterday's git activity |
| [`/retro`](.claude/skills/retro/SKILL.md) | EMs | Facilitates retros that produce action items, not vents |
| [`/incident`](.claude/skills/incident/SKILL.md) | On-call engineers | Live incident flow + postmortem writing |
| [`/oncall-handoff`](.claude/skills/oncall-handoff/SKILL.md) | On-call engineers | Shift-end handoff notes |

👉 See [EXAMPLES.md](EXAMPLES.md#skills) for what each one actually produces.

### ⚡ 6 slash commands — quick one-shot prompts

Invoked with `/<name> [args]`. Lighter than skills — one prompt, argument substitution via `$ARGUMENTS`, no multi-step process. See **[COMMANDS.md](COMMANDS.md)** for the command vs. skill distinction.

| Command | For | What it does |
|---|---|---|
| [`/tldr`](.claude/commands/tldr.md) | Everyone | 3-bullet summary of a file, function, or diff |
| [`/blame-why`](.claude/commands/blame-why.md) | Engineers | Explain why a line exists — git blame + commit context |
| [`/5-whys`](.claude/commands/5-whys.md) | EMs, engineers | Root-cause analysis walk-through |
| [`/tradeoff`](.claude/commands/tradeoff.md) | Engineers, architects | Structured tradeoff matrix between options |
| [`/what-changed`](.claude/commands/what-changed.md) | Everyone | Summarize git changes since a ref or date |
| [`/rubber-duck`](.claude/commands/rubber-duck.md) | Engineers | Help you think — without solving for you |

### 🤖 12 agents — specialists Claude can delegate to

Agents have fresh context (no bias from the main conversation) and often restricted tools (a reviewer that can read but not write). Claude picks them automatically based on their `description`, or you can name them (`"use the security-auditor agent"`).

| Agent | Use when |
|---|---|
| [`code-reviewer`](.claude/agents/code-reviewer.md) | You want a rigorous, independent second opinion on a diff |
| [`test-engineer`](.claude/agents/test-engineer.md) | You want tests with real coverage discipline |
| [`security-auditor`](.claude/agents/security-auditor.md) | Shipping code that touches auth, input, secrets, or network |
| [`architect`](.claude/agents/architect.md) | Designing a non-trivial change and want a plan first |
| [`doc-writer`](.claude/agents/doc-writer.md) | You need docs humans will actually read |
| [`incident-commander`](.claude/agents/incident-commander.md) | You're in a live incident and need someone driving the loop |
| [`onboarding-buddy`](.claude/agents/onboarding-buddy.md) | A new team member needs to get productive in a codebase |
| [`performance-analyst`](.claude/agents/performance-analyst.md) | Something is slow — you want measurement, not speculation |
| [`sql-reviewer`](.claude/agents/sql-reviewer.md) | Query plans, N+1s, missing indexes, and NULL-handling bugs |
| [`a11y-auditor`](.claude/agents/a11y-auditor.md) | Reviewing frontend changes for real accessibility issues |
| [`dockerfile-reviewer`](.claude/agents/dockerfile-reviewer.md) | Sanity-check a Dockerfile for security, size, and layer caching |
| [`api-contract-guardian`](.claude/agents/api-contract-guardian.md) | Catch breaking API changes in a diff before they ship |

👉 See [EXAMPLES.md](EXAMPLES.md#agents) for realistic exchanges.

### 🪝 8 hooks — automation around Claude

Run shell commands on Claude Code events. **Most people don't know this feature exists**; it's one of the most powerful things in the product. See **[HOOKS.md](HOOKS.md)** for the complete guide.

| Hook | Event | What it does |
|---|---|---|
| [`format-on-edit.sh`](.claude/hooks/format-on-edit.sh) | PostToolUse | Auto-formats files Claude edits (prettier, black, gofmt, rustfmt) |
| [`block-env-writes.sh`](.claude/hooks/block-env-writes.sh) | PreToolUse | Blocks writes to `.env`, private keys, credentials |
| [`block-force-push.sh`](.claude/hooks/block-force-push.sh) | PreToolUse | Refuses `git push --force` without explicit opt-in |
| [`session-summary.sh`](.claude/hooks/session-summary.sh) | Stop | Logs each session to `~/.claude/session.log` |
| [`notify-on-idle.sh`](.claude/hooks/notify-on-idle.sh) | Notification | Desktop notification when Claude is waiting on you |
| [`auto-gitignore.sh`](.claude/hooks/auto-gitignore.sh) | PostToolUse | Warns when Claude writes a sensitive-looking path not in `.gitignore` |
| [`test-on-edit.sh`](.claude/hooks/test-on-edit.sh) | PostToolUse | Runs the nearest test file when Claude edits source — tight feedback loop |
| [`pre-commit-lint.sh`](.claude/hooks/pre-commit-lint.sh) | PreToolUse | Lints staged files before Claude commits; blocks on errors |

### 🎭 4 output styles — swap Claude's voice per task

Reusable system-prompt presets. Switch via `/config` or add `"outputStyle": "<name>"` to `settings.json`. See **[OUTPUT-STYLES.md](OUTPUT-STYLES.md)**.

| Style | Best for |
|---|---|
| [`terse`](.claude/output-styles/terse.md) | You know what you want. No preamble. |
| [`pair-programmer`](.claude/output-styles/pair-programmer.md) | Exploring a problem together, thinking out loud |
| [`teacher`](.claude/output-styles/teacher.md) | Learning an unfamiliar codebase or pattern |
| [`senior-reviewer`](.claude/output-styles/senior-reviewer.md) | Adversarial mode — surfaces edge cases you missed |

### 📊 Custom status line

A git-aware status line with model, cwd, branch, dirty state, ahead/behind, and session cost. See **[.claude/statusline/README.md](.claude/statusline/README.md)**.

```
sonnet-4-6 | my-app | main* ↑2 | $0.42
```

### 🔌 MCP server guide

Curated list of genuinely useful MCP servers (GitHub, Postgres, Sentry, Linear, Puppeteer...) with setup snippets and security notes. See **[MCP.md](MCP.md)**.

### ⚙️ Safe default `settings.json`

A vetted starting point — permission allowlist (read-only ops) + denylist (destructive ops). See [`settings.example.json`](settings.example.json) and [`settings.example.README.md`](settings.example.README.md).

---

## Quickstart (5 minutes)

1. **Install (plugin, recommended):**
   ```
   /plugin marketplace add utsabpanta/claude-code-toolkit
   /plugin install team-power-pack@claude-code-toolkit
   ```

   Or, if you'd rather copy files manually:
   ```bash
   git clone https://github.com/utsabpanta/claude-code-toolkit && cd claude-code-toolkit
   ./install.sh --skills --commands --agents --output-styles
   ```

2. **Try a slash command:**
   ```
   /tldr src/some-file.ts
   ```
   Claude returns a 3-bullet summary.

3. **Try a skill:**
   ```
   /standup
   ```
   Claude pulls your git activity and drafts a standup note.

4. **Try an output style:**
   - Run `/config`
   - Find "Output Style" in the settings menu
   - Pick `terse`
   - Every response is now short and direct.

5. **Try an agent:**
   ```
   Use the code-reviewer agent to look at my staged changes.
   ```
   Claude spawns the agent with a fresh context for an independent review.

6. **Optional: install a hook** (not bundled in the plugin — hooks need machine-specific paths):
   ```bash
   ./install.sh --hooks
   ```
   Then add this to `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "matcher": "Edit|Write",
           "hooks": [
             { "type": "command", "command": "/Users/you/.claude/hooks/format-on-edit.sh" }
           ]
         }
       ]
     }
   }
   ```
   Now your code is auto-formatted whenever Claude edits a file.

See [EXAMPLES.md](EXAMPLES.md) for longer walkthroughs.

---

## Documentation map

| Doc | What's in it |
|---|---|
| [README.md](README.md) | You're here — index of everything |
| [CONCEPTS.md](CONCEPTS.md) | What a skill / agent / hook / output style / plugin actually is, and when to use which |
| [PLUGINS.md](PLUGINS.md) | How to install this repo as a plugin and how to publish your own |
| [EXAMPLES.md](EXAMPLES.md) | Concrete before/after demos for each feature |
| [INSTALL.md](INSTALL.md) | Script-based install options + troubleshooting |
| [COMMANDS.md](COMMANDS.md) | Slash commands — when to use them vs. skills, how to write your own |
| [HOOKS.md](HOOKS.md) | Deep dive on hooks, all event types, stdin formats |
| [OUTPUT-STYLES.md](OUTPUT-STYLES.md) | How output styles work, how to switch, how to write your own |
| [MCP.md](MCP.md) | Curated MCP server list with setup snippets |
| [CLAUDE.md](CLAUDE.md) | Guidance Claude uses when modifying this repo itself |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to add a skill, agent, hook, or output style |
| [settings.example.json](settings.example.json) | Template settings file |
| [settings.example.README.md](settings.example.README.md) | What's in the settings example and why |

---

## Design principles

Everything in this repo follows these rules:

1. **Spell out *how*, not just *what*.** A good skill tells Claude the *process* — what to check first, what order to work in — not just the goal.
2. **One skill, one job.** `/code-review` reviews. It doesn't also open PRs.
3. **Produce an artifact.** Every skill ends with something concrete: a review, a description, a file, a checklist.
4. **Be opinionated.** These files reflect choices about what "good" looks like. Fork and change them — that's the point.
5. **Fail safe.** Defaults that won't ruin your day. Explicit opt-in for anything destructive.

---

## Contributing

PRs welcome. If you've got a skill or agent that's served your team well, share it.

- Each skill is one folder with one `SKILL.md` — no dependencies between skills.
- Match the tone of existing skills (direct, second-person to Claude).
- Don't add examples that reference internal systems or specific people.
- Add an entry to EXAMPLES.md if your addition is non-obvious.

## License

MIT — see [LICENSE.md](LICENSE.md).
