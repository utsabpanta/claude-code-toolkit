---
name: standup
description: Draft standup notes from the user's recent git activity and context. Use when the user types /standup, asks for standup notes, or asks "what did I do yesterday?".
---

# Standup Notes

Draft a three-part standup: yesterday, today, blockers. Tight and honest — standups are not status reports.

## Step 1 — Gather yesterday's activity

Run in parallel:

- `git log --author="$(git config user.email)" --since="yesterday" --until="today" --all --oneline`
- `git log --author="$(git config user.email)" --since="yesterday" --until="today" --all --stat` — for more detail if needed
- `git branch --show-current` — what they're on now
- If `gh` is available: `gh pr list --author @me --state all --search "updated:>=$(date -v-1d +%Y-%m-%d)"` — PR activity

If the user works across multiple repos, they should run this from each or provide the list. If there was no Friday activity and it's Monday, extend to "since last Friday".

## Step 2 — Summarize yesterday

Translate commit activity into human updates. Group related commits — don't list every commit as a separate line.

- "Landed the auth refactor" beats "4 commits on auth.ts, 3 on middleware.ts"
- "Reviewed 3 PRs and caught a regression in the billing flow" beats silence on non-commit work
- If there are *no* commits, say what they did instead ("pairing on X", "debugging Y", "in meetings about Z") — ask if you don't know

Ask the user for **non-code work** — meetings, reviews, research, on-call, blocked on others. Git history doesn't capture these and they matter.

## Step 3 — Plan today

Ask the user what they plan to work on today, or infer from:
- In-progress branch (if not merged)
- Open drafts / WIP commits
- Tickets assigned to them (if tooling is available)

Keep it to 1–3 concrete items. "Working on stuff" is not a plan.

## Step 4 — Surface blockers

This is the most important part of standup — the rest is context. Ask explicitly:

> "Anything blocking you? Waiting on a review, a decision, an answer, a deploy, an env issue?"

If the user has nothing blocking, write "None" — don't fill space.

## Output format

```
**Yesterday**
- ...

**Today**
- ...

**Blockers**
- ... (or "None")
```

Keep the whole thing under ~10 lines. If it's longer than that, you're writing a status report, not a standup.

## Calibration

- **Prefer outcomes over activity.** "Shipped the export feature" beats "Worked on exports".
- **If a task is dragging into a second day,** say so explicitly ("still on the migration — hit X, need Y"). That's useful signal, not weakness.
- **Don't invent progress.** If the user genuinely didn't get much done yesterday, the notes should reflect that honestly — that's data the team needs.
- **Respect the team's format.** If the user's team uses a different template (emoji, sections, Jira links), ask and adopt it.
