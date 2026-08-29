# Settings and permissions

## Where settings live, and which one wins

Highest precedence first. A lower file cannot override a higher one.

| File | Scope | Committed |
|---|---|---|
| Enterprise managed settings | Organization-wide | Managed by IT |
| Command-line flags | This invocation | n/a |
| `.claude/settings.local.json` | This project, this developer | **No** — gitignore it |
| `.claude/settings.json` | This project, everyone | **Yes** |
| `~/.claude/settings.json` | Every project, this user | n/a |

Within permissions, **deny beats allow at every level**. A user-level `allow`
cannot override a project-level `deny`, which is what makes a committed project
policy meaningful for a team.

## Permission rules

Three lists, matched as `Tool(pattern)`:

```json
{
  "permissions": {
    "defaultMode": "default",
    "allow": ["Bash(git status:*)", "Bash(npm test:*)"],
    "ask":   ["Bash(git push:*)", "Bash(terraform:*)"],
    "deny":  ["Bash(rm -rf:*)", "Read(./.env)", "Write(./secrets/**)"]
  }
}
```

`defaultMode` is `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, or
`bypassPermissions`. Do not reach for `bypassPermissions` to cure prompt
fatigue — narrow the allowlist instead. `disableBypassPermissionsMode: "disable"`
removes the option entirely for a shared repo.

### Rules that matter

- **Allowlist the subcommand, never the family.** `Bash(npm test:*)`, not
  `Bash(npm:*)` — the latter includes `npm publish`.
- **Never allowlist `curl`, `wget`, `sudo`, or `rm`.** The first two fetch and
  can execute remote code.
- **Enumerate the spellings in `deny`.** `Bash(git push --force:*)` does not
  match `git push -f`, and neither matches `git push origin +main:main`.
- **Use `ask` for the middle ground.** `git push`, `gh pr create`, `docker`,
  `terraform` are legitimate and consequential. `ask` keeps them one keystroke
  away instead of blocked.

Permission rules match on **text**. The `guardrails` hooks match on **intent**,
which is why they exist alongside the rules rather than instead of them:
`guard-force-push.sh` catches all four spellings above.

## Policy profiles

Three starting points ship in
[`plugins/guardrails/policies/`](../plugins/guardrails/policies):

| Profile | For | Default mode |
|---|---|---|
| [`strict.json`](../plugins/guardrails/policies/strict.json) | Shared repos, production access, a deploy path | `default`, most tool families on `ask` |
| [`balanced.json`](../plugins/guardrails/policies/balanced.json) | Normal team development | `default`, read-only and test commands allowed |
| [`solo.json`](../plugins/guardrails/policies/solo.json) | Personal projects, blast radius of one machine | `acceptEdits` |

Do not paste one in unmodified — the allowlists guess at build commands. Run
`/permission-policy` instead and it will read the repo's actual `package.json`
scripts and `Makefile` targets and calibrate.

## `settings.example.json`

A conservative starting point at the repo root: 22 read-only and test commands
allowed, six destructive families denied. It deliberately contains **no `model`
key** — pinning a model in a shared file ages badly, and this repo previously
shipped a stale `claude-sonnet-4-6`. Set your own if you want one; current ids
are `claude-opus-5`, `claude-sonnet-5`, and `claude-haiku-4-5-20251001`.

It also ships no hooks and no MCP config on purpose. Install `guardrails` for
hooks; see [mcp.md](mcp.md) for where MCP config actually goes.

## Other keys worth knowing

| Key | Purpose |
|---|---|
| `enabledPlugins` | Auto-enable plugins for anyone who opens the repo |
| `extraKnownMarketplaces` | Trust a marketplace without a manual `/plugin marketplace add` |
| `hooks` | Personal hook wiring. Plugin hooks merge on top |
| `statusLine` | The command that renders your status bar |
| `outputStyle` | Persist a style without typing `/output-style` |
| `env` | Environment variables for shell commands Claude runs |
| `sandbox` | Filesystem and network isolation |
| `disableAllHooks` | Escape hatch when debugging a misbehaving hook |

## Auditing what you have

```bash
./scripts/doctor.sh .
```

Flags overly broad allow rules, `bypassPermissions`, `mcpServers` in the wrong
file, stale model pins, and hook commands that point at files which do not exist.
