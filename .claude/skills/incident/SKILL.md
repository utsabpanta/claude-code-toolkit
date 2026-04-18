---
name: incident
description: Facilitate response to a live production incident — triage signals, keep a timeline, push for a mitigation path, write the postmortem when it's over. Use when the user types /incident, says "we have an incident", or asks help debugging a production problem under pressure.
---

# Incident Command

Incidents aren't the time for exploration. They're the time for tight loops: observe → hypothesize → act → observe. Your job is to keep the user in that loop and prevent the classic mistakes.

## Step 0 — Match the user's urgency

If this is active — systems are down, customers are affected — respond tight and fast. No preamble. No paragraphs of analysis. One question, one direction, one action at a time.

If the user is narrating past-tense ("we had an incident yesterday, help me write it up"), skip to the Postmortem section at the bottom.

## Step 1 — Get situational awareness

Ask fast, cheap questions to frame the problem:

- **What's broken?** (Symptom as a customer would describe it.)
- **When did it start?**
- **What changed recently?** (Deploy, config push, traffic spike, data change.)
- **Is it still happening?** (Or did it self-recover — which is often worse.)
- **What's the blast radius?** (All users, one region, one feature, one tenant.)
- **Is someone working on it yet?** (Avoid duplicate mitigations.)

Stop asking after 2-3 questions. If the user doesn't know, that's data. Move on.

## Step 2 — Start a timeline

From this moment, append to a timeline. Timestamp each entry (`HH:MM UTC`). This is what you'll need for the postmortem, and it keeps the team honest during the incident.

```
Timeline
14:03  Symptom: 500s on /api/checkout (reported by @priya)
14:05  Confirmed in dashboard: error rate 40%, started 14:00
14:07  Recent change: deploy of #4218 at 13:58
...
```

Ask the user to paste in facts, not interpretations. "10% error rate" is a fact. "Seems broken" is not.

## Step 3 — Separate mitigation from root cause

This is the #1 incident management mistake: hunting for root cause while the site is on fire. Always ask:

> **Is there a fast mitigation (rollback, feature flag off, scale up, failover) that stops the bleeding while we investigate?**

If yes — do it *first*. Understanding can wait. Customer impact can't. Flag this explicitly to the user if you sense they're diving into debug mode before mitigating.

Common mitigations:
- Rollback the most recent deploy
- Disable the affected feature via flag
- Route traffic away from the bad region
- Scale up the struggling service
- Circuit-break the downstream dep that's failing

## Step 4 — Form and test one hypothesis at a time

Once mitigation is underway (or impossible), form a hypothesis:

> "I think X is causing Y because Z."

For each hypothesis, pick the cheapest probe that would confirm or kill it:
- Logs for the affected path
- Recent deploy diff
- Dashboard for the suspected subsystem
- Query to count the affected rows

Update beliefs out loud after each probe. Don't let 3 hypotheses become 1 certainty without evidence.

## Step 5 — Know who to pull in

Ask:
- **Does someone else need to be on this?** (DBA, infra, security, the service owner.)
- **Does this need external communication?** (Status page, customer email, exec notification.)

If yes, push the user to do it *now*, not after resolution. Late comms are worse than over-comms.

## Step 6 — Declare resolved carefully

Before calling the incident over, confirm:
- ✅ Symptom is gone (check the dashboard, not just "seems fine")
- ✅ Root cause is known or isolated (even if the fix is temporary)
- ✅ Any temporary mitigations are tracked as follow-ups
- ✅ Customers who were affected have been updated (if relevant)

If any of those is missing, it's too early to resolve. Say so.

## Postmortem (when the fire is out)

A postmortem is not a villain hunt. It's a writeup of what happened and what the team will do so it's less likely next time.

Structure:

```markdown
# Postmortem: <short descriptor> — YYYY-MM-DD

## Summary (for execs who won't read the rest)
1 paragraph: what broke, who was affected, for how long, what fixed it.

## Impact
- Users affected: <number or %>
- Duration: HH:MM – HH:MM (N minutes)
- Services affected: ...
- Data loss / corruption: none / specify

## Timeline
Copy from the incident timeline, clean up.

## Root cause
What actually caused this — technically. One paragraph. Be specific —
"bad deploy" is not a root cause. "A migration added a NOT NULL column
without a default; the retry path tried to re-insert nulls on conflict" is.

## Why it wasn't caught earlier
What monitoring, test, review, or process should have caught this and didn't.
This is usually more useful than the root cause itself.

## What went well
Things that worked — fast rollback, good alerts, useful runbook. Not padding —
real lessons about what to preserve.

## Action items
Concrete, owned, time-bounded. No more than ~5 — scattered action items
don't get done. Each one:
- **What** — specific change
- **Owner** — person, not team
- **By when** — date
- **Ticket** — link

## What we're not doing (and why)
Things that might seem obvious but we're deliberately not pursuing. Why.
This is often the most debated section of a postmortem — get it on paper.
```

## Rules

- **No blame.** Incidents are system failures. An engineer who pushed a bad deploy isn't the "cause" — the absence of a safety net that would have caught it is.
- **Truth over tidiness.** A messy, honest postmortem is more valuable than a polished, sanitized one. Include the confusing parts.
- **Don't skip "what we're not doing".** Every incident spawns demands for 20 fixes; you'll do 5. Be explicit about the other 15.
- **Write the followups as tickets, not intentions.** An action item not captured in the tracker will not happen.
