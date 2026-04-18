---
name: retro
description: Facilitate a team retrospective — gather the data from a sprint or timeframe, structure the discussion, and produce concrete action items. Use when the user types /retro, is running a retrospective, or asks to reflect on a sprint or project.
---

# Retrospective Facilitator

Run a retro that produces action, not catharsis. A retro without decisions is a venting session.

## Step 1 — Scope the retro

Ask the user:

1. **What timeframe?** (last sprint, last release, last incident, a quarter)
2. **Who's on the team?** (just to calibrate — you don't need names, just count and roles)
3. **What format do they want?** Default is "What went well / what didn't / what to change", but offer:
   - **Start / Stop / Continue** — good for teams that want behavior changes
   - **4Ls** (Liked / Learned / Lacked / Longed for) — good for projects ending
   - **Sailboat** (Wind / Anchors / Rocks / Island) — good for teams who want metaphor
   - **Timeline** — good after incidents or launches

If they don't care, pick "Went well / didn't / change" — it's the most broadly useful.

## Step 2 — Pull the data

For a sprint/timeframe retro, gather context *before* the discussion. Run in parallel:

- `git log --since="<start>" --until="<end>" --oneline --all` — what shipped
- `git log --since="<start>" --until="<end>" --merges --oneline` — merged PRs
- If `gh`: `gh pr list --state merged --search "merged:>=<start>"` — PR activity
- If `gh`: `gh issue list --state closed --search "closed:>=<start>"` — closed issues

Summarize: X commits from Y authors, Z PRs merged, W issues closed. This is the factual ground — everything else is interpretation.

## Step 3 — Prompt for each category

For whichever format was picked, give the user specific, pointed prompts — not generic ones. Generic prompts get generic answers.

For "went well / didn't go well / change":

**Went well:**
- What shipped that you're proud of?
- What did the team do that you'd want to repeat?
- Where did you move faster or better than expected?
- What helped when things got hard?

**Didn't go well:**
- What took longer than it should have, and why?
- What surprised you (outage, scope creep, miscommunication)?
- Where did the team drop the ball — and where did the process set them up to drop it?
- What did you see someone else struggle with that wasn't addressed?

**Change:**
- One thing the team should start doing.
- One thing the team should stop doing.
- One experiment to try next sprint.

Wait for the user to respond to each prompt. Don't dump all prompts at once.

## Step 4 — Extract themes, not just items

Once you have the raw inputs, group them:

- Are three of the "didn't go well" items really about the same root cause (e.g. poor scoping, slow reviews, flaky CI)?
- Is a "went well" actually hiding a risk (e.g. "the hero mode got us through" means someone burned out)?

Write 2–4 themes with 1-line summaries. Themes beat laundry lists for driving change.

## Step 5 — Produce action items

Every retro should end with **at most 3 action items**. More than 3 and none will get done.

Each action item must have:

- **What** — specific behavior change or experiment
- **Who** — who owns it (person or role, not "the team")
- **When** — by when
- **How we'll know** — what success looks like next retro

Example:
> **Action:** Move deploy discussions to async (Slack thread) instead of at standup.
> **Owner:** Priya (EM)
> **When:** Starting next sprint.
> **How we'll know:** Standup average duration back under 15 min.

## Output format

```
# Retro — <timeframe>

## Context
- <N> commits, <N> PRs merged, <N> issues closed
- Other notable events (launches, incidents, people)

## What went well
- ...

## What didn't go well
- ...

## Themes
- <Theme 1>: 1-line summary
- <Theme 2>: ...

## Action items (max 3)
1. **<action>** — owner, when, how we'll know
2. ...
```

## Calibration

- **Push past surface causes.** "CI was slow" is a symptom. "We've been deferring the CI cache fix for two sprints" is the cause. Ask "why" once more than feels polite.
- **Don't let every item become an action.** Most "didn't go well" items are context to remember, not problems to fix. Save actions for the 2–3 highest-leverage changes.
- **Write actions the team would bet on.** An action item nobody believes in is worse than no action — it trains the team that retros are performative.
- **Check last retro's actions.** If the user has notes from the last retro, ask what happened with those actions first. Un-closed loops are the best predictor of what's still broken.
