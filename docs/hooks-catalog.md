# Example hooks

See [`HOOKS.md`](../../HOOKS.md) at the repo root for the guide. This folder contains the scripts.

| Script | Event | What it does |
|---|---|---|
| `format-on-edit.sh` | PostToolUse | Runs prettier/black/gofmt/rustfmt on files Claude edits |
| `block-env-writes.sh` | PreToolUse | Prevents writes to `.env`, private keys, credentials files |
| `block-force-push.sh` | PreToolUse | Blocks `git push --force` without explicit opt-in |
| `session-summary.sh` | Stop | Appends a session record to `~/.claude/session.log` |
| `notify-on-idle.sh` | Notification | Desktop notification when Claude is waiting on you |

## Install one

```bash
mkdir -p ~/.claude/hooks
cp format-on-edit.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/format-on-edit.sh
```

Then paste the config block from the script's header comment into `~/.claude/settings.json`.

## Check before copying

Each script has comments at the top explaining exactly what it does and the `settings.json` block to add. Read the script first — hooks run as you, with your permissions.

## Safe combinations

These go well together:

- `format-on-edit.sh` + `block-env-writes.sh` — everyday ergonomics + basic secret safety
- `block-force-push.sh` + `block-env-writes.sh` — guardrails for autonomous use
- `session-summary.sh` + `notify-on-idle.sh` — track what happened + don't miss prompts

## Debugging hooks

If a hook doesn't seem to fire:

1. Check the path in `settings.json` is absolute.
2. Check the script is executable (`chmod +x`).
3. Run the script manually with a sample stdin: `echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.js"}}' | ./format-on-edit.sh`
4. Restart Claude Code — hook config is read at startup.
