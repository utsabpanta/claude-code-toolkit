# Install

Requires Claude Code 2.1.x or newer (`claude --version`). The hooks need `jq`;
without it they skip themselves with a warning rather than breaking your
session.

## Option 1 — Plugin (recommended)

Two plugins ship from one marketplace. Install either or both.

From inside Claude Code:

```
/plugin marketplace add utsabpanta/claude-code-toolkit
/plugin install guardrails@claude-code-toolkit
/plugin install team-power-pack@claude-code-toolkit
```

Or from your shell:

```bash
claude plugin marketplace add utsabpanta/claude-code-toolkit
claude plugin install guardrails@claude-code-toolkit
```

`/plugin install` takes `plugin-name@marketplace-name`. It does not take a URL —
add the marketplace first.

**Hooks are wired automatically.** `guardrails` ships `hooks/hooks.json`, which
Claude Code merges with your own hooks on install. There is no `settings.json`
editing and no absolute path to hand-write.

Verify:

```bash
claude plugin details guardrails
```

You should see three skills and six hook events.

## Option 2 — For a whole team

Commit this to the repo's `.claude/settings.json` and everyone who opens the
project gets the guardrails, with no per-person setup:

```json
{
  "extraKnownMarketplaces": {
    "claude-code-toolkit": {
      "source": { "source": "github", "repo": "utsabpanta/claude-code-toolkit" }
    }
  },
  "enabledPlugins": ["guardrails@claude-code-toolkit"]
}
```

Pin a version by adding `"ref": "v1.0.0"` to the source if you would rather
review upgrades than take them automatically.

## Option 3 — Script, no plugin system

```bash
git clone https://github.com/utsabpanta/claude-code-toolkit
cd claude-code-toolkit
./install.sh --all
```

Copies into `~/.claude/`. Existing files are skipped rather than overwritten.
Flags: `--skills`, `--agents`, `--hooks`, `--output-styles`, `--statusline`,
`--all`. With no flags it prompts.

Installed this way, hooks are **not** wired — the script prints the
`settings.json` block to paste. This is the tradeoff the plugin path avoids.

## Option 4 — Cherry-pick

Everything here is a plain file. Copy what you want:

```bash
cp -r plugins/team-power-pack/skills/migration-review ~/.claude/skills/
cp -r plugins/team-power-pack/agents/sql-reviewer.md  ~/.claude/agents/
cp    plugins/guardrails/hooks/guard-secrets.sh       ~/.claude/hooks/
cp    plugins/guardrails/hooks/lib/common.sh          ~/.claude/hooks/lib/
```

A hook copied this way needs `lib/common.sh` alongside it, `chmod +x`, and a
`settings.json` entry.

## Permission policies

Not installed automatically — permissions are too repo-specific to impose.

```bash
cat plugins/guardrails/policies/balanced.json
```

Merge the one you want into `.claude/settings.json`, or run `/permission-policy`
and let it calibrate to your repo's actual scripts. The three profiles are
`strict` (shared repos with a deploy path), `balanced` (normal team work), and
`solo` (personal projects).

## Status line

```bash
mkdir -p ~/.claude/statusline
cp plugins/team-power-pack/statusline/statusline.sh ~/.claude/statusline/
chmod +x ~/.claude/statusline/statusline.sh
```

Then in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline/statusline.sh"
  }
}
```

Renders `sonnet-5 | my-app | main* up2 | $0.42`.

## Output styles

Installed with `team-power-pack`. Switch with `/output-style terse`, or set
`"outputStyle": "terse"` in `settings.json`. If your Claude Code version does not
surface plugin-provided styles, copy them into `~/.claude/output-styles/`
instead — `./install.sh --output-styles` does that.

## Verify the install

```bash
claude plugin list
./scripts/doctor.sh .
```

Then confirm the guardrails actually guard. In a scratch repo, ask Claude to
write to `.env`. The write should be **refused**, not warned about.

## Uninstall

```bash
claude plugin uninstall guardrails@claude-code-toolkit
claude plugin marketplace remove claude-code-toolkit
```

Script installs are removed by deleting the copied files from `~/.claude/`.

## Troubleshooting

**A skill does not appear.** Restart Claude Code. Check `claude plugin list`
shows the plugin enabled, and that the folder name matches the `name` in the
skill's frontmatter — `scripts/doctor.sh` checks this.

**A hook does not fire.** Run `claude plugin details guardrails` and confirm the
hook events are listed. Then run the hook by hand:

```bash
echo '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/tmp/.env"}}' \
  | plugins/guardrails/hooks/guard-secrets.sh
```

A deny payload means the hook works and the wiring is the problem. No output
means the hook itself is the problem.

**A hook fires but does not block.** That is the bug this toolkit exists for. See
[hooks.md](hooks.md): exit 1 does not block, only exit 2 or a `deny` payload does.

**`jq: command not found`.** `brew install jq` or `apt install jq`. Hooks skip
themselves without it.
