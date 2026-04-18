# About `settings.example.json`

A minimal, safe starting point for `~/.claude/settings.json` (or a project `.claude/settings.json`).

## What's in it

### `permissions.allow`
Read-only or test-running commands that are safe to auto-approve. Claude Code won't prompt for these.

- Git inspection (`status`, `diff`, `log`, `show`, `branch`, `rev-parse`, `remote -v`)
- Basic filesystem (`ls`, `pwd`, `cat`, `wc`)
- Common test/build commands for major ecosystems
- GitHub CLI *read* operations (`pr list`, `pr view`, `issue list`, `issue view`)

None of these can mutate remote state or destroy local work.

### `permissions.deny`
Explicitly blocks dangerous commands even if another rule would allow them.

- `rm -rf` — destructive recursive deletion
- `git push --force` / `-f` — rewrites remote history
- `gh pr merge` — merges PRs (keep this a human decision)
- `npm publish` / `cargo publish` — publishes packages

### `model`
Defaults to `claude-sonnet-4-6`. Change to `claude-opus-4-7` if you want Opus as the default, or remove the key to use Claude Code's built-in default.

### `env`
Empty by default. Add project env vars here (e.g. `"DEBUG": "true"`) — they'll be available to shell commands Claude runs.

## What's *not* in it, on purpose

- **No hooks.** Hooks are team- and workflow-specific; adding a default stop-hook or pre-tool-use hook would surprise users. Add your own.
- **No write permissions.** Anything that creates, moves, or deletes files will prompt. That's the right default when sharing with others — you want the user to opt in deliberately.
- **No MCP config.** MCP servers are per-install.

## How to use

```bash
# If you don't have a settings.json yet:
cp settings.example.json ~/.claude/settings.json

# If you do, open both and merge the `allow` / `deny` arrays manually.
```
