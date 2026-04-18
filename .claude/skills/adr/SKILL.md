---
name: adr
description: Draft an Architecture Decision Record (ADR) for a technical decision — context, options considered, decision, consequences. Use when the user types /adr, says they're making an architecture decision, or wants to document a tradeoff.
---

# ADR — Architecture Decision Record

Write a record that the next person to ask "why the hell did we do it this way?" will be grateful to find. Good ADRs are short, honest about tradeoffs, and dated.

## Step 1 — Find the repo's ADR convention

Before writing, check:

- `docs/adr/`, `docs/architecture/`, `adr/`, `architecture/`, `.docs/decisions/` — common locations
- Existing ADRs — match their numbering (`0001-title.md`, `ADR-001.md`) and structure

If the repo has no ADRs yet, default to `docs/adr/NNNN-kebab-title.md` and offer to create the directory.

## Step 2 — Gather the inputs

Ask the user, one question at a time if they're not provided:

1. **What decision?** One sentence — what's being chosen.
2. **What's the context?** What prompted the decision — a new requirement, a scaling issue, a tech debt problem, an incident?
3. **What options did you consider?** Minimum two; preferably three.
4. **What did you decide, and why?**
5. **What does this cost you?** Every decision has a downside. If you can't name one, you haven't thought hard enough.

If the user gives you a rushed answer to any of these, push back gently once. "You said you picked Postgres over DynamoDB because 'it's simpler' — is there a specific tradeoff you're accepting?"

## Step 3 — Write it

Use this structure (the canonical Nygard format, lightly updated):

```markdown
# NNNN. <Title — short, complete, decision-stated>

- **Status:** Proposed | Accepted | Superseded by NNNN | Deprecated
- **Date:** YYYY-MM-DD
- **Deciders:** <Names or roles>

## Context

What's the situation? What forces are at play (technical, business, team)?
Write it so someone new to the project could follow. 1–3 paragraphs.

## Decision

What we decided. One or two sentences. Start with "We will…".

## Options considered

For each option (minimum 2):

### Option A — <name>
- **How it works:** 1–2 sentences
- **Pros:** bullets
- **Cons:** bullets

### Option B — <name>
...

## Rationale

Why the chosen option over the others. What tradeoff we're accepting.
The most important section for the future reader — make it honest.

## Consequences

What becomes true because of this decision:
- Positive: ...
- Negative: ...
- Neutral: ...

## Follow-ups (optional)

Concrete things to do because of this decision (tickets to file,
docs to update, migrations to plan).
```

## Step 4 — Rules for good ADRs

- **One decision per ADR.** If you're documenting two, split.
- **Title states the decision, not the topic.** "Use Postgres for user data" beats "Database choice".
- **Date it.** Future readers need to know if the ADR is 3 weeks or 3 years old.
- **Status: Proposed first.** Only move to Accepted after the team signs off.
- **Name the rejected options specifically** — "we considered alternatives" is useless; "we considered DynamoDB and rejected it because…" is useful.
- **Be honest about the cons.** The point of an ADR is to prevent someone re-relitigating the same decision later — they need the real reasons, not marketing.
- **Don't hide uncertainty.** If the team is split or the decision is reversible, say so.

## Step 5 — Link it

If the decision relates to earlier ADRs, cross-reference them ("Supersedes ADR-0007", "Builds on ADR-0003"). If an ADR is being superseded, update the old one's status.

## Output

Write the file to `docs/adr/NNNN-<kebab-title>.md` (or the repo's convention). Print the path so the user can open it. Don't also paste the whole contents into the chat — it's in the file now.
