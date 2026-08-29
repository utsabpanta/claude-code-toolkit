# Examples

What this toolkit looks like in use. Responses are illustrative; the wording
will vary, the shape is what matters.

Read [concepts.md](concepts.md) first if "skill vs. agent" is still fuzzy.

---

## Guardrails

The flagship. These fire automatically once `guardrails` is installed. There is
nothing to type.

### A write to `.env` is refused

**Claude tries:** writing `DATABASE_URL` into `.env`

**What happens:** `guard-secrets.sh` returns a deny decision before the write.
Claude sees the reason and changes course:

```
I can't write to .env - the guardrails hook refuses modifications to
environment files, since they hold live credentials.

I've added the key to .env.example instead, with a placeholder:

  DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

Set the real value yourself with:

  echo 'DATABASE_URL=...' >> .env
```

The important part is the word *refused*. Before version 1.0.0 this hook printed
a nearly identical message and then wrote the file anyway, because it exited 1
instead of emitting a deny decision. See [hooks.md](hooks.md).

### A force push is refused

**Claude tries:** `git push --force origin main` after a rebase

```
Blocked by guard-force-push. Force-pushing rewrites remote history and can
destroy commits your teammates already pulled.

Your local branch has diverged from origin/main by 3 commits. Options:

  1. git pull --rebase origin main, then push normally
  2. Push to a new branch and open a PR
  3. If you're certain, run: touch ~/.claude/allow-force-push
     (valid once, for 10 minutes)
```

The override is deliberately external, time-boxed, and single-use, so the agent
cannot grant it to itself.

### A destructive command asks first

Two tiers. `rm -rf /`, `mkfs`, and `curl | sh` are denied outright. Things that
are legitimate but destroy work get an `ask`:

```
Claude wants to run: git reset --hard HEAD~3

  guard-destructive: git reset --hard discards every uncommitted change in
  the working tree. Confirm this is intended and that nothing valuable is
  unstaged.

  [y] Allow   [n] Deny
```

A guardrail that blocks `git reset --hard` outright gets uninstalled the first
afternoon someone needs it. That is why this one asks.

### A session starts with context already loaded

`context-brief.sh` runs on `SessionStart` and injects what Claude would
otherwise spend three tool calls discovering:

```
Repository state at session start: branch feat/billing-retry. 4 file(s) with
uncommitted changes. 2 commit(s) ahead of origin/feat/billing-retry.
Open PR for this branch: #218 Retry failed invoice webhooks (draft).
```

### Everything is written to an audit trail

`audit-log.sh` appends one JSON object per event to
`~/.claude/audit/<repo>.jsonl`. Nothing leaves the machine.

```bash
$ jq -r 'select(.tool=="Write") | "\(.ts) \(.target)"' ~/.claude/audit/my-app.jsonl | tail -3
2026-08-29T14:02:11Z /repo/src/billing/retry.ts
2026-08-29T14:05:43Z /repo/test/billing/retry.test.ts
2026-08-29T14:09:02Z /repo/CHANGELOG.md
```

Answering "what did Claude change in this repo last Tuesday" is a `jq` query.

---

## Auditing a setup you did not write

### `/harden-setup`

**You:** `/harden-setup`

**You get:**

```
## Does not do what it says
- .claude/hooks/block-writes.sh exits 1 when it detects a protected path.
  Exit 1 does not block a tool call: the message prints and the write
  proceeds. Fix: emit hookSpecificOutput.permissionDecision = "deny".

  Verified by running it:
    $ echo '{"tool_name":"Write","tool_input":{"file_path":"/x/.env"}}' \
        | .claude/hooks/block-writes.sh
    Blocked: refusing to modify env file
    exit=1        <- does not block

## Wrong file
- .claude/settings.json contains an "mcpServers" key. settings.json does not
  configure MCP servers; this block is ignored with no error. Move it to
  .mcp.json at the repo root.

## Too permissive
- permissions.allow includes Bash(curl:*), which permits fetching and
  executing remote code. Narrow it or remove it.

## Portability
- .claude/hooks/standup.sh uses `date -v-1d`, which is BSD-only and fails
  on Linux and in CI.

## Fine
- 6 other hooks, 4 skills, 2 agents checked with no findings.

Want me to fix the three errors? The first one is the one to do now: you
currently believe that hook is protecting you.
```

### `/permission-policy`

**You:** `/permission-policy` in a repo with Terraform and a deploy workflow

**You get:** a policy derived from the repo's actual scripts rather than a
generic list, starting from the `strict` profile because the repo can deploy:

```
This repo has terraform/ and a .github/workflows/deploy.yml that assumes an
AWS role, so I've started from strict.json rather than balanced.

Allowed without prompting (from your package.json scripts and Makefile):
  npm test, npm run lint, npm run typecheck, make integration-test
  plus 14 read-only git and filesystem commands

Ask first:
  git push, gh pr create, docker, terraform plan

Denied:
  terraform apply, terraform destroy, kubectl delete, gh pr merge,
  npm publish, force push (all four spellings), reads of .env and ~/.aws

One note: your existing deny list has Bash(git push --force:*), which does
not match `git push -f` or `git push origin +main:main`. I've listed all
three. The guardrails hook catches them by intent regardless, which is why
it exists alongside the permission rules.

Write this to .claude/settings.json and commit it?
```

