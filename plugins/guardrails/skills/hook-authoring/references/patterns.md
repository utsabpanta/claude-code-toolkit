# Tested hook patterns

Each pattern below is implemented and covered by tests in this repository.
Read the real script alongside the sketch: `plugins/guardrails/hooks/`.

## Block a write by file identity

`guard-secrets.sh`. Match on `basename` first, then on the path, because
`*.env` and `*/secrets/*` are different questions.

```bash
base="$(basename "$file")"
case "$base" in
  .env|.env.*|*.env) deny "..." ;;
esac
case "$file" in
  */secrets/*|secrets/*) deny "..." ;;
esac
```

Order matters inside a `case`: put specific filenames before wildcards, or
`*.db` swallows `Thumbs.db`.

## Block a shell command by shape

`guard-force-push.sh`. Detect the subcommand and the dangerous flag separately,
then require both. Checking for `--force` alone matches `grep -r force`.

```bash
if printf '%s' "$cmd" | grep -qE 'git([[:space:]][^|;&]*)?[[:space:]]push([[:space:]]|$)'; then
  if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])(-f|--force|--force-with-lease)([[:space:]]|=|$)'; then
    deny "..."
  fi
fi
```

Enumerate the spellings. `git push -f`, `--force`, `--force-with-lease`,
`--force-if-includes`, and the refspec form `git push origin +main:main` are all
the same operation. A deny list that names only one is theatre.

Allow a global flag between `git` and the subcommand (`git -C /repo push`), or
the hook misses the most common scripted form.

## Two-tier severity

`guard-destructive.sh`. `deny` what is never intended; `ask` what is legitimate
but destroys work. A guardrail that blocks `git reset --hard` outright gets
uninstalled the first afternoon someone needs it.

```bash
m 'mkfs(\.|[[:space:]])'          && deny "..."   # unrecoverable
m 'git[[:space:]]+reset.*--hard'  && ask  "..."   # legitimate, destructive
```

## One-shot override

`guard-force-push.sh`. When a block has a legitimate escape, make the escape
explicit, external, time-boxed, and single-use — so it cannot be granted by the
agent itself.

```bash
override="$HOME/.claude/allow-force-push"
if [ -f "$override" ] && [ -n "$(find "$override" -mmin -10 2>/dev/null)" ]; then
  rm -f "$override"   # consume it
  allow
fi
```

## Inject context instead of blocking

`guard-dependency-add.sh`, `context-brief.sh`. `PostToolUse` cannot undo
anything, so the useful move is to tell Claude what to check next.

```bash
add_context "A dependency manifest changed ($file). Before treating this as done, confirm ..."
```

`context-brief.sh` uses the same mechanism on `SessionStart` to supply branch,
divergence, and open-PR state that Claude would otherwise spend three tool calls
discovering.

## Append-only audit trail

`audit-log.sh`. One JSON object per line, bounded, local. Never send hook
payloads off the machine: they contain file contents and command strings.

```bash
printf '%s' "$HOOK_INPUT" | jq -c '{ts: $ts, event: .hook_event_name, tool: .tool_name,
  target: (.tool_input.file_path // .tool_input.command // null)}' >> "$logfile"
```

Bound the file. An audit log that fills the disk is an outage.

## Fail open, always

Every hook here calls `require_jq`, which exits 0 with a warning when `jq` is
missing. A guardrail that breaks the session on a machine without `jq` gets
disabled, and a disabled guardrail protects nothing.

The same reasoning drives `set -uo pipefail` rather than `set -euo pipefail`:
under `set -e`, a `jq` filter that matches nothing aborts the hook partway
through — usually before the line that does the blocking.
