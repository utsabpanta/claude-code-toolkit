---
name: harden-setup
description: This skill should be used when the user asks to "audit my Claude Code setup", "check my hooks", "is my .claude config safe", "harden Claude Code for my team", or mentions that a hook does not seem to be firing or blocking. It finds configuration that looks correct but silently does nothing.
allowed-tools: Bash, Read, Grep, Glob
---

# Harden a Claude Code setup

Claude Code configuration fails quietly. A hook with the wrong exit code prints a refusal and lets the action through. An `mcpServers` block in the wrong file is ignored without an error. A permission rule that is too broad never announces itself. The user believes they have a guardrail; they have a comment.

Your job is to find those, explain the consequence in terms of what actually happens, and fix them.

## Step 1 — Run the audit

```bash
"${CLAUDE_PLUGIN_ROOT}/../../scripts/doctor.sh" .
```

If that path is unavailable (the skill is running outside the repo), fall back to inspecting by hand using the checks below. Report the findings, but do not stop there: the script covers the mechanical checks, and the judgment calls are yours.

## Step 2 — Verify every blocking hook actually blocks

This is the highest-value check and the one people get wrong most often.

A `PreToolUse` hook blocks a tool call in exactly two ways:

- exit code **2**, with the reason on **stderr**; or
- exit code **0** with this on **stdout**:

```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"why"}}
```

**Exit code 1 does not block anything.** It is reported as a non-blocking error and the tool runs.

For each hook that claims to block, prove it rather than reading it:

```bash
echo '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/tmp/.env"}}' \
  | /path/to/the-hook.sh; echo "exit=$?"
```

A hook that blocks emits a `deny` payload or exits 2. Anything else is a no-op. Say so plainly: "this hook does not block; it prints a message and the write proceeds."

## Step 3 — Check the permission rules

Read `permissions.allow`, `permissions.ask` and `permissions.deny` from `.claude/settings.json`, `.claude/settings.local.json`, and `~/.claude/settings.json`.

Flag as too broad: any `Bash(rm:*)`, `Bash(sudo:*)`, `Bash(curl:*)`, `Bash(wget:*)`, or a bare tool family like `Bash(gh:*)` in a repo that can publish releases. Flag `defaultMode: "bypassPermissions"` unconditionally.

Check the deny list actually covers what the user believes it covers. `Bash(git push --force:*)` does not match `git push -f`, and neither matches `git push origin +main:main`. Enumerate the variants.

Read precedence matters and people get it backwards: deny wins over allow, and the order is enterprise managed settings, then command line, then `.claude/settings.local.json`, then `.claude/settings.json`, then `~/.claude/settings.json`. A user-level allow cannot override a project-level deny.

## Step 4 — Check the file each thing lives in

Configuration in the wrong file is inert:

| Thing | Correct location |
|---|---|
| MCP servers, project scope | `.mcp.json` at the repo root |
| MCP servers, user scope | `~/.claude.json`, normally via `claude mcp add` |
| MCP governance only | `settings.json`: `enableAllProjectMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers` |
| Hooks, personal | `settings.json` under `hooks` |
| Hooks, shipped in a plugin | `hooks/hooks.json` at the plugin root, paths via `${CLAUDE_PLUGIN_ROOT}` |
| Skills | `<dir>/SKILL.md` where `<dir>` matches the frontmatter `name` |

An `mcpServers` key inside `settings.json` is the single most common instance of this and produces no error at all.

## Step 5 — Portability

Hooks run wherever the user runs Claude Code, including Linux CI. Flag `date -v` (BSD only), `realpath --relative-to` (GNU only), `sed -i ''` (BSD only), and `readlink -f` (GNU only). Give the portable replacement, not just the complaint.

Also flag `set -e` combined with `jq`: a filter that matches nothing returns non-zero and aborts the hook halfway, usually before the part that does the blocking.

## Step 6 — Report

Group by consequence, not by file:

```
## Does not do what it says
- <hook>: exits 1 on a secret write, so the write proceeds. Fix: emit a deny payload.

## Too permissive
- Bash(curl:*) is allowlisted; that permits fetching and running remote code.

## Wrong file
- mcpServers in .claude/settings.json is ignored. Move it to .mcp.json.

## Portability
- <hook> uses `date -v-1d`, which fails on Linux.

## Fine
- <n> hooks, <n> skills, <n> agents checked with no findings.
```

Then offer to fix them. Fix the silent no-ops first: those are the ones the user already believes are protecting them.

## Rules

- **Prove a hook's behavior by running it**, never by reading it. The whole point is that these files look correct.
- **Never widen a permission to make something work.** If a command is blocked, that is usually the system functioning.
- **Do not edit `~/.claude/settings.json` without asking.** It is user-global and affects every project.
- **A clean report is a valid result.** Do not invent findings to look thorough.
