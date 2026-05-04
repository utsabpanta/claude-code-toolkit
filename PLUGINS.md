# Plugins — install this toolkit, ship your own

Plugins are how Claude Code distributes bundles of skills, agents, slash commands, output styles, hooks, and MCP servers. A plugin is a directory with a manifest (`.claude-plugin/plugin.json`); a *marketplace* is a catalog of plugins you publish at a Git URL.

This page covers two things:

1. **How to install this repo as a plugin.**
2. **How to publish your own plugin** — using this repo as a working template.

> Official docs: [Plugins](https://docs.claude.com/en/docs/claude-code/plugins) · [Plugin reference](https://docs.claude.com/en/docs/claude-code/plugins-reference) · [Plugin marketplaces](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)

---

## Install this repo as a plugin

This repo ships with `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, so you can install everything in one step from inside Claude Code.

### Option A — install from the marketplace (recommended)

In Claude Code:

```
/plugin marketplace add utsabpanta/claude-code-toolkit
/plugin install team-power-pack@claude-code-toolkit
```

That registers the marketplace, then installs the `team-power-pack` plugin (skills + agents + commands + output styles).

To list, update, or remove later:

```
/plugin marketplace list
/plugin marketplace update claude-code-toolkit
/plugin uninstall team-power-pack@claude-code-toolkit
```

### Option B — install directly from the Git URL

If you'd rather skip the marketplace step:

```
/plugin install https://github.com/utsabpanta/claude-code-toolkit
```

Claude Code reads `.claude-plugin/plugin.json` and registers the components.

### Option C — local development install

For hacking on the toolkit without publishing, point Claude Code at your local clone:

```bash
git clone https://github.com/utsabpanta/claude-code-toolkit
claude --plugin-dir ./claude-code-toolkit
```

Edits to skills/agents are picked up on restart.

### What you get after install

- **19 skills** — `/code-review`, `/commit`, `/pr-description`, `/standup`, `/incident`, …
- **6 slash commands** — `/tldr`, `/blame-why`, `/5-whys`, `/tradeoff`, `/what-changed`, `/rubber-duck`
- **12 agents** — `code-reviewer`, `security-auditor`, `architect`, `incident-commander`, …
- **4 output styles** — `terse`, `pair-programmer`, `teacher`, `senior-reviewer`

Hooks are **not** auto-installed by the plugin (they need to run shell scripts as you, with paths that vary per machine). Use `./install.sh --hooks` and follow [HOOKS.md](HOOKS.md) to wire them up.

---

## Publish your own plugin

The simplest possible plugin is a Git repo with this layout:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # required manifest
├── skills/
│   └── my-skill/SKILL.md    # optional — any combination of components
├── agents/
│   └── my-agent.md
├── commands/
│   └── my-command.md
├── output-styles/
│   └── my-style.md
├── hooks/
│   └── hooks.json           # optional — bind events to commands
└── README.md
```

You can include any subset of these. A plugin that ships only a single skill is fine.

### `plugin.json` — the minimum

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "What this plugin does, in one sentence.",
  "author": { "name": "Your Name", "url": "https://github.com/you" },
  "license": "MIT"
}
```

`name` and `version` are the only required fields. With the default layout above (`skills/`, `agents/`, `commands/`, `output-styles/`), Claude Code discovers components automatically — you don't need to list them.

### `plugin.json` — overriding paths

If your components live somewhere other than the defaults (this repo keeps everything under `.claude/` for backwards compatibility with `install.sh`), point at them explicitly:

```json
{
  "name": "team-power-pack",
  "version": "0.1.0",
  "skills": "./.claude/skills/",
  "agents": "./.claude/agents/",
  "commands": "./.claude/commands/",
  "outputStyles": "./.claude/output-styles/"
}
```

You can also pass arrays of specific files — useful for selectively exposing things:

```json
{
  "agents": ["./agents/security-auditor.md", "./agents/architect.md"]
}
```

### Bundling MCP servers

Add `.mcp.json` at the plugin root, or inline:

```json
{
  "name": "my-plugin",
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

When the plugin is enabled, the server starts automatically.

### Bundling hooks

Hooks belong in `hooks/hooks.json` (or inline as `"hooks": { … }` in `plugin.json`). Reference scripts inside the plugin via `${CLAUDE_PLUGIN_ROOT}`:

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [
        { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh" }
      ]
    }
  ]
}
```

Be careful here: a plugin that auto-runs shell scripts on a user's machine is a trust boundary. Keep hooks scoped, document them prominently in your README, and prefer fail-open scripts.

### Naming collisions

- **Plugin skills/commands** are namespaced when they conflict with user-level ones. If both `~/.claude/commands/tldr.md` and `team-power-pack`'s `/tldr` exist, the plugin command appears as `/team-power-pack:tldr`.
- **Agents** are picked by `description` match — keep yours specific.

---

## Publish a marketplace (catalog of plugins)

A marketplace is a Git repo with `.claude-plugin/marketplace.json` listing one or more plugins. It lets users install any plugin in your catalog with a single registration step.

```json
{
  "name": "my-marketplace",
  "owner": { "name": "Your Team", "url": "https://github.com/your-team" },
  "plugins": [
    {
      "name": "team-power-pack",
      "source": ".",
      "description": "Engineering team skills + agents.",
      "version": "0.1.0"
    },
    {
      "name": "frontend-pack",
      "source": "./packs/frontend",
      "description": "React-flavored review and a11y skills."
    },
    {
      "name": "external-plugin",
      "source": { "source": "github", "repo": "another-org/their-plugin" }
    }
  ]
}
```

Users install via:

```
/plugin marketplace add your-team/your-marketplace-repo
/plugin install team-power-pack@your-marketplace
```

`source` can be:
- A relative path inside the marketplace repo (`"."` or `"./packs/frontend"`)
- A `{ "source": "github", "repo": "owner/repo" }` object pointing at another GitHub repo
- A Git URL

This repo is itself a one-plugin marketplace — see [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).

---

## Versioning and updates

- Bump `version` in `plugin.json` when you change behavior. Semver is the convention, not enforced.
- Users get updates with `/plugin marketplace update <marketplace-name>`.
- Tag your repo (`git tag v0.2.0`) so users can pin specific versions if your plugin supports that — Claude Code defaults to tracking the marketplace's default branch.

---

## Testing your plugin before publishing

1. **Validate the manifest:**
   ```bash
   jq . .claude-plugin/plugin.json
   ```

2. **Local install:**
   ```bash
   claude --plugin-dir .
   ```

3. **In Claude Code, verify the components are loaded:**
   ```
   /plugin                # see your plugin listed
   /                      # your slash commands appear in autocomplete
   /agents                # your agents appear
   ```

4. **Try each component end-to-end** — invoke a skill, ask Claude to use an agent by name, switch to your output style.

5. **Push to a Git remote, then test the marketplace install** from a clean machine.

---

## Where to keep going

- This repo's [CONTRIBUTING.md](CONTRIBUTING.md) — conventions for skills, agents, hooks, output styles
- [CONCEPTS.md](CONCEPTS.md) — what each component type is for
- [Anthropic plugin docs](https://docs.claude.com/en/docs/claude-code/plugins) — full schema reference and edge cases
