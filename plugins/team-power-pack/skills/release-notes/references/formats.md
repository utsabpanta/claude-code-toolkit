# Output formats

## Keep a Changelog

Categories, in this order. Omit any that are empty.

**Added** — new features. **Changed** — changes in existing behavior.
**Deprecated** — soon to be removed. **Removed** — now gone.
**Fixed** — bug fixes. **Security** — vulnerability fixes.

```markdown
## [1.4.0] - 2026-08-29

### Added
- `--dry-run` flag on `import` to preview changes before applying. [#142]

### Changed
- Default timeout raised from 5s to 30s for large imports.

### Fixed
- Crash when parsing empty CSV files. [#148]

### Security
- Updated `axios` to 1.7.4 to patch CVE-2024-XXXXX.
```

Unreleased work accumulates under `## [Unreleased]` at the top and is renamed to
the version heading at tag time.

Reference: https://keepachangelog.com/

## Customer release notes

```markdown
# <Version> release notes

<One paragraph. If the release has a theme - "performance and reliability",
"billing revamp" - name it. If it is a grab-bag, name the two or three
highlights and move on.>

## Breaking changes
(only when there are any; always first)
- **<What changed>.** <Who is affected.> <What they need to do.>

## New
- <Capability, stated as something the reader can now do.>

## Improved
- <Existing thing that got better, with the magnitude if it is known.>

## Fixed
- <Bug a user would have noticed, described from their side.>
```

Keep bullets under about 150 characters and link to docs for detail. Past tense
for fixes, present tense for capabilities: "Fixed X", "You can now Y".

## Version numbering

Under semantic versioning: breaking changes require a major bump, new
backward-compatible features a minor bump, fixes a patch bump. If the drafted
notes contain a breaking change and the proposed version is a patch, raise it
before writing.