---

## Skills

### `/migration-review`

**You:** `/migration-review` on a Postgres migration adding a NOT NULL column

**You get:**

```
## Blocking

1. ADD COLUMN status TEXT NOT NULL DEFAULT 'pending' on `orders`
   `orders` has ~40M rows. On PostgreSQL below 11 this rewrites the entire
   table under an ACCESS EXCLUSIVE lock - every read and write blocks for
   the duration, likely several minutes.

   Safe sequence, three deploys:
     1. ADD COLUMN status TEXT           (nullable, instant)
     2. Backfill in batches, then deploy code that writes it
     3. SET NOT NULL, after the backfill is verified complete

2. CREATE INDEX idx_orders_status ON orders(status)
   No CONCURRENTLY. This takes a write lock for the length of the build.
   Use CREATE INDEX CONCURRENTLY, and note it cannot run inside a
   transaction - your migration tool may wrap it in one by default.

## Rollback
The down migration drops the column. That is not reversible once written to.
Say explicitly whether losing that data on rollback is acceptable.

## Question
What is the row count on `orders` in production? My estimate came from the
staging dump and the lock duration scales with it.
```

### `/release-notes`

Handles both audiences from one commit range.

**You:** `/release-notes for the changelog`

```
Range: v2.3.1..HEAD (via git describe --tags --abbrev=0), 34 commits,
8 user-visible.

## [2.4.0] - 2026-08-29

### Added
- `--dry-run` on `import` to preview changes before applying. [#142]

### Changed
- Default request timeout raised from 5s to 30s for large imports.

### Fixed
- Crash when parsing empty CSV files. [#148]
- Uploads could silently fail under concurrent writes. [#151]

Dropped 26 commits as internal: refactors, test-only changes, CI, and
dependency bumps with no observable behavior change.
```

**You:** `/release-notes for customers`

Same range, different writing: "Search is roughly 10x faster on large
workspaces" rather than "Switched search to a trigram index."

### `/tldr`

**You:** `/tldr src/auth/session.ts`

```
- Manages server-side session state (creation, refresh, destruction) for the
  JWT auth flow.
- Exports createSession, refreshSession, destroySession - all take a Request
  and return Promise<Session>.
- Gotcha: destroySession requires the caller to hold the session lock. See
  #412, which fixed a race there.
```

---

## Agents

An agent runs in its own context window and reports back, which is what makes
it useful for a second opinion: it has no knowledge of what your main
conversation already concluded.

### `security-auditor`

**You:** "Have the security-auditor look at the new upload endpoint."

```
## Findings

### High - path traversal in the upload handler
src/api/upload.ts:34

  const dest = path.join(UPLOAD_DIR, req.body.filename)

`filename` comes straight from the request. A value of
`../../../etc/cron.d/x` escapes UPLOAD_DIR. Reachable: this is an
authenticated route, but any logged-in user can reach it.

  Fix: const dest = path.join(UPLOAD_DIR, path.basename(req.body.filename))
  and verify the resolved path is still inside UPLOAD_DIR.

### Medium - no size limit
src/api/upload.ts:28
Multer is configured without `limits`. A single request can exhaust disk.

## Not checked
- The S3 upload path (src/api/upload-s3.ts) - it was not in the diff.
- Authentication itself. I assumed requireAuth works as named.
```

The "Not checked" section is deliberate. An audit that does not say what it
skipped is easy to over-trust.

### `sql-reviewer`

**You:** "Ask sql-reviewer about this query."

```
## Correctness

  WHERE user_id NOT IN (SELECT owner_id FROM teams)

`teams.owner_id` is nullable. If any row has a NULL owner_id, NOT IN returns
zero rows for every input - the query silently returns nothing. Use
NOT EXISTS, or add `WHERE owner_id IS NOT NULL` to the subquery.

## Performance
The LEFT JOIN on `audit_log` is degraded to an INNER JOIN by
`WHERE audit_log.action = 'delete'` in the outer WHERE clause. If you meant
to keep unmatched rows, move that predicate into the ON clause.
```

---

## Output styles

Switch with `/output-style <name>`.

**Default:** "I'll take a look at the authentication module. Let me start by
reading the session handling code to understand the current flow..."

**`terse`:** *(reads the file immediately, then)* "Race between refresh and
logout. session.ts:88 clears the cookie after refresh re-creates it. Fix: take
the lock before clearing."

**`senior-reviewer`:** "Before I read this - what happens when two tabs refresh
simultaneously? Your fix assumes a single refresh in flight. Have you checked
that assumption?"

**`teacher`:** "This is a race condition, which is worth understanding rather
than just patching. Two operations touch the same state with no ordering
guarantee between them. Here, the refresh job and the logout handler both write
the session cookie..."

---

## Combining them

A realistic sequence for shipping a schema change:

1. `/migration-review` on the migration. It flags the missing `CONCURRENTLY`.
2. Fix it. `format-on-edit.sh` formats the file automatically.
3. `sql-reviewer` agent on the queries the migration enables.
4. `/release-notes` for the changelog entry.
5. Commit. `pre-commit-lint.sh` lints the staged files first and denies the
   commit if they fail.
6. `guard-force-push.sh` stops the reflexive `git push --force` after the
   rebase.

Steps 2, 5 and 6 happen without you asking. That is the difference between a
skill and a hook.
