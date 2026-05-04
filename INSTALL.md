# Install

Pick whichever path matches how you want to manage Claude Code extensions.

## Option 1 — Plugin (recommended)

In Claude Code, run:

```
/plugin marketplace add utsabpanta/claude-code-toolkit
/plugin install team-power-pack@claude-code-toolkit
```

That installs all 19 skills, 12 agents, 6 slash commands, and 4 output styles in one step. Updates are pulled with `/plugin marketplace update claude-code-toolkit`.

To install directly from the Git URL without registering the marketplace:

```
/plugin install https://github.com/utsabpanta/claude-code-toolkit
```

For local development:

```bash
git clone https://github.com/utsabpanta/claude-code-toolkit
claude --plugin-dir ./claude-code-toolkit
```

> Hooks are **not** auto-installed by the plugin — they need machine-specific paths and shouldn't run silently. Install them with `./install.sh --hooks` (Option 2 below) and follow [HOOKS.md](HOOKS.md) to wire them in.

See **[PLUGINS.md](PLUGINS.md)** for more on installing, updating, and publishing plugins.

---

## Option 2 — Script

If you'd rather drop files into `~/.claude/` directly:

```bash
git clone https://github.com/utsabpanta/claude-code-toolkit && cd claude-code-toolkit
./install.sh                 # interactive picker
./install.sh --all           # install everything
./install.sh --skills        # just skills
./install.sh --commands      # just slash commands
./install.sh --agents        # just agents
./install.sh --output-styles # just output styles
./install.sh --hooks         # hook scripts (you wire them in settings.json)
./install.sh --statusline    # status line (you wire it in settings.json)
```

The script is idempotent: it won't overwrite existing files, only add new ones.

## Option 3 — Manual user-level install

Skills/commands/agents/styles land in your user folder and activate for any project:

```bash
mkdir -p ~/.claude/skills ~/.claude/commands ~/.claude/agents ~/.claude/output-styles
cp -r .claude/skills/*        ~/.claude/skills/
cp -r .claude/commands/*.md   ~/.claude/commands/
cp -r .claude/agents/*        ~/.claude/agents/
cp -r .claude/output-styles/* ~/.claude/output-styles/
```

## Option 4 — Project-level

Commit the `.claude/` folder into your project — your whole team gets the same skills:

```bash
cd /path/to/your-project
cp -r /path/to/claude-code-toolkit/.claude .
git add .claude && git commit -m "Add shared Claude skills"
```

Project-level skills override user-level ones with the same name.

## Option 5 — Cherry-pick

Every skill and agent is self-contained:

```bash
cp -r .claude/skills/code-review     ~/.claude/skills/
cp .claude/agents/security-auditor.md ~/.claude/agents/
cp .claude/output-styles/terse.md     ~/.claude/output-styles/
```

---

## Hooks and status line — separate opt-in

These require editing `~/.claude/settings.json`. The scripts are copied but do nothing until you register them.

**Hooks** — see [HOOKS.md](HOOKS.md). Each script's header has the exact `settings.json` block to paste.

**Status line** — see [.claude/statusline/README.md](.claude/statusline/README.md):

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/you/.claude/statusline/statusline.sh"
  }
}
```

## Settings

`settings.example.json` is a template, not auto-installed. Merge what you want:

```bash
# No existing settings:
cp settings.example.json ~/.claude/settings.json

# Already have one:
# open both files, merge the `permissions.allow` / `deny` arrays
```

See [settings.example.README.md](settings.example.README.md) for what each field does.

## Verify

1. Restart Claude Code (only needed for the script-based install — plugins activate immediately).
2. Type `/` — new slash commands and skills should appear.
3. Try `/code-review` in a repo with staged changes.
4. Run `/config` and look for "Output Style" — the new styles should appear in the picker.
5. If you installed agents, Claude can delegate to them by name (`use the security-auditor agent`).

## Troubleshooting

**A skill doesn't appear in the menu:**
- File must be at `~/.claude/skills/<name>/SKILL.md` (folder + file), or installed via plugin.
- `name:` in frontmatter must match the folder name.
- Restart Claude Code (script install only — plugins live-reload).

**A plugin slash command isn't appearing or collides with a user command:**
- Plugin slash commands get namespaced when there's a collision: try `/team-power-pack:tldr` instead of `/tldr`.
- Check `/plugin` to verify the plugin is enabled.

**An agent isn't being used:**
- Agents are opportunistically picked by Claude — they activate on matching tasks, not slash commands.
- The `description` field drives when the agent gets chosen. If yours has a vague description, it won't trigger.
- You can force Claude to use a specific agent by naming it: "use the security-auditor agent on this diff."

**A hook doesn't fire:**
- Absolute path in `settings.json`, not relative.
- Script has `chmod +x`.
- Test outside the harness: `echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.js"}}' | /path/to/hook.sh`
- Restart Claude Code after editing settings.

**Plugin install failed:**
- Make sure you can `git clone` the repo from your machine — Claude Code uses your git config.
- For private repos, configure SSH or set up a credential helper.
- Try `/plugin marketplace list` to confirm the marketplace registered.
