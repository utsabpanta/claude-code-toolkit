---
name: code-review
description: Review the user's pending code changes (staged diff, a commit range, or a branch vs. main) against a principled rubric and produce a structured review. Use when the user types /code-review, asks for a code review, or asks you to look over a diff before they ship.
---

# Code Review

Your job is to produce a review that a senior engineer would be glad to receive — specific, prioritized, and easy to act on. Not a summary of the changes. A review.

## Step 1 — Identify what to review

Figure out the scope in this order:

1. **If the user named a ref** (e.g. "review my branch", "review vs. main"): diff `HEAD` against that ref.
2. **Else if there are staged changes** (`git diff --cached` non-empty): review staged changes.
3. **Else if there are unstaged changes**: review the working tree diff.
4. **Else**: diff the current branch against its merge-base with the default branch (`main` or `master`).

Run `git status` and `git diff <scope>` to see what you're reviewing. Also run `git log --oneline <scope>` so you understand the intent.

If the diff is larger than ~500 lines, tell the user and ask whether to proceed, narrow to specific files, or focus on a subset (e.g. "just the security-sensitive parts").

## Step 2 — Read the code in context

Don't review a hunk in isolation. For each changed file:

- Read the full file, not just the hunk, so you understand what the function/class is for.
- Check callers of any changed function (`grep` for its name) to spot breakage.
- If tests exist for this file, skim them — they encode the invariants.

## Step 3 — Apply the rubric

Check for issues in this order. Stop climbing the list as soon as you find a blocker; you can always add nits later.

1. **Correctness** — does this do what the commit message / PR title claims? Are edge cases handled (empty input, null, concurrent calls, large input)? Off-by-one? Wrong operator?
2. **Security** — SQL/command injection, XSS, missing authz, leaked secrets, unsafe deserialization, path traversal, SSRF. Input from users or the network is a red flag.
3. **Data integrity** — migrations that could lose data, changes to write paths without transactions, race conditions.
4. **Failure modes** — what happens if this network call times out? If this DB write fails halfway? Is the error surfaced or swallowed?
5. **Readability** — would a new team member understand this in six months without context? Are names honest? Are comments actually explaining *why*?
6. **Test coverage** — are the cases above actually tested? A test that only covers the happy path is a partial test.
7. **Consistency** — does this match existing patterns in the codebase, or does it reinvent something?
8. **Scope creep** — does the diff do more than the PR title suggests? Unrelated cleanup in the same PR makes it harder to review and revert.

## Step 4 — Write the review

Output in this exact structure:

```
## Summary
One paragraph: what the change does, and your overall take (looks good / needs changes / needs discussion).

## Blockers
Issues that must be fixed before merge. Each one: file:line, what's wrong, why it matters, suggested fix.
If none: write "None."

## Suggestions
Improvements worth making but not blocking. Same format.

## Nits
Style, naming, minor cleanups. Prefix each with "(nit)".

## What's good
One or two things done well. Not flattery — specific things you'd want to see repeated.
```

## Calibration

- **Be direct.** "This can lose data if the write fails after line 42" beats "you might want to consider error handling."
- **Quote the code.** When you flag an issue, include the 1–3 lines you're talking about so the user doesn't have to hunt.
- **Don't pad.** If there are no blockers, say so. A short review is a good review.
- **Don't review style the linter already catches** unless the user asked for a style review.
- **Don't suggest rewrites** unless you have a specific, demonstrable reason — "this is clearer" is not a reason.

If you would approve the PR with no changes, say so at the top of the Summary. Don't invent issues to look thorough.
