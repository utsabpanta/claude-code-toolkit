# Claude Code hook events

Complete list as of Claude Code 2.1.251. Verified against
https://code.claude.com/docs/en/hooks

Most published hook guides list six to nine events and get the blocking rules
wrong. Check this table before concluding an event does not exist.

## Events

| Event | Fires when | Can block (exit 2) |
|---|---|---|
| `SessionStart` | A session begins or resumes | No |
| `Setup` | `--init-only`, `--init`, or `--maintenance` in `-p` mode | No |
| `UserPromptSubmit` | The user submits a prompt, before processing | Yes |
| `UserPromptExpansion` | A slash command expands into a prompt | Yes |
| `PreToolUse` | Before a tool call executes | Yes |
| `PermissionRequest` | A tool needs a permission decision | No |
| `PermissionDenied` | Auto mode denied a tool | No |
| `PostToolUse` | After a tool call succeeds | No |
| `PostToolUseFailure` | After a tool call fails | No |
| `PostToolBatch` | After a parallel batch of tool calls resolves | Yes |
| `Notification` | Claude Code emits a notification | No |
| `MessageDisplay` | Assistant message text streams to the display | No |
| `SubagentStart` | A subagent is spawned | No |
| `SubagentStop` | A subagent finishes | Yes |
| `TaskCreated` | A task is created | Yes |
| `TaskCompleted` | A task is marked complete | Yes |
| `Stop` | Claude finishes responding | Yes |
| `StopFailure` | The turn ends because of an API error | No |
| `TeammateIdle` | An agent-team teammate goes idle | Yes |
| `InstructionsLoaded` | CLAUDE.md and `.claude/rules/*.md` are loaded | No |
| `ConfigChange` | Configuration changes mid-session | Yes |
| `CwdChanged` | The working directory changes | No |
| `DirectoryAdded` | A directory is added via `/add-dir` | No |
| `FileChanged` | A watched file changes on disk | No |
| `WorktreeCreate` | A worktree is being created | Yes (any non-zero aborts) |
| `WorktreeRemove` | A worktree is being removed | No |
| `PreCompact` | Before context compaction | Yes |
| `PostCompact` | After context compaction | No |
| `PreModelSwitch` | Before a model switch is applied | Yes |
| `PostModelSwitch` | After the model changes | No |
| `Elicitation` | An MCP server requests user input | No |
| `ElicitationResult` | The user responds to an MCP elicitation | No |
| `SessionEnd` | The session terminates | No |

## Input payload

Every hook receives JSON on stdin. Fields present on all events:

```json
{
  "session_id": "string",
  "prompt_id": "uuid, null until the first user input",
  "transcript_path": "path to the conversation JSON",
  "cwd": "string",
  "permission_mode": "default | plan | acceptEdits | auto | dontAsk | bypassPermissions",
  "effort": { "level": "low | medium | high | xhigh | max" },
  "hook_event_name": "string",
  "agent_id": "string, subagents only",
  "agent_type": "string, subagents or --agent"
}
```

Event-specific fields are added on top. `PreToolUse` and `PostToolUse` add
`tool_name`, `tool_input`, and `tool_use_id`. `Notification` adds `message`.

Read the file path defensively — different tools use different keys:

```bash
hook_field '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path'
```

## Output payload

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow | deny | ask",
    "permissionDecisionReason": "string",
    "additionalContext": "string",
    "updatedInput": {},
    "continue": true,
    "retry": true
  },
  "systemMessage": "shown to the user",
  "terminalSequence": "ANSI escape, for a bell or window title"
}
```

- `permissionDecision` — tool and permission events, and blocking events.
- `additionalContext` — events in the standard decision model. Injects text into the conversation.
- `updatedInput` — `PreToolUse` and `UserPromptSubmit` only. Rewrites the tool arguments in place.
- `continue` — some events, notably `Stop`.
- `retry` — `PermissionDenied` only.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Proceed. stdout is parsed as JSON when it is valid JSON, otherwise treated as text. |
| 2 | Block, on events that support blocking. The reason comes from `permissionDecisionReason`, else stderr. |
| anything else | Non-blocking error. **The action still happens.** |

Exit 2 does **not** block `PermissionRequest`, `StopFailure`, `PostToolUse`, or
`PostToolUseFailure`. On the two `PostToolUse` events, stderr is still shown to
Claude even though the tool already ran, which is how you ask Claude to clean up
after itself.

For `SessionStart`, `UserPromptSubmit`, `UserPromptExpansion`, and
`PostModelSwitch`, plain-text stdout on exit 0 is added to the conversation as
context — useful for a quick hook where full JSON is overkill.

## Timeouts

Default 600s, but 30s for `UserPromptSubmit` and `PreModelSwitch`, and 10s for
`MessageDisplay`. On timeout the output is discarded and the action proceeds
(except `PreModelSwitch`, which blocks). Set an explicit `timeout` per hook.

## Path placeholders

| Placeholder | Resolves to |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}` | The plugin's install directory. Changes on every plugin update. |
| `${CLAUDE_PLUGIN_DATA}` | Persistent plugin state that survives updates. |
| `${CLAUDE_PROJECT_DIR}` | The project root where the session started. Constant across worktrees. |

All three are substituted into `command` and `args`, and exported as environment
variables on the spawned process.
