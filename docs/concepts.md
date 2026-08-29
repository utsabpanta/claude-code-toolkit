# What the hell is a skill? (and an agent, a hook, an output style, a plugin…)

Claude Code has several customization surfaces that do different things. Most people discover them piecemeal and confuse them. Here is the clean mental model.

## The 30-second version

| Feature | What it is | Who triggers it | When to reach for it |
|---|---|---|---|
| **Skill** | A folder with a `SKILL.md`: a multi-step procedure plus optional `references/` and `scripts/` | **Claude**, by matching your request against the skill's `description` — and you, via `/<name>` | You want a workflow Claude follows every time, whether or not you remember to ask for it. **Recommended for new things.** |
| **Slash command** | Legacy form of a skill: a single `.md` prompt template in `commands/` | **You** | Nothing new. Slash commands have merged into skills; write a skill with `disable-model-invocation: true` instead |
| **Agent** | A specialized sub-Claude with its own system prompt and tool access | **Claude** (usually) | You want a focused second opinion, or to protect your main context window |
| **Hook** | A shell command triggered by a Claude Code event | **Claude Code harness** | You want automation *around* Claude — format on save, block dangerous commands, notifications |
| **Output style** | A persistent tone and behavior preset that replaces part of the system prompt | **You**, via `/output-style` or `/config` | You want to change how Claude *talks* for a while |
| **MCP server** | An external process that exposes new tools to Claude | **Claude** (as tools) | You want Claude to access a system it can't reach today (GitHub, a DB, a browser) |
| **Plugin** | A bundle of any of the above, distributed as a Git repo, installed with `/plugin install` | **You** | You want to share a curated collection across teams or machines |

---

## Slash commands — "I want a one-shot shortcut"

A slash command is a **prompt template** you invoke with `/<name> [args]`. It's the lightest-weight customization in Claude Code.

> **Heads-up on terminology.** Both "slash commands" (the file-based prompt templates in `.claude/commands/`) and "skills" appear in the `/` menu. Internally, skills *also* get a slash command, but they're a richer construct (folder, frontmatter, multi-step instructions). When this doc says "command" it means the simple `.claude/commands/<name>.md` form.

**What they look like:**

```
.claude/commands/tldr.md
```

```markdown
---
description: Summarize a file, function, or diff in 3 bullets
argument-hint: [file or path or "HEAD"]
---

Summarize the following in exactly 3 bullets: $ARGUMENTS

Rules:
- Exactly 3 bullets.
- Each ≤ 20 words.
- Lead with the most important fact.
```

`$ARGUMENTS` gets replaced with whatever the user typed after the command name. So `/tldr src/foo.ts` runs the template with `$ARGUMENTS = src/foo.ts`.

**When to use a slash command:**
- You want a quick, consistent prompt that takes arguments.
- The task is one-shot — one prompt, one answer — no multi-step process.
- You want the shortest path from idea to output.

**When to reach for a skill instead:**
- The task has multiple phases (gather data, analyze, produce artifact).
- You want Claude to follow a specific *process* — check X first, then Y, then Z.
- You need structure the template-plus-args shape can't express.

> Slash commands aren't going away, but **skills are now the recommended primary mechanism** for any non-trivial workflow. If you're starting fresh, default to a skill. Use a command for true one-liners.

## Slash commands vs. skills

Both are invoked with `/<name>`. The difference is structure:

| | Slash command | Skill |
|---|---|---|
| Format | Single `.md` file in `.claude/commands/` | Folder with `SKILL.md` in `plugins/team-power-pack/skills/` |
| Takes arguments | Yes (`$ARGUMENTS`, `argument-hint:`) | Claude parses from user message |
| Structure | One prompt | Multi-step process |
| Good for | Quick shortcuts | Repeatable workflows |
| Example | `/tldr src/foo.ts` | `/migration-review` |

**Heuristic:** start with a command. If the prompt grows steps and starts looking like a recipe, promote it to a skill.

👉 **This repo's slash commands:** see the table in [README](../README.md) and [COMMANDS.md](commands.md).

---

## Skills — "I want to kick off this workflow"

A skill is a procedure Claude loads when it becomes relevant. The `description` is what decides that: Claude reads every skill's description and loads the body when your request matches. You can also invoke one directly with `/<name>`.

