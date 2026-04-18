---
name: refactor-plan
description: Break a large refactor into small, safe, independently shippable steps — each with a clear commit boundary. Use when the user types /refactor-plan, describes a big refactor, or asks how to split up a change that's gotten too big.
---

# Refactor Plan

Your job is to turn "I want to change X everywhere" into a sequence of small PRs that each leave the codebase green. A good refactor plan is boring: every step ships; nothing is load-bearing on the next step.

## Step 1 — Pin down the goal

Before planning, get specific. Ask (or infer from context):

- **What's the end state?** Not "cleaner code" — something concrete like "all config is read from `Config` struct instead of env vars at call sites."
- **What's the motivation?** Performance? Testability? Removing a dependency? A coming feature that needs the new shape?
- **What's in scope, what's not?** Spell it out. Scope creep kills refactors.

If any of these are unclear, ask one clarifying question before planning.

## Step 2 — Map the surface

Find everything that will need to change:

- `grep` for the API, type, or pattern being replaced.
- Count the call sites. 10 sites and 500 sites lead to different plans.
- Identify natural boundaries: modules, layers, teams. A refactor that crosses a team boundary is two refactors.
- Find the tests. Untested code is the riskiest part of a refactor — note which call sites lack coverage.

## Step 3 — Design the step sequence

Good steps share these properties:

- **Each step leaves main green.** Tests pass, service runs, feature flag off.
- **Each step is independently revertable.** If step 3 is bad, reverting it doesn't force you to revert 1 and 2.
- **Each step is reviewable in under 30 minutes.** If it's bigger, split again.
- **The new API is introduced before old call sites migrate.** The old API stays working until the last migration lands.
- **The old API is removed only after the last call site is gone.** Verified by `grep`, not hoped for.

Prefer this shape for most refactors:

1. **Introduce the new shape** alongside the old. Nothing calls it yet. Tests for the new code.
2. **Migrate call sites in batches.** Group by module or team. One PR per batch. Each PR is mechanical.
3. **Delete the old shape** once `grep` confirms it's unused.

If the refactor needs a data migration or a breaking API change, insert those as their own steps with their own plans (see `/migration-review`).

## Step 4 — Output

Produce this structure:

```
## Goal
One sentence: what the end state looks like and why.

## Surface
- X call sites across Y files / Z modules.
- Tests: covered / partially / not at all.
- Risk areas: [list 1–3]

## Plan
Step 1: [title] — [one-sentence what]. [one-sentence why now]. Shippable: yes. Revertable: yes.
Step 2: ...
...

## Verification at each step
What command confirms the step is done and safe (tests, grep for old API, etc.)

## Exit criteria
How you know the refactor is complete. Usually: `grep` for old API returns nothing + no references in docs.

## Out of scope
Things someone might expect to be in this refactor, but aren't, and why.
```

## Rules

- **No step is "also fix X while we're here."** Unrelated fixes get their own PRs.
- **Name the feature flag** if the refactor needs one to stay safe during rollout.
- **Don't plan more than 7 steps at a time.** If you need more, plan the first 5 and re-plan after they land — reality will have changed.
- **If the refactor can't be broken down** (e.g. a type change that propagates everywhere), say so and propose how to minimize the blast radius.
