---
name: hook-authoring
description: This skill should be used when the user asks to "write a hook", "add a Claude Code hook", "make Claude stop doing X automatically", "block a tool call", or wants a hook tested. It covers choosing the event, the exit-code and JSON contract, and shipping the hook with a test.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Write a Claude Code hook that works

Most hooks in the wild are subtly broken in the same way: they detect the thing correctly and then fail to act on it, because the author assumed a non-zero exit blocks the call. It does not. This skill exists to make that impossible to get wrong.

For the full event list and payload shapes, read `references/hook-events.md`. For the tested patterns, read `references/patterns.md`.

## Step 1 — Pick the event

Ask what the user wants to happen, then map it:

| They want | Event | Can it block? |
|---|---|---|
| Stop a tool call before it runs | `PreToolUse` | Yes |
| React after a tool ran (format, lint, log) | `PostToolUse` | No |
| Add context when a session starts | `SessionStart` | No |
| Rewrite or reject a user prompt | `UserPromptSubmit` | Yes |
| Stop Claude from ending its turn | `Stop` | Yes |
| Record what happened at the end | `SessionEnd` | No |

If they want to *prevent* something, it must be a `PreToolUse` hook. A `PostToolUse` hook cannot undo the write that already happened; the most it can do is tell Claude to clean up.

Check `references/hook-events.md` before assuming an event does not exist — there are 32, and the useful ones beyond the obvious six include `PostToolUseFailure`, `SubagentStop`, `PreCompact`, `ConfigChange`, and `TeammateIdle`.

## Step 2 — Write it against the contract

The contract that matters:

- **exit 0** — proceed. stdout is parsed as JSON if it is valid JSON.
- **exit 2** — block, on events that support blocking. The reason comes from stderr.
- **exit 1 or anything else** — a non-blocking error. **The action still happens.**

Prefer the JSON form on exit 0, because it carries a structured reason Claude can act on:

```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}
```

`permissionDecision` accepts `allow`, `deny`, and `ask`. Use `ask` for anything that is legitimate but destructive — `git reset --hard`, `DROP TABLE`, a production config edit. Reserve `deny` for what is genuinely never intended.

Do not hand-roll that JSON. This plugin ships `hooks/lib/common.sh`; source it and call `deny`, `ask`, `add_context`, `warn`, or `allow`:

```bash
#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

file="$(hook_field '.tool_input.file_path')"
[ -z "$file" ] && allow

case "$(basename "$file")" in
  *.lock) deny "Refused to edit $file by hand. Lockfiles are generated; run the package manager instead." ;;
esac

allow
```

Use `set -uo pipefail`, not `set -euo pipefail`. With `set -e`, a `jq` filter that matches nothing returns non-zero and kills the hook before it reaches the decision.

## Step 3 — Test it before wiring it

A hook is a program that reads JSON on stdin. Test it like one:

```bash
echo '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/app/yarn.lock"}}' \
  | ./my-hook.sh; echo "exit=$?"
```

Then write a bats test asserting the decision, not the exit code alone. The test that matters is the one that fails when the hook stops blocking:

```bash
@test "denies editing a lockfile" {
  run -0 run_hook my-hook.sh "$(pretooluse Write '{"file_path":"/app/yarn.lock"}')"
  assert_denied "$output"
}

@test "allows an ordinary source file" {
  run -0 run_hook my-hook.sh "$(pretooluse Write '{"file_path":"/app/src/a.ts"}')"
  assert_allowed "$output"
}
```

Always write the negative case too. A hook that denies everything passes every deny test and makes the tool unusable.

## Step 4 — Wire it

For a personal hook, `settings.json`:

```json
{"hooks":{"PreToolUse":[{"matcher":"Edit|Write","hooks":[
  {"type":"command","command":"$CLAUDE_PROJECT_DIR/.claude/hooks/my-hook.sh","timeout":10}]}]}}
```

For a hook shipped in a plugin, `hooks/hooks.json` at the plugin root, using `${CLAUDE_PLUGIN_ROOT}` — never an absolute path, which breaks on every other machine:

```json
{"hooks":{"PreToolUse":[{"matcher":"Edit|Write","hooks":[
  {"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.sh","timeout":10}]}]}}
```

The `matcher` is a regex over the tool name. Omit it for events that are not tool-scoped. Set a `timeout` — the default is generous and a hanging hook stalls the session.

Then `chmod +x` the script. A non-executable hook fails silently.

## Rules

- **Never claim a hook blocks without running it and seeing the deny.**
- **Fail open.** If `jq` is missing or the payload is unexpected, exit 0. A hook that breaks the session on an edge case gets deleted, and then it protects nothing.
- **One hook, one job.** Several small hooks on the same matcher are easier to test and disable than one that does everything.
- **Keep hooks fast.** They run on every matching tool call, in the user's critical path.
- **Never log secrets.** Hook payloads contain file contents and command strings.
