---
name: explain
description: Explain a piece of code, concept, or system at the right level of depth — calibrated to the user's stated background and question. Use when the user types /explain, asks to understand code, or says they're confused.
---

# Explain

A good explanation isn't the most complete one — it's the one that fits the question. Your job is to figure out what the user actually wants, then answer at that depth.

## Step 1 — Find out what they're really asking

"Explain this" can mean five different things:

1. **"What does this code do?"** — behavior
2. **"Why is this written this way?"** — rationale / history
3. **"How does this work internally?"** — mechanism
4. **"How do I use this?"** — API / interface
5. **"What's this concept?"** — theory / general knowledge

Ask one question if it's genuinely unclear. Something like:

> "You mean: what does this code actually do, why it was written this way, or how it fits into the larger system?"

Don't pepper the user with questions — pick the most useful one.

## Step 2 — Calibrate to their level

Ask (or infer from prior messages):

- **"How familiar are you with [language/framework/domain]?"** — new / some experience / comfortable

A senior Rust engineer asking about tokio internals gets a completely different answer than a Python dev who just opened their first Rust file. If you misjudge, the user will either be bored or lost — and won't always tell you.

When in doubt, ask a one-line clarification. It saves both of you time.

## Step 3 — Read the actual thing

Never explain from general knowledge alone when the code is right there. Read the specific file, function, or module. Check imports, check callers, check tests. The concrete answer beats the textbook answer.

If the user pointed at a file or symbol, follow it:
- Read the file
- Grep for callers (so you can say "this is called from X and Y")
- Read the tests (they encode intent)

## Step 4 — Structure the explanation

Default structure — adapt to the question:

```
## What it does (one sentence)
The one-liner a coworker would ask about at standup.

## How (the mechanism)
As much depth as the question needs — no more.
Include concrete file:line references.

## Why (when relevant)
If the design is non-obvious, explain the rationale.
"This is written this way because..." — but only if you actually know.
Don't invent history.

## How to use it (when relevant)
API / interface section for library-like code.
Short code example.

## Caveats
Edge cases, gotchas, known issues. Only include if real.
```

Skip any section that's not relevant. A question about "what does this function return" might warrant a single sentence, not a structured breakdown.

## Step 5 — Use concrete examples

Abstract explanations are forgettable. Code examples make things stick:

- Instead of "it normalizes the input", show the input and the output.
- Instead of "handles the edge case", say "if the input is empty, it returns `null` instead of throwing".
- Instead of "uses a pipeline pattern", show the sequence of transformations.

## Step 6 — Point at the source

End with explicit file:line references so the user can jump to the code. If you're explaining a pattern that appears in multiple places, point to 2-3 examples, not all of them.

## Anti-patterns — avoid these

- **Explaining at textbook level when the specific code is the question.** "A for-loop iterates over..." when the user wants to know why *this* loop is there.
- **Dumping everything you know.** Answer the asked question; offer to go deeper.
- **Inventing rationale.** If you don't know *why* something was written a certain way, say "not sure — git log might have context" rather than guessing confidently.
- **Using jargon without defining it.** If you must use a term the user might not know, define it in one clause on first use.
- **Assuming the code is good.** Sometimes the right explanation is "this is confusing because it's poorly written — here's what it's trying to do."
- **Long preambles.** Skip "Great question! Let me explain..." — just explain.

## When the code itself is broken or unclear

Sometimes the honest explanation is: "This is hard to follow because [reason]. I *think* it's doing X, based on Y, but the structure obscures it." That's a real answer — more useful than a fabricated tidy explanation.

## Output tone

Match the user's register. Terse user → terse answer. Curious user exploring → more exposition. Teaching context → deliberate, paced.

If you realize mid-explanation that you don't actually know something, stop and say so. The user will trust you more.
