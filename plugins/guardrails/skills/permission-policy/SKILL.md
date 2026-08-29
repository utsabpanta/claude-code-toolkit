---
name: permission-policy
description: This skill should be used when the user asks to "set up permissions for Claude Code", "stop Claude asking me every time", "lock down Claude for my team", "what should I allowlist", or is choosing between permission modes. It produces a permission policy calibrated to the repo, not a generic list.
allowed-tools: Bash, Read, Grep, Glob
---

# Design a permission policy

The failure mode at both ends is the same: the policy stops being used. Too tight and the user turns permissions off entirely. Too loose and it grants nothing worth having. The goal is the narrowest allowlist that removes the prompts the user actually hits.

Three starting profiles ship with this plugin in `${CLAUDE_PLUGIN_ROOT}/policies/`: `strict.json`, `balanced.json`, `solo.json`. Start from one, then calibrate to the repo. Do not paste one in unmodified.

## Step 1 — Find out what this repo actually runs

Do not guess the commands. Read them:

```bash
ls package.json pyproject.toml go.mod Cargo.toml Gemfile Makefile 2>/dev/null
jq -r '.scripts | keys[]' package.json 2>/dev/null
grep -E '^[a-zA-Z_-]+:' Makefile 2>/dev/null | cut -d: -f1
ls .github/workflows/ 2>/dev/null
```

The test, lint, build and typecheck commands this repo really uses are the ones worth allowlisting. Everything else is speculation.

## Step 2 — Pick the tier

| Profile | For | Default mode |
|---|---|---|
| `strict` | Shared repos, production access, anything with a deploy path | `default`, most tool families on `ask` |
| `balanced` | Normal team development | `default`, read-only and test commands allowed |
| `solo` | A personal project where the blast radius is one machine | `acceptEdits` |

Ask which one fits if it is not obvious from the repo. A repo with `terraform/`, `.github/workflows/` that deploy, or credentials in CI is `strict` regardless of team size.

## Step 3 — Write the allow list

Rules to hold to:

- **Allowlist read-only commands freely.** `git status`, `git diff`, `git log`, `ls`, `cat`, `rg`, `grep`. These have no blast radius and they are most of the prompts.
- **Allowlist the specific subcommand, never the family.** `Bash(npm test:*)`, not `Bash(npm:*)` — the latter includes `npm publish`.
- **Never allowlist `curl`, `wget`, `sudo`, or `rm`.** The first two fetch and can execute remote code; the second two are exactly the blast radius the policy exists to bound.
- **Use `ask` for the middle ground.** `git push`, `gh pr create`, `docker`, `terraform` are legitimate and consequential. `ask` keeps them one keystroke away instead of blocked.

## Step 4 — Write the deny list

Deny beats allow at every level, so this is where the real guarantees live.

Cover, at minimum: history rewrites (`git push --force`, `git push -f`, `git reset --hard`), publication (`npm publish`, `cargo publish`, `twine upload`, `gh release create`), merges (`gh pr merge`), infrastructure mutation (`terraform apply`, `terraform destroy`, `kubectl delete`), and credential reads (`Read(./.env)`, `Read(~/.aws/**)`, `Read(~/.ssh/**)`).

Enumerate the spellings. `Bash(git push --force:*)` does not match `git push -f`. List both, and understand that a pattern list will never catch every variant — that is why the `guardrails` hooks exist alongside it. Permission rules match on text; hooks match on intent.

## Step 5 — Place it in the right file

| File | Scope | Committed |
|---|---|---|
| `.claude/settings.json` | The project, for everyone | Yes |
| `.claude/settings.local.json` | The project, for this developer | No — gitignore it |
| `~/.claude/settings.json` | Every project for this user | Not applicable |

Precedence, highest first: enterprise managed settings, command line, `settings.local.json`, `settings.json`, user settings. A user-level allow cannot override a project-level deny — which is what makes a committed project policy meaningful.

For a team, put the shared floor in `.claude/settings.json` and commit it, and let people add personal conveniences in `settings.local.json`.

## Step 6 — Verify

Show the user what changed and what it means in practice:

```
Allowed without prompting:  22 read-only and test commands
Ask first:                  git push, gh pr create, docker
Denied outright:            force push, publish, terraform apply, secret reads
```

Then check the policy did not break the ordinary loop: run the repo's own test command and confirm it does not prompt.

## Rules

- **Never add a permission to unblock a single command mid-task.** Note it and batch the policy change into a deliberate edit.
- **Never suggest `bypassPermissions`** as a fix for prompt fatigue. Narrow the allowlist instead.
- **Prefer `ask` to `allow`** whenever the command writes anything outside the working tree.
- **A permission rule is not a security boundary against a determined process.** It bounds accident and mistake. Say so rather than overselling it.
