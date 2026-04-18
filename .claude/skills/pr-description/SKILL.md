---
name: pr-description
description: Generate a pull request title and body for the user's current branch based on its commits and diff. Use when the user types /pr-description, asks to draft a PR, or is about to open a pull request.
---

# PR Description

Write a PR description a reviewer can load quickly: what changed, why it changed, how to verify.

## Step 1 — Gather the facts

Run these in parallel:

- `git branch --show-current` — branch name (often encodes intent)
- `git log <base>..HEAD --oneline` — every commit on this branch
- `git log <base>..HEAD` — full commit bodies (often the best source of "why")
- `git diff <base>...HEAD --stat` — which files changed and how much
- `git diff <base>...HEAD` — the actual diff (skim, don't memorize)

Where `<base>` is the branch this will merge into — usually `main` or `master`. Confirm with `git remote show origin | grep HEAD` if unsure.

If the branch has a linked issue (e.g. `feature/PROJ-123-foo`), note the issue ID.

## Step 2 — Find the "why"

The hardest part of a PR description is explaining *why*, not *what*. Look for it in:

1. Commit messages (especially the first commit and any that say "Fix" or "Add")
2. Issue ID in the branch name — if the user has `gh` installed and an issue is linked, `gh issue view <id>` is gold
3. Code comments added in the diff
4. The change itself: what problem would this solve? What was broken or missing before?

If you genuinely can't tell why, ask the user in one sentence rather than inventing a reason.

## Step 3 — Write it

Use this structure. Keep it tight — reviewers hate walls of text.

```
## Summary
2–4 sentences. What this PR does and why. First sentence should stand alone as a commit message.

## Changes
- Bullet list of the notable changes, grouped logically (not one per commit)
- Each bullet is a *change*, not a *file* — "Switch auth to JWT" not "Update auth.ts"
- Skip trivial bullets ("fix typo", "update imports") unless that's the whole PR

## Test plan
- [ ] Concrete steps or commands a reviewer can run to verify
- [ ] Include both the happy path and at least one edge case
- [ ] If this is covered by automated tests, say which tests and how to run them

## Notes for reviewer
Anything the reviewer should know: tradeoffs, follow-ups you're deferring, areas you're unsure about, migration ordering, etc. Omit this section if there's nothing to say — don't fill space.
```

For the **title**:

- Under 70 characters.
- Imperative mood ("Add X", "Fix Y", not "Added" or "Adds").
- Include the issue ID if there is one: `[PROJ-123] Add X`.
- No trailing period.

## Calibration

- **Don't list every commit.** The reader can see the commit history. Group by logical change.
- **Don't describe the diff line by line.** Describe the *behavior* change.
- **Don't invent a test plan.** If you didn't actually see tests, the test plan should say "manual verification: <steps>" not "all tests pass".
- **Match the repo's style.** If the repo has a PR template (`.github/pull_request_template.md`), read it and follow it instead of this structure.

## Output

Print the title on its own line, then a blank line, then the body. Don't wrap in code blocks unless the user asks — they'll copy-paste.

Do **not** actually run `gh pr create` unless the user explicitly asks. This skill drafts; the user ships.
