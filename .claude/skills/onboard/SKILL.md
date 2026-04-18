---
name: onboard
description: Help the user get oriented in an unfamiliar codebase — map the structure, identify the entry points, explain the domain model, and surface the landmines. Use when the user types /onboard, says they're new to a codebase, or asks "what is this repo?"
---

# Onboarding Guide

Get a new person (or yourself) productive in a codebase within an hour. Not a walking tour — a map plus the one path they need first.

## Step 1 — Establish the target

Ask:

1. **What do you want to do first?** ("Fix a bug in X", "add a feature around Y", "just understand it").
2. **What's your background?** (Language, frameworks, domain.)
3. **How much time do you have for this orientation?** (30 min? A day? Adjusts depth.)

Tailor the orientation to the answers. Someone who says "I need to add a column to the users table" gets a very different tour than someone who says "I'm new to the team, general overview please."

## Step 2 — Read the self-description first

Before exploring code, read what the repo says about itself:

- `README.md`
- `CONTRIBUTING.md`
- `docs/` (if it exists — skim top-level only)
- `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod` — what's declared?
- `.github/workflows/` — what CI runs?
- `CHANGELOG.md` or recent release notes — what's been changing lately?

Don't read every file. Skim for: what this project *is*, who it's for, how it's run, how it's tested.

## Step 3 — Map the structure

Run `ls` at the root and one or two levels deep to get the directory layout. For each top-level directory, figure out what it's for — usually obvious from names, sometimes you need to read one file inside.

Produce a map like this:

```
repo/
├── src/
│   ├── api/         <- HTTP handlers, thin (delegates to services)
│   ├── services/    <- Business logic, most of the work lives here
│   ├── db/          <- Migrations + queries
│   └── jobs/        <- Background workers (via Sidekiq)
├── test/            <- Mirror of src/
├── infra/           <- Terraform + deploy configs
└── docs/            <- ADRs + runbooks
```

Annotate only what's non-obvious. "src/ = source" doesn't earn its keep.

## Step 4 — Identify entry points and data flow

For a web app:
- Where do requests come in? (Router, controller, handler file.)
- How do they flow to business logic?
- Where does data get written / read?

For a CLI:
- Where is `main` / the entry binary?
- How are commands dispatched?

For a library:
- What's the public API? (`index.ts`, `lib.rs`, `__init__.py`, etc.)
- What's the boundary between public and internal?

Pick **one** concrete request/command/call and trace it end-to-end. Show the user the actual file:line trail. This is worth more than any overview.

## Step 5 — Surface the domain model

Every codebase has 3–5 core nouns — things the system manipulates. (e.g. `User`, `Invoice`, `Tenant`, `Job`.) Find them:

- Check the DB schema / migrations if there's a database.
- Check the type definitions if there's a type system.
- Find the folder or model that holds them.

For each core noun, one line: what it is, how it relates to the others. The goal is a vocabulary the user can speak with after reading this.

## Step 6 — Find the landmines

What's the stuff that bites newcomers? Look for:

- **Pinned versions with "do not upgrade" comments** in lockfiles / dockerfiles.
- **`TODO` / `HACK` / `XXX` comments** with context about why.
- **Flags or env vars that must be set** for things to work locally.
- **Long-running branches** in `git branch -a` — sign of in-flight work.
- **Tests marked as skipped or flaky.**
- **Custom Makefile targets / `scripts/`** — what does the team actually run?

One short list: "Watch out for these."

## Step 7 — Local setup check

Ask the user whether they've run the project locally. If not, walk through:

1. Check the README's setup steps (or `CONTRIBUTING.md`).
2. What's missing (env vars, services, seed data)?
3. Run `<test command>` to confirm the toolchain is working.

If anything in the docs is stale or wrong, flag it — that's a valuable PR for their first contribution.

## Output

```
# Onboarding: <repo name>

## What this is
1-sentence description, and who it's for.

## Entry points
Where to start reading depending on what you need:
- To understand a request: start at `src/api/router.ts:42`
- To understand the data model: `src/db/schema.sql`
- To run tests: `npm test` (set `TEST_DATABASE_URL` first)

## The map
<Annotated tree from Step 3>

## Core domain
- **User** — ... (relates to Organization and Session)
- **Invoice** — ...
- **Tenant** — ...

## One walked path
Chosen scenario walked end-to-end with file:line references.

## Landmines
- Don't upgrade `foo` past v2 — breaks on Node 18 (see comment in package.json)
- Tests need `TEST_DATABASE_URL` set — README doesn't mention this
- `jobs/` uses a homegrown queue, not the Sidekiq you'd expect

## First task
Based on your stated goal, here's where to start: ...
```

## Rules

- **Don't show off.** A shorter orientation is better. Prune anything that won't be useful in the first hour.
- **Don't explain language/framework basics.** The user knows what a React component is.
- **Don't invent rationales** for code structure you don't understand. Say "not sure why this is split this way — worth asking".
- **Cite specific paths.** Every claim should be backed by a file or line.
