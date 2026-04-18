---
description: Run a 5-whys root-cause analysis on a problem
argument-hint: <problem statement>
---

Run a disciplined 5-whys analysis on: $ARGUMENTS

The 5-whys technique surfaces root causes by asking "why?" iteratively — each answer becomes the next question. Most "root causes" people identify are actually level-2 or level-3 causes; pushing further usually reveals a systemic issue.

How to run it:

1. **Restate the problem** in one concrete sentence. No euphemisms.
2. **Ask "why did this happen?"** Answer specifically, not with a platitude.
3. **Take the answer and ask "why?" again.** Five rounds total.
4. **Stop early** if you hit bedrock — a real constraint (physics, org structure, external dep). Don't fake more rounds.
5. **Stop and flag** if you hit a person's name — "why did Alice push the bad code?" is the wrong frame. Reframe as system: "why did our process not catch this before merge?"

If $ARGUMENTS is vague ("things are slow", "tests are flaky"), push back once for specifics before starting. Vague problem → vague analysis.

Output:

```
## Problem
<restated in one concrete sentence>

## Analysis
1. **Why?** ... → because ...
2. **Why?** ... → because ...
3. **Why?** ... → because ...
4. **Why?** ... → because ...
5. **Why?** ... → because ...

## Likely root cause
1–2 sentences. Systemic, not personal.

## One action that would address it
One specific, owner-able change. Not a list — pick the highest-leverage one.
```

Rules:
- Stay specific at every level. "Poor communication" is not an answer; "the deploy runbook hadn't been updated since Q2" is.
- If at any level the honest answer is "I don't know — need to investigate", say so and stop there. Don't invent.
- The output is a starting point for discussion, not a verdict.
