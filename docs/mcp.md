# MCP servers

An MCP server is a separate process (or a remote HTTP endpoint) that exposes
tools to Claude Code. Configuring one is where people most often put correct
JSON in the wrong file and get no error at all.

## Where MCP configuration actually lives

**Not in `settings.json`.** An `mcpServers` key inside `settings.json` is
ignored silently. `scripts/doctor.sh` flags this specifically.

| Scope | File | Committed | Normal way to edit |
|---|---|---|---|
| Project | `.mcp.json` at the repo root | Yes | Hand-edited, reviewed like code |
| User | `~/.claude.json` | No | `claude mcp add --scope user` |
| Local | `~/.claude.json`, project-keyed | No | `claude mcp add --scope local` |

`settings.json` holds only the *governance* keys, which decide which servers a
project is allowed to use:

```json
{
  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": ["github"],
  "disabledMcpjsonServers": ["some-server"],
  "allowedMcpServers": ["github", "sentry"],
  "deniedMcpServers": []
}
```

## The CLI

Prefer this over hand-editing user-scope config:

```bash
claude mcp add <name> --scope user -- npx -y @some/mcp-server
claude mcp add <name> --scope project --transport http https://mcp.example.com/mcp
claude mcp list
claude mcp get <name>
claude mcp remove <name>
```

`--scope` is one of `local` (default, this project only, private), `project`
(written to `.mcp.json`, shared with the team), or `user` (all your projects).

## `.mcp.json` format

```json
{
  "mcpServers": {
    "local-stdio-server": {
      "command": "npx",
      "args": ["-y", "@some/mcp-server"],
      "env": { "API_KEY": "${SOME_API_KEY}" }
    },
    "remote-http-server": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "headers": { "Authorization": "Bearer ${SOME_TOKEN}" }
    }
  }
}
```

`type` is `stdio` (the default when `command` is present), `http`, `sse`, or
`ws`. Most first-party servers today are remote HTTP with OAuth rather than a
local `npx` process — Claude Code will walk you through the OAuth flow on first
use, and `/mcp` shows connection status.

Environment expansion works in `.mcp.json`: `${VAR}` fails if unset,
`${VAR:-default}` falls back. Use it so a committed `.mcp.json` never contains a
credential.

## Bundling MCP servers in a plugin

Either a `.mcp.json` at the plugin root, or an `mcpServers` key in
`plugin.json`. Both merge with the user's own servers rather than replacing
them. Reference bundled binaries through `${CLAUDE_PLUGIN_ROOT}`:

```json
{
  "mcpServers": {
    "db-tools": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "env": { "DB_URL": "${DB_URL}" }
    }
  }
}
```

Tools from a plugin server are named
`mcp__plugin_<plugin-name>_<server-name>__<tool-name>`, which is the form to use
in `permissions.allow`.

## Choosing servers

This repository deliberately does not ship a curated server list. Lists of that
kind age badly: several widely-copied recommendations
(`@modelcontextprotocol/server-postgres`, `server-sqlite`, `server-slack`,
`server-puppeteer`, `server-github`) are now archived or deprecated, and one
frequently-copied example — `@modelcontextprotocol/server-fetch` — does not
exist on npm at all. The reference fetch server is Python: `uvx mcp-server-fetch`.

Go to the source instead:

- The official registry and the current reference servers:
  https://github.com/modelcontextprotocol/servers
- Vendor-run servers, which are usually the maintained option: GitHub, Sentry,
  Linear, Notion, and Stripe each publish their own.

Prefer a vendor's own remote server over a community wrapper. It will be
maintained, and OAuth beats pasting a personal access token into a config file.

## Security

An MCP server runs with your credentials and can read whatever you point it at.

- Treat adding one like adding a dependency: check who publishes it.
- Never hardcode a token. Use `${VAR}` expansion or OAuth.
- Scope tokens to the minimum. A read-only GitHub token is enough for review
  workflows.
- Use `permissions.deny` on specific `mcp__*` tools that write, if you only want
  the read paths.
- `/mcp` lists connected servers and their tools. Audit it occasionally.

## Related

- [hooks.md](hooks.md) — the other extension point that fails silently
- `scripts/doctor.sh` — flags `mcpServers` in the wrong file
