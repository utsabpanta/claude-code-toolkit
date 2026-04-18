---
name: user-story
description: Turn a feature idea or customer request into a well-formed user story with acceptance criteria and open questions. Use when the user types /user-story, asks to write a user story, or describes a feature they want to spec.
---

# User Story

Produce a story a team can actually build from — not a vague wish. A good user story is small enough to fit in a sprint, clear enough that two engineers reading it would build the same thing, and honest about what's still unknown.

## Step 1 — Extract the core

From whatever the user gave you (a sentence, a customer email, a half-written ticket), pull out:

1. **The user** — who is this for? Be specific: "paid admin user", not "user".
2. **The action** — what do they want to do?
3. **The value** — why? What gets better for them?

If any of these is missing or fuzzy, ask. Don't fill in the blanks from your imagination — guessing the "why" is how products end up building the wrong thing.

## Step 2 — Write the story

Use the canonical form:

> **As a** [specific user], **I want to** [action], **so that** [value].

One sentence. If you need two, the story is too big — split it.

## Step 3 — Write acceptance criteria

These are the conditions that must be true for the story to be "done". Write them so QA and engineering both know when they've hit the bar.

Format each as **Given / When / Then** (or a plain checklist if the team prefers):

```
- Given [starting state], when [action], then [observable result].
```

Rules:

- **Observable.** "The API should be fast" is not testable. "Response returns in under 500ms at p95" is.
- **Specific.** "Handles errors gracefully" is not specific. "Shows an inline error message with retry button" is.
- **Cover the unhappy paths.** What if the input is invalid? What if the service is down? What if the user has no permission?
- **Include the empty and first-time states** if this is user-facing.

Most stories need 3–7 criteria. More than 10 usually means the story should be split.

## Step 4 — List open questions

Flag anything you don't know. This is often the most valuable part — it's what the team should figure out *before* estimating, not during implementation.

Examples:
- "Should this be visible to free-tier users or paid only?"
- "What happens to existing records when this field is added?"
- "Is there a design mock, or do we need one?"
- "Does legal need to sign off on the new data being stored?"

## Step 5 — Estimate size (rough)

Give a t-shirt size (XS / S / M / L / XL) and a one-line rationale. Not story points — those are team-calibrated. This is a sanity check: if the story is L or XL, suggest splitting.

## Output format

```
## Story
As a [user], I want to [action], so that [value].

## Acceptance criteria
- Given..., when..., then...
- ...

## Out of scope
What this story does NOT include. Helps prevent scope creep.

## Open questions
- ...

## Size
M — rationale.
```

## Calibration

- **Don't invent technical details.** "Use Redis for caching" is not a user story, it's an implementation choice. Keep the story about user-observable behavior.
- **Don't hide uncertainty.** If three things are unclear, list three open questions. A story that looks definitive but isn't will waste the team's time.
- **Match the team's template.** If the repo or a nearby doc has a story template, use it. This skill's format is a sensible default, not a mandate.
