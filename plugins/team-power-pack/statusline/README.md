# Custom status line

The status line is the info strip at the bottom of Claude Code. By default it shows the model. You can make it show anything you want.

## What's here

`statusline.sh` — a bash script that prints:

```
sonnet-4-6 | my-app | main* ↑2 | $0.42
```

- **Model** — what's running (sonnet/opus/haiku + version)
- **Directory** — basename of the current working dir
- **Git** — branch, `*` if dirty, `↑N` ahead / `↓N` behind upstream
- **Session cost** — running token cost in USD (if the harness provides it)

## Install

```bash
mkdir -p ~/.claude/statusline
cp statusline.sh ~/.claude/statusline/
chmod +x ~/.claude/statusline/statusline.sh
```

Then register in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/statusline.sh"
  }
}
```

Restart Claude Code.

## How it works

On each redraw, the harness pipes a JSON blob to the command's stdin:

```json
{
  "model": { "display_name": "Sonnet 4.6" },
  "workspace": { "current_dir": "/path/to/project" },
  "session_id": "...",
  "cost": { "total_cost_usd": 0.42 }
}
```

Whatever the command writes to stdout becomes the status line. Keep it short — long status lines wrap and look bad.

## Customizing

Open `statusline.sh` and edit the composition at the bottom. Ideas:

- Drop the cost if your org hides it
- Show the current Claude *task* status (if you use background tasks)
- Pull from `gh pr view --json isDraft,state` to show "PR: draft" when one is open
- Show `kubectl config current-context` if you work across clusters
- Show `AWS_PROFILE` if you switch profiles frequently

## Speed matters

This script runs on every redraw. Keep it under ~100ms:

- Don't make network calls.
- Don't run `git status` (slow on big repos) — prefer `git diff --quiet` and `rev-list --count`.
- Cache expensive lookups in a temp file if needed.
