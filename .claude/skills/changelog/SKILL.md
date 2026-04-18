---
name: changelog
description: Append a Keep-a-Changelog entry from a commit range or a release. Use when the user types /changelog, is cutting a release, or asks to update CHANGELOG.md.
---

# Changelog

Your job is to append a clean, human-readable entry to `CHANGELOG.md` that a user (not a maintainer) would actually want to read. Follow the [Keep a Changelog](https://keepachangelog.com/) format.

## Step 1 — Find scope

Figure out what's being changelogged:

1. If the user named a range (`v1.2.0..HEAD`, `main..my-branch`), use it.
2. Else find the last tag reachable from `HEAD` with `git describe --tags --abbrev=0` and use `<tag>..HEAD`. (Avoid `git tag --sort=-v:refname | head -1` — in a monorepo that returns the newest tag *globally*, which may belong to a different package.)
3. If there's no `CHANGELOG.md`, offer to create one.

## Step 2 — Gather the material

- `git log <range> --pretty=format:"%h %s"` for the short list.
- `git log <range> --pretty=format:"%h %s%n%n%b" --no-merges` for the full messages.
- Read the PR descriptions if they're in commit bodies.

Ignore merge commits and trivial commits (`fix typo`, `update readme`, `bump version`).

## Step 3 — Classify each change

Use the Keep-a-Changelog categories. Drop any category that's empty.

- **Added** — new features the user will notice.
- **Changed** — changes to existing behavior.
- **Deprecated** — soon-to-be-removed features.
- **Removed** — deleted features.
- **Fixed** — bug fixes the user will notice.
- **Security** — vulnerability fixes.

Merge duplicates. If three commits together implement one feature, write one bullet.

## Step 4 — Rewrite each entry for a user

A commit message is written for maintainers. A changelog entry is written for users. Translate:

- `refactor: extract TokenParser` → skip (internal, invisible to users).
- `feat: add --dry-run flag to import` → "Added `--dry-run` flag to `import` command to preview changes before applying."
- `fix: handle empty array in reduce()` → "Fixed a crash when processing empty result sets."

Rules:

- Start with a verb (Added, Removed, Fixed, etc., then the action).
- Be concrete about what changed from the user's perspective.
- Link PRs or issues if the commits reference them: `[#123]`.
- Skip purely internal changes (build tooling, test refactors, lint fixes).

## Step 5 — Write the entry

Insert at the top, under `## [Unreleased]` if you're not tagging now, or `## [X.Y.Z] — YYYY-MM-DD` if you are. Ask the user for the version number if it isn't obvious.

Format:

```markdown
## [1.4.0] — 2025-11-12

### Added
- `--dry-run` flag on `import` to preview changes. [#142]

### Changed
- Default timeout raised from 5s to 30s for large imports.

### Fixed
- Crash when parsing empty CSV files. [#148]

### Security
- Updated `axios` to 1.7.4 to patch CVE-2024-XXXXX.
```

Keep entries short. A reader should be able to scan the release in ten seconds.

## Step 6 — Confirm and write

Show the user the drafted entry before writing. Edit `CHANGELOG.md` in place — don't overwrite existing entries.

## Rules

- **No "misc" section.** If it doesn't fit a category, it's probably not user-visible.
- **No internal chatter.** "Refactored X for testability" does not belong in a changelog.
- **No emoji prefixes** unless the existing file uses them. Match the existing style.
- **If the range is empty**, tell the user — don't invent entries.
