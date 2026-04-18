---
name: api-design
description: Critique a new or changed API endpoint before it ships — contract, error shapes, pagination, versioning, auth. Use when the user types /api-design, is about to add an endpoint, or wants a sanity check on an API surface.
---

# API Design Review

Your job is to catch API mistakes while they're still cheap to fix. Once an endpoint has clients, every mistake is a migration.

> **Related:** this skill critiques a *new or changed endpoint's design* (shape, auth, pagination, error format). For detecting *breaking changes to an existing public API* (removed fields, renamed fields, narrowed types), use the `api-contract-guardian` agent instead.

## Step 1 — Find the endpoint(s)

- If the user named a file or route, start there.
- Else look at `git diff` for added/changed route handlers, OpenAPI/Swagger files, GraphQL schemas, or RPC definitions.
- Read the handler body AND any schema/DTO/validator it references.

If multiple endpoints are in scope, review them one at a time.

## Step 2 — Rubric

Walk this in order. Flag each issue as blocker / suggestion / nit.

### Contract

- Is the URL shape RESTful and predictable? `/users/:id/orders`, not `/getUserOrders?id=…`.
- Is the HTTP method right? `GET` reads, `POST` creates, `PUT`/`PATCH` update, `DELETE` deletes. No `GET` with side effects.
- Are path params vs. query params used sensibly? Identity → path. Filtering → query.
- Is the request body schema explicit and validated? Missing validation is a security issue, not just an ergonomics issue.

### Response shape

- Is the success shape consistent with other endpoints in this service? Envelope vs. bare object — pick one and match.
- Are timestamps ISO 8601 with timezone? Not epoch ints unless the rest of the API uses them.
- Are IDs returned as strings? (Large ints lose precision in JS.)
- Are nullable fields explicit, not omitted-when-null?

### Error shape

- Are errors structured (`{ error: { code, message, details } }`) or just string messages? Structured wins — clients can branch on `code`.
- Are HTTP status codes correct? 400 for bad input, 401 for missing auth, 403 for forbidden, 404 for not found, 409 for conflicts, 422 for semantic validation. Don't return 200 with `{ error: ... }`.
- Does the error message leak internals? Stack traces, SQL, file paths — all leaks.

### Pagination

- Any list endpoint without pagination is a bug waiting to happen. Say so.
- Cursor pagination > offset pagination for anything that changes. Offset skips/duplicates on writes.
- Is the page size capped server-side? `?limit=1000000` should be rejected or clamped.

### Auth & authz

- Who can call this? Is that enforced in the handler or assumed?
- Does authz happen *before* the expensive work (DB query, external call)?
- If the endpoint returns user data, does it check that the caller is allowed to see *that* user's data — not just "is authenticated"?
- Rate limits: is there one? Public endpoints without rate limits are DoS-by-accident waiting to happen.

### Versioning & compatibility

- If this changes an existing endpoint: is the change backwards compatible? Added fields = usually safe. Removed fields, renamed fields, changed types = breaking.
- How will clients know to migrate? Version in URL (`/v2/`), header, or content negotiation — whatever the rest of the API does.

### Idempotency

- Is the operation idempotent? If not, does it support an idempotency key (for `POST`/`PATCH`)? Network retries on non-idempotent writes = double-charged customers.

### Performance

- Does this endpoint do N+1 queries? (Loop over items, query per item.)
- Is the response size bounded? An endpoint that returns "all user's orders" with no pagination is a landmine.

## Step 3 — Output

```
## Summary
One line: endpoint, method, what it does, and your take (ship / fix first / discuss).

## Blockers
Issues that must be fixed before this ships to real clients.
Each: what's wrong — why it matters — suggested fix.

## Suggestions
Should do but won't break anything.

## Nits
Naming, consistency, minor shape cleanups.

## What's good
1–2 specific things done well.
```

## Rules

- **Match the existing API style** over theoretical purity. A second endpoint that disagrees with the first is worse than two that are both slightly off.
- **Always ask about pagination** on any list endpoint. Always.
- **Call out breaking changes loudly.** "This breaks existing clients" is a blocker unless there's a versioning story.
- **Don't lecture on REST philosophy.** Catch real problems.