**What they look like** — a folder, not a file:

```
plugins/team-power-pack/skills/migration-review/
  SKILL.md              the procedure
  references/           detail loaded only when needed
  scripts/              executables the skill can run
```

That structure is the point. `SKILL.md` stays short, and long templates or edge-case detail live in `references/` where they cost no context until Claude actually opens them.

Inside `SKILL.md`, frontmatter plus Markdown instructions:

```markdown
---
name: migration-review
description: This skill should be used when the user types /migration-review,
  is about to ship a database schema change, or asks whether a migration is
  safe to run against production.
allowed-tools: Read, Grep, Glob, Bash(git:*)
---

# Migration review

Your job is to find the migrations that will lock a production table.

## Step 1 — Identify what to review
...
```

**When to use a skill:**
- You do the same kind of task repeatedly (reviews, PR descriptions, commits, release notes).
- The task has a process you want followed the same way every time.
- You want shareable, forkable workflows — skills are plain Markdown.

**When NOT to use a skill:**
- One-off tasks. Just ask Claude directly.
- Things that need to be auto-triggered on an event. That's a hook.

👉 **This repo's skills:** see the Skills table in [README](../README.md).

---

## Agents — "I want a specialist opinion"

An agent is a separate instance of Claude with its own system prompt, its own tool access, and a fresh context window. When the main Claude delegates to an agent, the agent's conversation is isolated — only its final summary comes back.

**Two ways agents get invoked:**

1. **Claude picks one automatically.** When you say "review this diff", Claude notices the `code-reviewer` agent's description matches and delegates.
2. **You request one by name.** Say "use the security-auditor agent" and Claude will.

**What they look like:**

```
plugins/team-power-pack/agents/security-auditor.md
```

```markdown
---
name: security-auditor
description: Use before shipping code that touches auth, input parsing, secrets...
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a security engineer reviewing code for shippability...
```

**When to use an agent:**
- You want a *second opinion* independent of the main conversation. Since the agent has fresh context, it won't be biased by what the main thread already decided.
- You want to keep a large research task out of your main context window (the agent does the research and returns a summary).
- You want *restricted* tool access — e.g., a reviewer that can't write files, only read them.

**When NOT to use an agent:**
- You're in an active conversation and want to keep the same context. Just prompt the main Claude.
- The task is trivial — spawning an agent adds overhead.

**Skill vs. agent — the cleanest heuristic:**
> A **skill** structures *what Claude does when you ask*. An **agent** is *who you're asking*.

A skill is a recipe. An agent is a specialist. You can even use them together — a skill's instructions can say "for the security pass, delegate to the `security-auditor` agent".

👉 **This repo's agents:** see the Agents table in [README](../README.md).

---

## Hooks — "Do this automatically when Claude does X"

Hooks are shell commands the Claude Code harness runs when specific events fire. Claude isn't aware of them; the *harness* runs them around Claude's actions.

**Example events:**

| Event | Fires when |
|---|---|
| `PreToolUse` | Just before Claude runs a tool (you can block it) |
| `PostToolUse` | After a tool completes |
| `Stop` | When Claude finishes responding |
| `Notification` | When Claude needs your attention (approval prompt, etc.) |
| `UserPromptSubmit` | When you hit enter on a message |
| `SessionStart` | When Claude Code launches |

**How they're configured:** In `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "/Users/you/plugins/guardrails/hooks/format-on-edit.sh" }
        ]
      }
    ]
  }
}
```

**What hooks are for:**
- Running formatters automatically after Claude edits files
- Blocking dangerous commands (force-push, writes to `.env`)
- Sending notifications when Claude is waiting on you
- Logging every action for audit
- Enforcing repo rules ("no edits under `dist/`")

**What hooks are NOT for:**
- Changing how Claude *talks*. That's an output style.
- Giving Claude new capabilities. That's an MCP server.

👉 **This repo's hooks:** see [HOOKS.md](hooks.md).

---

## Output styles — "Change how Claude talks for a while"

An output style is a reusable system-prompt preset. Switch to one and all of Claude's responses for this session (or until you change it) get that style on top.

**How to activate:**

- `/config` → pick from the Output Style list
- Or set `"outputStyle": "<name>"` in `settings.json`

**What they look like:**

```markdown
---
name: terse
description: Short answers, no preamble, no recap.
---

