---
name: Propose a new guardrail
about: Something Claude does that should be caught
title: 'guard: <what it should catch>'
labels: enhancement, hooks
---

## What should be caught

## Why it matters

What goes wrong when it is not caught? Has it happened to you?

## Deny or ask?

`deny` is for things that are never intended and unrecoverable. `ask` is for
things that are legitimate but destroy work.

## Which event

`PreToolUse` is the only one that can prevent an action.

## False positives

What legitimate usage looks similar, and how a hook would tell them apart?
