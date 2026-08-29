---
name: A guardrail is too aggressive
about: A hook blocks something legitimate
title: 'guard-<name> blocks <legitimate thing>'
labels: false-positive, hooks
---

## What was blocked

The exact command or file path:

```
```

## Why it is legitimate

## Which hook

`guard-...`

## Suggested fix

Should this be allowed outright, or moved from `deny` to `ask`? A guardrail that
blocks legitimate work gets uninstalled, so `ask` is often the right answer.