You are in terse mode. No preamble. ≤ 2 sentences before tool calls. No trailing summary.
```

**When to use an output style:**
- You want Claude's voice to change for a while (pair programming, teaching, reviewing)
- You're tired of verbose output and want to switch to terse mode for a session
- You want the team to share a house style for Claude

**Skill vs. output style:**
> A **skill** changes what Claude *does*. An **output style** changes how Claude *talks*.

You can combine them: activate the `senior-reviewer` style, then run `/migration-review` — you get the rigorous review process *and* the adversarial tone.

👉 **This repo's styles:** see [OUTPUT-STYLES.md](output-styles.md).

---

## MCP servers — "Give Claude access to a new system"

MCP (Model Context Protocol) servers are external processes that expose tools to Claude. Unlike hooks, MCP tools are invoked *by Claude* — they become part of the tool list Claude can call.

Example: the GitHub MCP server exposes tools like `github.create_issue`, `github.list_prs`. Claude can call them the same way it calls `Bash` or `Read`.

**Configured in `.mcp.json` at the repo root** (project scope), or through
`claude mcp add` (user scope, stored in `~/.claude.json`). **Not in
`settings.json`** — an `mcpServers` key there is silently ignored.

```json
{
  "mcpServers": {
    "example-remote": {
      "type": "http",
      "url": "https://mcp.example.com/mcp"
    },
    "example-local": {
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "env": { "API_KEY": "${EXAMPLE_TOKEN}" }
    }
  }
}
```

**When to use an MCP server:**
- Claude needs to talk to a system beyond your local machine (GitHub, Linear, Sentry, Slack, a database)
- You want structured, typed tool access instead of shelling out through `Bash`

See [mcp.md](mcp.md) for the CLI, transports, plugin bundling, and why this repo does not ship a curated server list.

---

## Plugins — "Bundle this stuff and ship it to a team"

A plugin is a Git repo with `.claude-plugin/plugin.json` declaring a bundle of skills, agents, slash commands, output styles, hooks, and/or MCP servers. Users install with one command:

```
/plugin marketplace add <git-url-or-owner/repo>
/plugin install <plugin-name>@<marketplace-name>
```

…and they get every component the plugin ships, in one go. Updates are pulled with `/plugin marketplace update`.

**What plugins are for:**
- Sharing a curated toolkit across a team without each person running an install script.
- Distributing your work to the open source community.
- Versioning bundles together so a `team-power-pack v1.2` always means the same thing.

**What plugins are NOT:**
- A different *kind* of feature. A plugin is a *delivery vehicle* for the features you already understand. There's no such thing as "plugin code" — there's a skill, agent, hook, etc., that happens to live inside a plugin.

**This repo is a marketplace shipping two plugins** — see [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json), and the per-plugin manifests at [`plugins/guardrails/.claude-plugin/plugin.json`](../plugins/guardrails/.claude-plugin/plugin.json) and [`plugins/team-power-pack/.claude-plugin/plugin.json`](../plugins/team-power-pack/.claude-plugin/plugin.json). Either install it (see [install.md](install.md)) or use the layout as a template for your own.

👉 **Full plugin guide:** see [PLUGINS.md](plugins.md).

---

## How they compose

These features work together. A realistic setup:

- **Output style** `terse` active — Claude is concise by default
- **Skills** `/migration-review`, `/release-notes`, `/standup` ready to invoke
- **Agents** `security-auditor`, `architect` available — Claude delegates to them when relevant
- **Hooks**: `format-on-edit.sh` formats every file Claude edits; `block-force-push.sh` protects your remote; `notify-on-idle.sh` pings your desktop when Claude needs input
- **MCP servers** for GitHub + Sentry so Claude can read issues and error events directly

Those are the surfaces this repository ships. They are not the whole picture. Also worth knowing:

- **`CLAUDE.md`** — memory files loaded into every session, with `@import` syntax and an enterprise / project / user hierarchy. The highest-leverage customization there is, and the cheapest.
- **`settings.json` permissions** — `allow`, `ask`, and `deny` rules plus permission modes. Deny beats allow, and project settings beat user settings. See [settings.md](settings.md).
- **Status line** — a script that renders the bar under your prompt. This repo ships one in `plugins/team-power-pack/statusline/`.
- **Sandboxing** — filesystem and network isolation configured under `sandbox` in `settings.json`.
- **The `SlashCommand` tool** — lets Claude invoke your commands itself rather than waiting for you to type them.

Plugins exist to ship any combination of these as a single installable unit.

## How to invoke each one (the exact mechanics)

Most of the confusion in this repo comes from the naming: `/migration-review` (skill) and `sql-reviewer` (agent) sound alike but are invoked differently. Here's the definitive table:

| Feature | Invocation | Who does the work | Context |
|---|---|---|---|
| **Slash command** | Type `/name [args]` — e.g. `/tldr src/foo.ts` | Main Claude in your current chat | Same as your conversation |
| **Skill** | Type `/name` — e.g. `/migration-review` | Main Claude in your current chat | Same as your conversation |
| **Agent** | Ask by name — e.g. "use the code-reviewer agent" or "@agent-code-reviewer" | A separate sub-Claude spawned for this task | Fresh, isolated — doesn't see your prior chat |
| **Output style** | `/config` → pick one | Main Claude, but voice/tone changed | Same conversation, different instructions on top |
| **Hook** | Triggered automatically by Claude Code events | Not Claude — a shell script you wrote | N/A (runs outside the conversation) |
| **Plugin** | `/plugin install <name>@<marketplace>` (one-time) | N/A — installs other components | N/A |

### `/migration-review` vs. `sql-reviewer` — worked example

```
You: /migration-review
```
→ Main Claude reads `plugins/team-power-pack/skills/migration-review/SKILL.md` and follows its process. The review is produced inline, in your current conversation. Cheap, fast, same context.

```
You: Use the code-reviewer agent to look at my staged changes.
```
→ Claude spawns a sub-Claude (the `code-reviewer` agent) with a fresh context window. The sub-Claude reads the diff, produces a review, and returns just its summary. Your main context isn't filled with the review detail. The sub-Claude has no idea what you and main-Claude were just discussing — it's genuinely a second pair of eyes.

**Which should you use?**

- **Skill** when you just want a review, any time. Works well when starting fresh.
- **Agent** when you've been deep in the code and want a *fresh-eyes* pass that won't be biased by whatever you just argued into existence with main Claude. Or when you want to keep the noisy review output out of your primary context.

**They compose.** A skill can delegate sub-tasks to an agent. `/migration-review` can internally say "for the query-plan pass, delegate to the `sql-reviewer` agent." Skills drive the workflow; agents provide specialist, isolated second-opinion work.

### Naming agents explicitly vs. auto-delegation

Two ways Claude picks an agent:

1. **You name it.** "Use the architect agent" / "have the doc-writer draft this" / `@agent-security-auditor`. Most reliable — you get the specialist you wanted.
2. **Claude picks one based on `description`.** Each agent's frontmatter says when it should activate. When your request matches, Claude may auto-delegate without you asking.

If auto-delegation misses, just name the agent — "use the X agent on this" is always unambiguous.

## Common confusions

- **"Command or skill?"** — Write a skill. Slash commands are the legacy form and have merged into skills; a skill with `disable-model-invocation: true` behaves exactly like the old command form, and gains frontmatter, bundled references, and scripts.
- **"Skill or agent?"** — Not about who invokes it: Claude decides when to use a *skill* too, by matching your request against its `description`. The real difference is context. A skill runs **in your conversation**, using your context and adding to it. An agent runs in a **separate context window** and reports back a result. Reach for an agent when you want a fresh pair of eyes, or when the work would flood your main context.
- **"Should I use a hook or a skill for X?"** — Does the user need to ask for it every time? Skill. Does it need to happen automatically, without Claude even knowing? Hook.
- **"What's the difference between an output style and a skill?"** — Style = how Claude talks. Skill = what Claude does. They stack.
- **"Does an agent replace the main Claude?"** — No. The main Claude delegates *to* the agent, reads its result, and continues the conversation with you.
- **"Plugin or skill?"** — Not a real choice — a plugin is just a way to ship one or more skills (or agents, or hooks…). Author skills. Bundle them as a plugin when you want to share them.
