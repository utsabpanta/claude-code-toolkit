---
name: migration-review
description: Review a database migration for safety — lock risk, rollback, backfill correctness, and compatibility with in-flight code. Use when the user types /migration-review, is about to ship a schema change, or asks if a migration is safe.
---

# Migration Review

Your job is to decide whether this migration is safe to run in production, and to say so plainly. Migrations are the class of change most likely to cause a real outage — treat this review accordingly.

## Step 1 — Find the migration

In order:

1. If the user named a file, use it.
2. Else look in the usual suspects: `migrations/`, `db/migrations/`, `prisma/migrations/`, `alembic/versions/`, `supabase/migrations/`, `flyway/`.
3. Check `git status` and `git diff` for newly added or modified migration files on this branch.

If you find more than one, ask which to review — or offer to review them in order.

## Step 2 — Understand the target table

Before judging the migration, understand what you're migrating:

- Row count (ask the user if unknown — "10K rows" and "500M rows" are different universes).
- Is it on the write path of a hot endpoint? Migrations that lock a hot table = outage.
- Are there foreign keys referencing it?
- Which services read/write it? `grep` the table name across the repo.

## Step 3 — Walk the rubric

Flag anything that matches. Lead with blockers.

### Locking / availability risks

- `ALTER TABLE ... ADD COLUMN` with a non-null default on a large table (many DBs rewrite the whole table).
- `ALTER TABLE ... ALTER COLUMN` type changes.
- Adding an index without `CONCURRENTLY` (Postgres) or equivalent.
- Adding `NOT NULL` to an existing column without a default or backfill.
- Adding a `UNIQUE` constraint on a populated column (does an exclusive lock).
- Foreign key additions on large tables (locks both sides).

### Data-loss risks

- `DROP COLUMN` or `DROP TABLE` on data that's still referenced by running code.
- Type narrowing (`VARCHAR(255)` → `VARCHAR(64)`) that could truncate.
- `UPDATE` / `DELETE` without a `WHERE` — or with one that's wrong.
- Renaming a column that's still read by the old code (two-phase required).

### Rollback

- Is there a `down` / reverse migration? Is it correct?
- If the migration is destructive (drops data), rollback is impossible — call that out.
- Irreversible migrations are sometimes fine, but must be deliberate.

### Compatibility with in-flight code

- Does the current deployed code still work after this migration runs, but before the new code deploys?
- Does the new code work against the old schema during rollout?
- Adding a required field the old code doesn't set = bugs. Prefer nullable → backfill → NOT NULL in three deploys.

### Backfill correctness

- Is the backfill run inline (blocks the migration) or out-of-band (safer but can skew)?
- Is the backfill idempotent? What happens if it's re-run?
- Is it batched? A `UPDATE big_table SET ...` with no `LIMIT` can lock for minutes.

### Index hygiene

- New indexes: are they actually used by a query? Check the relevant `WHERE` / `JOIN`.
- Dropped indexes: is any query still relying on them?

## Step 4 — Output

Produce this structure:

```
## Verdict
Safe to ship / Needs changes / Do not ship.

## Reasoning
One paragraph. What the migration does, on what table, at what scale.

## Blockers
Anything that could cause data loss, an outage, or break in-flight code.
Each: the line/statement, what goes wrong, suggested fix.

## Suggestions
Improvements that aren't blockers.

## Rollout plan
If the migration is multi-step safe (e.g. add nullable → backfill → enforce NOT NULL), spell out the sequence explicitly.
```

## Rules

- **Ask for the row count** if it's not obvious. "Safe" depends on it.
- **Prefer multi-step migrations** for anything touching a large or hot table. Split destructive changes across deploys.
- **If the user says "it's a small table, just ship it,"** still flag the pattern so they know it wouldn't be safe at scale.
- **Don't hand-wave with "be careful in production."** Name the specific failure.
