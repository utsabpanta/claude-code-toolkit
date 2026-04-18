---
name: commit
description: Stage appropriate files and create a well-formed commit with a message that explains why, not just what. Use when the user types /commit, says "commit this", or wants to commit staged work.
---

# Smart Commit

Produce a commit a reviewer 6 months from now will thank you for — one that explains the *why*, references the right thing, and doesn't bundle unrelated changes.

## Step 1 — Check state

Run in parallel:

- `git status` — what's modified, staged, untracked
- `git diff --cached` — what's already staged
- `git diff` — what's unstaged
- `git log -5 --oneline` — to match the repo's commit-message style

Do **not** run `git add .` or `git add -A`. That's how secrets get committed.

## Step 2 — Decide what goes in this commit

If nothing is staged yet, look at what's changed and decide what belongs together. A commit should be one logical change. If the diff contains two unrelated changes (a bug fix and a refactor), propose splitting into two commits.

Ask the user if it's ambiguous — don't guess. Show them:

```
I see changes in:
  - src/auth/session.ts      (fix logout race)
  - src/billing/invoice.ts   (unrelated typo fix)
  - test/auth/session.test.ts (tests for the fix)

I'd commit the auth fix + its test as one commit, and the typo fix separately. OK?
```

Stage files explicitly by path (`git add src/auth/session.ts test/auth/session.test.ts`), never with wildcards that could catch unintended files.

## Step 3 — Screen for secrets

Before committing, scan the staged diff (`git diff --cached`) for:

- Hardcoded tokens, API keys, passwords
- `.env` files (block entirely — ask the user before proceeding)
- Large binary or generated files that shouldn't be versioned

If you spot anything suspicious, stop and ask.

## Step 4 — Write the message

Match the repo's style first. Check `git log` — is this repo using:

- **Conventional Commits** (`feat:`, `fix:`, `chore:`, `refactor:`)?
- **Issue-tagged** (`[PROJ-123] Fix logout`)?
- **Free-form but consistent** (imperative mood, no period)?

Follow what you see. If there's no clear convention, default to:

```
<short subject in imperative mood, ≤ 72 chars>

<blank line>

<body, wrapped at ~72 chars, explaining WHY this change is needed,
what alternative was considered, or what surprise a future reader
might hit. Skip the body if the subject is self-sufficient.>

<blank line>

<optional footer: issue refs, co-authors, breaking change notes>
```

Rules:

- **Subject in imperative mood.** "Fix X" / "Add Y", not "Fixed" or "Adds".
- **No period at the end of the subject.**
- **The subject is a standalone line.** If you need more, use the body.
- **The body explains WHY.** The diff shows what. Don't repeat the diff in prose.
- **Reference the issue if relevant.** `Fixes #123` in the footer closes it on merge.
- **Skip the body when the subject really says it all.** Don't pad.

## Step 5 — Commit

Use a heredoc to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Fix logout race when session is expiring

The logout handler was racing with the token refresh job. If a
user hit logout within the 10-second refresh window, the refresh
would re-create the session cookie after logout cleared it.

Fixed by taking the session lock before clearing cookies. Added
a test that reproduces the race by triggering refresh and
logout concurrently.

Fixes #412
EOF
)"
```

After committing, run `git status` to confirm the commit landed and show the user the result.

## Rules

- **Never pass `--no-verify`.** If the pre-commit hook fails, that's a signal — investigate, don't bypass.
- **Never `--amend` without asking.** Amending changes history and can lose work.
- **Never `git add .` or `git add -A`.** Stage files by name.
- **If the hook fails, fix the issue and make a NEW commit** (not `--amend`) — the failed commit didn't happen.

## Output

Show the user:
- What you staged
- The commit message
- The resulting `git status`

That's it. No "ready to push!" flourish — pushing is a separate decision.
