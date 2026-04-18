---
description: Summarize what changed since a git ref (branch, tag, date)
argument-hint: <ref> (e.g. main, v2.1, HEAD~10, "yesterday")
---

Summarize what's changed since $ARGUMENTS.

## Process

1. **Resolve the ref.** If $ARGUMENTS looks like a tag/branch/commit, diff against it with `git log <ref>..HEAD`. If it looks like a date ("yesterday", "2 weeks ago", "2025-10-01"), use `git log --since="<date>"`. If it's empty or ambiguous, ask.

2. **Pull the data:**
   - `git log <range> --no-merges --pretty=format:"%h %s%n%b%n---"` — commit messages
   - `git log <range> --stat` — scope per commit
   - Optionally `git log <range> --pretty=format:"%an" | sort -u` — authors

3. **Group changes** into coherent buckets — not one bullet per commit:
   - ✨ **New** — new features or capabilities
   - 🔧 **Improved** — enhancements
   - 🐛 **Fixed** — bug fixes
   - ♻️ **Refactored** — internal changes with no visible effect
   - 📚 **Docs / tests / infra** — everything else

   Drop any empty bucket.

4. **Translate to human language.** Not "Refactor handlers/auth.ts" → "Simplified the auth handler to prepare for the JWT migration." Readers care about behavior changes, not file names.

5. **Flag anything notable.** Breaking changes, security fixes, dependency bumps, config changes — call these out separately at the top so no one misses them.

## Output

```
# Since <ref> — <N> commits, <N> authors

## Notable / breaking (if any)
- ...

## ✨ New
- ...

## 🔧 Improved
- ...

## 🐛 Fixed
- ...

## ♻️ Refactored / infra / docs
- ...

## Contributors
<N names>
```

## Rules
- **Length scales with the range.** 3 commits → 3 bullets. 300 commits → ~12 grouped bullets, not 300.
- **No commit noise.** "bump version", "fix typo in comment", "rerun CI" — drop unless the whole range is that size.
- **Lead with behavior, not code.** "Faster checkout" beats "Switched query planner hints."
- **Don't invent narrative.** If a week of commits is genuinely a grab bag, say "grab bag of small fixes" and list 4–5 representative ones.
