# MCP servers — giving Claude new abilities

The **Model Context Protocol** lets you plug external tools into Claude Code: databases, browsers, issue trackers, search indexes, your own internal APIs. Claude calls them like built-in tools.

Most users stick to the built-in tools. Adding even one well-chosen MCP server changes what Claude can do in your project.

## How MCP servers are configured

MCP servers are declared in `~/.claude/settings.json` (user-level) or `.claude/settings.json` (project-level). Each server is a process Claude Code spawns on startup.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/project"]
    }
  }
}
```

When Claude Code starts, it spawns each server and discovers what tools they expose. The tools become available to Claude automatically (you'll see them alongside `Read`, `Bash`, etc.).

## Curated list

A short, practical list. All of these are official (Anthropic / `modelcontextprotocol` org) or widely-used. **Read the README of any server before trusting it** — MCP servers run with your permissions.

### Everyday picks

| Server | What it does | When to use |
|---|---|---|
| [`server-filesystem`](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) | Scoped file access to specific directories | Work across multiple projects in one Claude session |
| [`server-git`](https://github.com/modelcontextprotocol/servers/tree/main/src/git) | Rich git operations (better than shelling out for complex ops) | Heavy git work — bisect, blame analysis, cross-branch diffs |
| [`server-github`](https://github.com/github/github-mcp-server) | Full GitHub API — issues, PRs, reviews, discussions | Instead of `gh` for anything beyond basic PR listing |
| [`server-sequentialthinking`](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking) | Structured step-by-step reasoning tool | When you want Claude to explicitly plan before coding |

### For data work

| Server | What it does |
|---|---|
| [`server-postgres`](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres) | Read-only SQL against a Postgres database |
| [`server-sqlite`](https://github.com/modelcontextprotocol/servers/tree/main/src/sqlite) | Read/write SQLite |
| [`server-redis`](https://github.com/modelcontextprotocol/servers/tree/main/src/redis) | Key inspection and basic commands |

### For product / ops

| Server | What it does |
|---|---|
| [`server-slack`](https://github.com/modelcontextprotocol/servers/tree/main/src/slack) | Post to / read from Slack channels |
| [`server-sentry`](https://github.com/getsentry/sentry-mcp) | Pull error events + stack traces directly into context |
| [`server-linear`](https://github.com/jerhadf/linear-mcp-server) | Read/update Linear issues |

### Browser / web

| Server | What it does |
|---|---|
| [`server-puppeteer`](https://github.com/modelcontextprotocol/servers/tree/main/src/puppeteer) | Headless browser automation — good for UI testing |
| [`server-fetch`](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch) | Retrieve & convert web pages to markdown |

## Example config

A starter `~/.claude/settings.json` with three genuinely useful servers:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    },
    "sequentialthinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequentialthinking"]
    }
  }
}
```

For secrets like tokens, use `${ENV_VAR}` style and export the value in your shell — don't commit tokens into `settings.json`.

## Writing your own

MCP is a spec, not a framework. If the tool you want doesn't have a server, you can write one. Starting points:

- Python: [`mcp` SDK](https://github.com/modelcontextprotocol/python-sdk)
- TypeScript: [`@modelcontextprotocol/sdk`](https://github.com/modelcontextprotocol/typescript-sdk)

A minimal server (TypeScript) is ~50 lines. The big benefit of writing one vs. running Claude through shell scripts: MCP tools get **structured, typed** args and results, so Claude misuses them less.

## Security notes

- **MCP servers run as your user.** A malicious server can do anything you can do. Don't install random community servers without reading the source.
- **Scope tokens narrowly.** A GitHub token for an MCP server doesn't need full repo access. Use fine-grained PATs.
- **Prefer project-level config for secrets-bearing servers.** It keeps per-project tokens out of your global config.
- **Audit what tools each server exposes** — run `/mcp` in Claude Code to see the full tool list.
