---
name: release-notes
description: This skill should be used when the user asks to "write release notes", "update the changelog", "what changed in this release", "cut a release", or mentions CHANGELOG.md. It mines a commit range and writes for either a customer audience or a Keep a Changelog file.
allowed-tools: Bash(git:*), Bash(gh:*), Read, Edit, Write, Grep, Glob
---

# Release notes and changelog

Same source material, two audiences. Ask which one, or infer it: a request naming `CHANGELOG.md` wants the changelog form; a request about "the release" or "customers" wants the notes form. When both are wanted, write the changelog first and derive the notes from it.

| | Changelog | Release notes |
|---|---|---|
| Reader | Developers integrating or upgrading | Customers using the product |
| Format | Keep a Changelog, appended to a file | Standalone document or post |
| Includes | Every user-visible change, plus deprecations | The highlights, plus anything requiring action |
| Tone | Terse, factual, complete | Benefit-first, complete on breaking changes only |

Templates for both are in `references/formats.md`.

## Step 1 — Resolve the range

```bash
git describe --tags --abbrev=0            # the previous tag reachable from HEAD
git log --oneline "$(git describe --tags --abbrev=0)..HEAD"
```

Use `git describe --tags --abbrev=0`, **not** `git tag --sort=-v:refname | head -1`. In a monorepo the latter returns the newest tag globally, which may belong to a different package entirely — the single most common way this task produces a wrong answer.

If the user named a range, use it. If there is no tag at all, fall back to the first commit and say so. If the range is empty, tell the user; do not invent entries.

## Step 2 — Gather

```bash
git log <range> --no-merges --pretty=format:'%h %s%n%b%n---'
git log <range> --no-merges --stat --oneline | tail -40
```

If the repo uses GitHub and commits reference PRs, the PR body is usually a better source than the commit message:

```bash
gh pr list --state merged --search "merged:>=$(git log -1 --format=%cs "$(git describe --tags --abbrev=0)")" --json number,title,body
```

## Step 3 — Classify, then translate

Drop internal changes: refactors, test-only commits, CI, lint, dependency bumps that change nothing a user can observe. A 40-commit release usually produces eight bullets.

Then rewrite from engineer-speak to reader-speak. This is the step that carries the whole task:

| Commit says | Changelog entry | Release note |
|---|---|---|
| `refactor: extract TokenParser` | — drop | — drop |
| `fix: race in upload handler` | Fixed uploads failing under concurrent writes. | Fixed an issue where uploads could silently fail under heavy load. |
| `feat: add --dry-run to import` | Added `--dry-run` to `import`. [#142] | You can now preview an import before running it with `--dry-run`. |
| `perf: trigram index on search` | Changed search to use a trigram index. | Search is roughly 10x faster on large workspaces. |
| `chore: bump tiptap 2.1 to 2.3` | — drop unless behavior changed | — drop |

Lead with the benefit, not the mechanism. Name the feature, not the file — nobody outside the repo knows what `ReportBuilder.tsx` is.

## Step 4 — Breaking changes go first

Breaking changes lead the document, never buried under "Changed". For each one state what changed, who is affected, and what they must do. Include the deprecation timeline if one exists.

If a release has breaking changes and the version does not reflect that, say so before writing.

## Step 5 — Match the existing file

If `CHANGELOG.md` exists, read the last two entries and match them: heading level, date format, whether categories are used, whether entries link issues. Consistency across releases matters more than this skill's preferred format. Insert at the top under `## [Unreleased]`, or under `## [X.Y.Z] - YYYY-MM-DD` when tagging now. Never overwrite existing entries.

Ask for the version number if it is not obvious from the tags.

## Step 6 — Show before writing

Show the drafted entry, then write it. For release notes, output to chat unless the user named a file.

## Rules

- **Do not pad.** Three real changes means three bullets.
- **Do not dump the commit list.** Most commits do not deserve a bullet.
- **Do not omit a regression that was fixed.** Candor reads better than the pretence that nothing breaks.
- **No "Miscellaneous" section.** If it does not fit a category, it is probably not user-visible.
- **Match the file's emoji convention**, whichever way it goes. Do not introduce emoji into a file that has none.
