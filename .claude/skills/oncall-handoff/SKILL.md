---
name: oncall-handoff
description: Generate an on-call handoff note — what happened during the shift, what's still open, what to watch for. Use when the user types /oncall-handoff, is ending their on-call shift, or asks to write a handoff.
---

# On-Call Handoff

Handoff notes are a contract: the outgoing engineer takes on the work of the incoming one. A good handoff saves the next person 30 minutes of scramble; a bad one makes them start from scratch.

## Step 1 — Gather the shift's activity

Ask the user for the shift boundaries (e.g. "last 7 days", "since Monday 9am"), then gather what you can automatically:

- **Alerts fired** — if the user has an alert tool query, run it. Otherwise ask.
- **Incidents opened/closed** — same.
- **PRs merged into main that might have deployed** — `git log --since="<date>" --first-parent main --oneline`.
- **Anything they explicitly worked on** — ask.

Don't pretend to have data you don't. If you can't query the alerting system, say "you'll need to fill in the alert summary."

## Step 2 — Classify each event

For each alert, incident, or anomaly that happened during the shift, decide:

- **Resolved, no action needed** — alert fired, self-recovered, understood why
- **Resolved, follow-up filed** — alert fired, fixed or mitigated, ticket for permanent fix
- **Mitigated but open** — currently stable via a temporary fix; still needs real fix
- **Ongoing** — the next on-call is inheriting this *live*
- **Unexplained** — alert fired, cleared, we don't know why (important to flag)

The "mitigated but open" and "unexplained" categories are where bad handoffs fail — people forget to mention them.

## Step 3 — Surface the watch-list

What should the incoming engineer keep a closer eye on than usual? Candidates:

- Services with a recent deploy that's still "soaking"
- Known-flaky alerts not worth re-tuning yet
- A customer escalation that might re-surface
- A holiday traffic pattern starting this week
- A scheduled maintenance window during their shift

Keep it short. Every item must be actionable — "watch the cache layer" is useless without "because deploy #4321 changed eviction and we haven't confirmed it's stable under peak".

## Step 4 — Link the runbooks

If any known issue is likely to recur, link (or name) the runbook:

> "If the `checkout_latency_p95` alert re-fires, see runbook at `docs/runbooks/checkout-latency.md` — fix is usually to restart the pricing worker."

This is where a good team's on-call gets 10x better: the handoff points to *prior knowledge*, so the next person doesn't rediscover the same fix.

## Step 5 — Write it

Use this structure:

```markdown
# On-call handoff — <date range>
**Outgoing:** <name>  **Incoming:** <name>

## TL;DR
2-3 sentences. Was the shift quiet / busy / on fire? What's the #1 thing
the next person needs to know?

## Still open (action required)
Things the incoming person inherits *live*. Each one:
- **What** — one line
- **Where** — link/dashboard/ticket
- **Status** — mitigated? investigating? stuck on?
- **Next step** — what the incoming person should do first

## Watch list
Things to keep an eye on, not to act on immediately. Each one:
- **What to watch** — metric, customer, system
- **Why** — what might happen
- **What to do if it does** — runbook link or brief fix

## Resolved during shift
Short list. Don't dump every alert. Call out anything *interesting* —
something that almost went wrong, or that changed your understanding
of the system.

## Unexplained
Alerts or anomalies that fired and cleared, where we don't know why.
Even one line each — someone might recognize the pattern.

## Housekeeping
Open PRs, pending deploys, customer comms due, anything admin.
```

## Calibration

- **Length should match the shift.** A quiet shift gets a 5-line handoff. A rough shift gets detail.
- **Specificity beats completeness.** One specific "watch deploy #4321" beats five vague "watch infrastructure".
- **Name the stakes.** "Customer X is watching this — they'll escalate if it re-fires" tells the next person why it matters.
- **Don't editorialize.** "This alert is stupid" isn't useful. "This alert fires on every deploy and clears in 30s — we should retune" is actionable.
- **End the note with a time you're available.** If they have questions in the first hour of their shift, when can they reach you?

## Output

Print the handoff as Markdown. If the team has a specific handoff template (check `docs/oncall/` or similar), use that instead of this structure.
