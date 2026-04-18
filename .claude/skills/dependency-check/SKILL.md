---
name: dependency-check
description: Evaluate a package before adding it — what it does, maintenance health, alternatives, supply-chain risk, and whether it's actually needed. Use when the user types /dependency-check, is about to add a dependency, or asks whether they should pull in a library.
---

# Dependency Check

Your job is to help the user decide whether adding this dependency is a good idea — or whether they'd be better off writing 30 lines themselves. Every dependency is a long-term liability. Default to skepticism.

## Step 1 — Identify the package

- The user will name a package (`left-pad`, `lodash`, `requests`, etc.) and an ecosystem (npm, PyPI, crates.io, Go modules).
- If the ecosystem is unclear, infer from the project: look at `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`.
- If the user is evaluating multiple candidates, check each in turn.

## Step 2 — Gather the facts

Use `WebFetch` or the registry CLI to answer these. If offline, ask the user to paste the info.

### What it does
- The first paragraph of the README. In your own words, one sentence.
- The core API surface — what you actually call.

### Maintenance health
- Last release date. Six months = fine. Two years = be careful. Five years = probably unmaintained.
- Open issues vs. closed issues.
- Open PRs sitting stale.
- Number of maintainers. A bus factor of 1 on a package you depend on is a risk.

### Popularity
- Weekly downloads (npm) / stars / dependents. Not a quality signal on its own, but very low numbers + recent changes = experimental.
- Are any well-known projects depending on it?

### Supply chain
- How many transitive dependencies does it pull in? Run `npm view <pkg> dependencies` or equivalent.
- Any recent security advisories? (`npm audit`, `pip-audit`, GitHub Security Advisories.)
- Is it published by a known author/org, or a freshly-created account?
- Does it run install scripts? Post-install scripts are a classic supply-chain attack vector.

### License
- Compatible with your project's license? GPL in an MIT project is a problem. Unlicensed / "no license" = you don't have rights to use it.

### Size
- Bundle size (for frontend). `bundlephobia.com` or similar.
- Install footprint (server). Does it pull in 400MB of native deps for a 10-line utility?

## Step 3 — Evaluate the need

Ask honestly: could the user write this themselves in under an hour?

- If the package is <100 lines and the API is small → probably write it.
- If the package handles genuinely hard things (cryptography, parsing, timezones, HTTP) → don't reinvent, use a well-maintained one.
- If a closer alternative already exists in the project's stdlib or existing deps → use that.

## Step 4 — Output

```
## Verdict
Add it / Don't add it / Maybe, with caveats.

## What it does
One sentence.

## Health
- Last release: [date]
- Maintainers: [n]
- Open issues / PRs: [n / n]
- Transitive deps: [n]
- License: [license]
- Known vulns: [yes/no, which]

## Alternatives
- [alt 1] — why it might be better/worse
- [alt 2] — ...
- Rolling your own — rough LoC estimate and what you'd have to handle

## Risks
- [concrete risk 1]
- [concrete risk 2]

## Recommendation
One paragraph. If "add it": pin to what version and why. If "don't": what to do instead.
```

## Rules

- **Be blunt about abandonware.** A package whose last commit was 2019 is a yes-or-no decision, not a maybe.
- **Supply chain is not paranoia.** Left-pad, event-stream, ua-parser-js — these were real incidents. A dependency with one maintainer and install scripts is a real risk.
- **Count transitive deps.** `is-odd` pulling in `is-number` pulling in `kind-of` is a meme for a reason.
- **Don't recommend "just write it yourself" for things that are genuinely hard.** Crypto, date/time, HTTP, parsing — use the library.
- **If the user has already added it** and wants a retroactive check: give them a path to removal or replacement if warranted, not just a grade.
