---
name: release-notes
description: Generate customer-facing release notes from git commits since a tag, ref, or date. Use when the user types /release-notes, asks to draft release notes, or asks what changed in a release.
---

# Release Notes

Customer-facing release notes. Different from a changelog — the audience is users, not engineers. Focus on *what they can now do* or *what got better*, not on internal refactors they don't care about.

## Step 1 — Determine the range

Ask or infer the range:

- "Since the last tag" → `git describe --tags --abbrev=0` gives the previous tag, then `git log <tag>..HEAD`.
- "Since date X" → `git log --since="X"`.
- "Since we shipped v2.1" → `git log v2.1..HEAD`.

If unclear, ask once: "What range should I cover — since the last tag, since a date, or a specific commit?"

## Step 2 — Collect the changes

Run:

- `git log <range> --no-merges --pretty=format:"%h %s%n%b%n---"` — commit subjects and bodies.
- `git log <range> --stat` — to get a sense of scale per commit.

For each commit, note:
- What changed (from subject + body)
- Whether it's user-visible (new feature, behavior change, bug fix a user would have noticed) or internal (refactor, test, dep bump, CI)

Drop the internal changes unless the user asks for a full changelog.

## Step 3 — Group and translate

Group user-visible changes into these buckets (omit any that are empty):

- **✨ New** — new features or capabilities
- **🔧 Improved** — existing features that got better
- **🐛 Fixed** — bug fixes users would have noticed
- **⚠️ Breaking** — changes that require action from users

For each entry, rewrite from engineer-speak to user-speak:

| Commit says | Notes should say |
|---|---|
| "Refactor auth middleware to use JWT" | — (internal, drop) |
| "Fix race condition in upload handler" | "Fixed an issue where uploads could silently fail under heavy load." |
| "Add /api/v2/reports endpoint" | "New Reports API — export analytics as CSV or JSON. See docs for details." |
| "Bump tiptap from 2.1 to 2.3" | — (internal, drop — unless it changed user-visible editor behavior) |

Rules:

- **Lead with the benefit, not the mechanism.** "Faster search" beats "Switched search from Postgres LIKE to trigram index."
- **Past tense for fixes, present for features.** "Fixed X" / "You can now Y."
- **Name the feature, not the file.** Users don't know what `ReportBuilder.tsx` is.
- **Keep each bullet under ~150 chars.** Link to docs for detail.

## Step 4 — Add the header

At the top, include:

```
# [Version or date] release notes

One-paragraph summary of what this release is about. If it's a themed release
("performance & reliability", "billing revamp"), say that. If it's a grab-bag,
name the 2–3 highlights.
```

## Step 5 — Draft breaking changes carefully

If there are breaking changes:

- Put them **at the top**, not buried.
- For each one: what changed, who's affected, what they need to do.
- Include a deprecation timeline if one exists.

## Output format

```
# <Version> release notes

<Summary paragraph>

## ⚠️ Breaking changes
(only if any)
- **<thing that changed>.** <Who's affected. What to do.>

## ✨ New
- ...

## 🔧 Improved
- ...

## 🐛 Fixed
- ...
```

## Calibration

- **Don't pad.** If the release has three things in it, the notes have three bullets. Nobody reads padded notes.
- **Don't lie by omission.** If something broke and got fixed, say so — users appreciate candor more than they appreciate pretending nothing ever goes wrong.
- **Don't dump the commit list.** A 40-commit release might produce 8 bullets. Most commits don't deserve a bullet.
- **If the repo has a CHANGELOG.md**, check its style and match it. Consistency across releases matters more than this skill's specific format.
