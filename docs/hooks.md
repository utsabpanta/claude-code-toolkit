# Hooks

A hook is a program Claude Code runs when something happens. It reads a JSON
event on stdin and decides what should follow.

Hooks are the only extension point that can *stop* Claude. They are also the one
that fails silently: a hook with the wrong exit code prints a refusal and lets
the action through. This page is the contract. The tested implementations are in
[`plugins/guardrails/hooks/`](../plugins/guardrails/hooks), and the complete
event reference is in
[`hook-events.md`](../plugins/guardrails/skills/hook-authoring/references/hook-events.md).

## The exit-code contract

| Exit code | Meaning |
|---|---|
| `0` | Proceed. stdout is parsed as JSON when it is valid JSON. |
| `2` | Block, on events that support blocking. The reason comes from stderr. |
| anything else | Non-blocking error. **The action still happens.** |

`exit 1` does not block anything. This is the single most common bug in
published Claude Code hooks, and it was present in this repository until the
1.0.0 rewrite: two hooks that existed to block secret writes and force pushes
both used `exit 1` and were no-ops.

Prefer the JSON form on exit 0, because it carries a structured reason:

```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"why"}}
```

`permissionDecision` is `allow`, `deny`, or `ask`. Use `ask` for actions that are
legitimate but destructive; a guardrail that blocks `git reset --hard` outright
gets uninstalled the first afternoon someone needs it.

## Events

There are 32. These are the ones most hooks use:

| Event | Fires | Can block |
|---|---|---|
| `PreToolUse` | Before a tool call | Yes |
| `PostToolUse` | After a tool call succeeds | No |
| `PostToolUseFailure` | After a tool call fails | No |
| `UserPromptSubmit` | On prompt submission | Yes |
| `SessionStart` | Session begins or resumes | No |
| `SessionEnd` | Session terminates | No |
| `Stop` | Claude finishes responding | Yes |
| `SubagentStop` | A subagent finishes | Yes |
| `PreCompact` / `PostCompact` | Around context compaction | Pre only |
| `Notification` | Claude Code emits a notification | No |

The full table, including `PostToolBatch`, `TeammateIdle`, `ConfigChange`,
`WorktreeCreate`, `PreModelSwitch`, and the elicitation events, is in
[hook-events.md](../plugins/guardrails/skills/hook-authoring/references/hook-events.md).

If you want to *prevent* something, it has to be `PreToolUse`. A `PostToolUse`
hook cannot undo the write that already happened.

## Configuring hooks

Personal hooks go in `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/plugins/guardrails/hooks/my-hook.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

`matcher` is a regex over the tool name; omit it for events that are not
tool-scoped. Set a `timeout` — a hanging hook stalls the session.

`/hooks` opens an interactive configuration UI, which is easier than hand-editing.

Hooks shipped in a plugin go in `hooks/hooks.json` at the plugin root and use
`${CLAUDE_PLUGIN_ROOT}` instead of an absolute path:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/guard-force-push.sh", "timeout": 10 }
      ]}
    ]
  }
}
```

This is why installing `guardrails` needs no `settings.json` editing at all.
Plugin hooks merge with user and project hooks rather than replacing them.

| Placeholder | Resolves to |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}` | The plugin's install directory |
| `${CLAUDE_PLUGIN_DATA}` | Plugin state that survives updates |
| `${CLAUDE_PROJECT_DIR}` | The project root where the session started |

## Hooks in this repository

Installed and wired automatically by `guardrails`. Every one has a bats suite in
[`tests/`](../tests).

| Hook | Event | What it does |
|---|---|---|
| `guard-secrets.sh` | PreToolUse | Denies writes to `.env`, private keys, service-account JSON, `secrets/` |
| `guard-force-push.sh` | PreToolUse | Denies force pushes, including `-f` and `+refspec` forms. One-shot override |
| `guard-destructive.sh` | PreToolUse | Denies `rm -rf /`, `mkfs`, `curl \| sh`. Asks before `git reset --hard`, `DROP TABLE` |
| `guard-prod-config.sh` | PreToolUse | Asks before production infra and CI workflow edits. Denies hand-edits to tfstate |
| `pre-commit-lint.sh` | PreToolUse | Lints staged files before `git commit`, denies on failure |
| `format-on-edit.sh` | PostToolUse | Runs the right formatter for the file just edited |
| `auto-gitignore.sh` | PostToolUse | Flags a sensitive new file that git is not ignoring |
| `guard-dependency-add.sh` | PostToolUse | Prompts a supply-chain check when a manifest changes |
| `audit-log.sh` | PostToolUse, SessionStart, SessionEnd | Local JSONL audit trail |
| `context-brief.sh` | SessionStart | Injects branch, divergence, and open-PR state |
| `session-summary.sh` | Stop | Appends a session record |
| `notify-on-idle.sh` | Notification | Desktop notification when Claude needs you |
| `test-on-edit.sh` | PostToolUse | Runs the nearest test file. **Not wired by default** |

`test-on-edit.sh` is deliberately unwired: running tests on every edit is right
for some repos and intolerable in others. Add it to your own `settings.json` if
you want it.

## Writing your own

Use the `/hook-authoring` skill, which walks the contract and generates the test
alongside the hook. The short version:

- Source `hooks/lib/common.sh` and call `deny`, `ask`, `add_context`, `warn`, or
  `allow`. Do not hand-roll the JSON.
- Use `set -uo pipefail`, **not** `set -euo pipefail`. Under `set -e`, a `jq`
  filter that matches nothing aborts the hook before it reaches the decision.
- Fail open. If `jq` is missing or the payload is unexpected, exit 0.
- `chmod +x` the script. A non-executable hook fails silently.
- Test it by piping a payload in, and assert the *decision*, not the exit code:

```bash
echo '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/tmp/.env"}}' \
  | plugins/guardrails/hooks/guard-secrets.sh
```

## Auditing what you already have

```bash
./scripts/doctor.sh .
```

It flags hooks that intend to block but exit 1, hooks that exit 2 without a
reason, `set -e` combined with `jq`, BSD-only date arithmetic, and hook commands
that point at files which do not exist.

## Security

Hooks run automatically with your user's permissions, and their payloads contain
file contents and command strings. Read any hook before installing it, never log
payloads to a shared location, and be aware that a hook is not a security
boundary against a determined process — it bounds accident and mistake.
