---
name: A hook is not blocking
about: A guardrail fires but the action still happens
title: 'guard-<name> does not block <action>'
labels: bug, hooks
---

## Which hook

`guard-...`

## What you ran

Paste the payload and the hook's response:

```bash
echo '{"hook_event_name":"PreToolUse","tool_name":"...","tool_input":{...}}' \
  | plugins/guardrails/hooks/guard-....sh; echo "exit=$?"
```

Output:

```
```

## Expected

A `permissionDecision` of `deny` or `ask`, or exit code 2.

## Environment

- `claude --version`:
- OS:
- `jq --version`:
- Installed via: plugin / install.sh / cherry-pick
