# Hooks — the most underused Claude Code feature

Hooks let you run a shell command on specific Claude Code events: before a tool runs, after a tool runs, when Claude stops, when a notification fires, when the user submits a prompt. They're how you turn Claude Code from a chat into a **programmable harness**.

Most people never try them. That's a missed opportunity.

## What you can do with hooks

- **Format code automatically** after Claude edits a file (prettier, black, gofmt)
- **Block dangerous commands** (force-push, secrets in commits) before they run
- **Summarize a session** when Claude stops working
- **Get a notification** when Claude needs your input
- **Enforce repo rules** (no edits to `dist/`, no writes to `.env`)
- **Auto-run tests** after Claude edits source files
- **Log every tool call** to a file for audit

Hooks run as your shell user with your permissions. Write them carefully.

## Events you can hook

| Event | Fires when |
|---|---|
| `PreToolUse` | Before a tool call. Can block the call by exiting non-zero. |
| `PostToolUse` | After a tool call completes. |
| `Stop` | When Claude finishes responding. |
| `SubagentStop` | When a sub-agent finishes. |
| `Notification` | When Claude needs the user's attention (approval prompts, etc.). |
| `UserPromptSubmit` | When the user submits a message. Can transform it. |
| `SessionStart` | When Claude Code launches. |
| `PreCompact` | Before the harness compacts your conversation history. |

## How hooks are configured

In `~/.claude/settings.json` or `.claude/settings.json` in your project:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/your-hook.sh"
          }
        ]
      }
    ]
  }
}
```

- **`matcher`** is a regex against the tool name. Use `Edit|Write` to hook both. Omit for all tools.
- **`command`** is the shell command to run. Absolute paths are safer than relative ones.
- The hook receives a JSON blob on stdin describing the event. See each example for what it contains.

## Ready-to-use examples

Each file in `.claude/hooks/` is a self-contained, commented script. Read before you install — you'll want to tweak them.

| Hook | Event | What it does |
|---|---|---|
| [`format-on-edit.sh`](.claude/hooks/format-on-edit.sh) | `PostToolUse` | Runs the right formatter for the edited file (prettier, black, gofmt, rustfmt) |
| [`block-env-writes.sh`](.claude/hooks/block-env-writes.sh) | `PreToolUse` | Blocks writes to `.env*` files and common secret files |
| [`block-force-push.sh`](.claude/hooks/block-force-push.sh) | `PreToolUse` | Refuses `git push --force` unless a flag file exists |
| [`session-summary.sh`](.claude/hooks/session-summary.sh) | `Stop` | Logs a one-line summary of each session to a rolling file |
| [`notify-on-idle.sh`](.claude/hooks/notify-on-idle.sh) | `Notification` | macOS notification + sound when Claude is waiting on you |

## Install one

1. Copy the script to somewhere stable (e.g. `~/.claude/hooks/`):
   ```bash
   mkdir -p ~/.claude/hooks
   cp .claude/hooks/format-on-edit.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/format-on-edit.sh
   ```

2. Register it in `~/.claude/settings.json` (see each script's header for the exact config block to paste in).

3. Restart Claude Code.

4. Try it — e.g. edit a file Claude opens, watch the formatter run.

## Writing your own

The script receives a JSON blob on stdin. Parse it, do work, control flow via exit code:

- **Exit 0** → allow the action to proceed (for `PreToolUse`) or just finish (other events).
- **Exit non-zero** → block the action (`PreToolUse` only; other events ignore this). stdout becomes the reason shown to Claude.
- **stdout during allowed events** → may be appended to the transcript depending on event. Use sparingly.

Minimal hook template:

```bash
#!/usr/bin/env bash
set -euo pipefail
input=$(cat)   # JSON blob from Claude Code
# extract fields with jq
tool=$(echo "$input" | jq -r '.tool_name // empty')
# do work, decide to allow or block
exit 0
```

## Rules of thumb

- **Fail safe.** If your hook errors out, make sure the failure doesn't corrupt state.
- **Be fast.** Hooks run synchronously — a 5-second hook makes Claude feel 5 seconds slower.
- **Be quiet.** Only print to stdout if you want Claude to see the output.
- **Absolute paths.** Relative paths depend on where Claude was launched from.
- **Test outside the harness first.** Cat a sample JSON blob into your script and see what it does.
- **Version control your hooks.** They're code, and they'll bite you if you can't diff them.
