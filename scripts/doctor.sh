#!/usr/bin/env bash
# doctor.sh — audit a Claude Code setup for the mistakes that fail silently.
#
# Usage:
#   ./scripts/doctor.sh [path]      # default: current directory
#
# Checks the project's .claude/ directory and the user's ~/.claude/ for
# configuration that looks correct but does not work. Exits non-zero if any
# ERROR-level finding is present, so it can gate CI.

set -uo pipefail

TARGET="${1:-.}"
ERRORS=0
WARNINGS=0

err()  { printf 'ERROR   %s\n' "$1"; ERRORS=$((ERRORS + 1)); }
wrn()  { printf 'WARN    %s\n' "$1"; WARNINGS=$((WARNINGS + 1)); }
ok()   { printf 'ok      %s\n' "$1"; }
head_() { printf '\n== %s ==\n' "$1"; }

command -v jq >/dev/null 2>&1 || { echo "doctor: jq is required."; exit 2; }

cd "$TARGET" 2>/dev/null || { echo "doctor: cannot enter $TARGET"; exit 2; }
printf 'Claude Code setup audit: %s\n' "$(pwd)"

# ---------------------------------------------------------------------------
head_ "Hook scripts"
# ---------------------------------------------------------------------------
hook_files=$(find . ~/.claude/hooks -maxdepth 4 -name '*.sh' -path '*hook*' 2>/dev/null | sort -u)
if [ -z "$hook_files" ]; then
  ok "no hook scripts found"
else
  while IFS= read -r h; do
    [ -z "$h" ] && continue
    [ -x "$h" ] || err "$h is not executable; Claude Code cannot run it"

    # The headline check: a hook that intends to block but exits 1.
    if grep -qE 'exit[[:space:]]+1' "$h" && grep -qiE 'block|refus|deny|prevent|reject' "$h"; then
      if ! grep -qE 'permissionDecision|exit[[:space:]]+2' "$h"; then
        err "$h looks like a blocking hook but uses 'exit 1'. Exit 1 does NOT block a tool call: use exit 2, or emit hookSpecificOutput.permissionDecision=\"deny\"."
      fi
    fi

    # A blocking hook that writes its reason to stdout without JSON is ignored.
    if grep -qE 'exit[[:space:]]+2' "$h" && ! grep -qE '>&2|permissionDecision' "$h"; then
      wrn "$h exits 2 but never writes to stderr or emits JSON; Claude will see no reason for the block."
    fi

    grep -q 'set -e' "$h" && grep -q 'jq ' "$h" && \
      wrn "$h combines 'set -e' with jq; a jq miss will abort the hook mid-way. Prefer 'set -uo pipefail'."

    grep -qE 'date[[:space:]]+-v[0-9-]' "$h" && \
      err "$h uses BSD-only 'date -v'; this fails on Linux and in CI. Use a portable form."
  done <<< "$hook_files"
  ok "scanned $(printf '%s\n' "$hook_files" | grep -c . ) hook script(s)"
fi

# ---------------------------------------------------------------------------
head_ "settings.json"
# ---------------------------------------------------------------------------
for s in .claude/settings.json .claude/settings.local.json "$HOME/.claude/settings.json"; do
  [ -f "$s" ] || continue
  if ! jq empty "$s" 2>/dev/null; then
    err "$s is not valid JSON"
    continue
  fi
  ok "$s parses"

  jq -e '.mcpServers' "$s" >/dev/null 2>&1 && \
    err "$s contains an 'mcpServers' key. settings.json does not configure MCP servers: use .mcp.json at the project root, or 'claude mcp add'."

  model=$(jq -r '.model // empty' "$s")
  case "$model" in
    ""|inherit) ;;
    *sonnet-4*|*opus-4*|*haiku-3*|*claude-3*)
      wrn "$s pins an older model ('$model'). Current ids: claude-opus-5, claude-sonnet-5, claude-haiku-4-5-20251001." ;;
  esac

  jq -e '.permissions.allow[]? | select(test("^Bash\\((rm|sudo|curl|wget)"))' "$s" >/dev/null 2>&1 && \
    err "$s allowlists a command family that can be destructive or fetch remote code (rm/sudo/curl/wget). Narrow the pattern."

  jq -e '.permissions.defaultMode? == "bypassPermissions"' "$s" >/dev/null 2>&1 && \
    err "$s sets defaultMode to bypassPermissions, which disables every permission prompt."

  # Hook commands must resolve.
  jq -r '.hooks // {} | to_entries[] | .value[]? | .hooks[]? | select(.type=="command") | .command' "$s" 2>/dev/null | \
  while IFS= read -r c; do
    [ -z "$c" ] && continue
    case "$c" in
      *'${CLAUDE_PLUGIN_ROOT}'*|*'${CLAUDE_PROJECT_DIR}'*|*'$CLAUDE_PROJECT_DIR'*) continue ;;
    esac
    script=$(printf '%s' "$c" | awk '{print $1}')
    case "$script" in
      /*) [ -x "$script" ] || echo "WARN    $s references a hook command that is missing or not executable: $script" ;;
    esac
  done
done
[ -f .claude/settings.json ] || [ -f "$HOME/.claude/settings.json" ] || ok "no settings.json found"

# ---------------------------------------------------------------------------
head_ "Skills"
# ---------------------------------------------------------------------------
skills=$(find . -maxdepth 5 -name SKILL.md -not -path './.git/*' 2>/dev/null | sort)
if [ -z "$skills" ]; then
  ok "no skills found"
else
  while IFS= read -r sk; do
    [ -z "$sk" ] && continue
    dir=$(basename "$(dirname "$sk")")
    head -1 "$sk" | grep -q '^---$' || { err "$sk does not start with YAML frontmatter"; continue; }
    fm=$(awk 'NR>1{ if ($0=="---") exit; print }' "$sk")
    name=$(printf '%s' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1 | tr -d '"'"'"'')
    desc=$(printf '%s' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -1)
    [ -n "$name" ] || err "$sk has no 'name' in frontmatter"
    [ -n "$desc" ] || err "$sk has no 'description' in frontmatter"
    [ -n "$name" ] && [ "$name" != "$dir" ] && err "$sk: frontmatter name '$name' does not match directory '$dir'"
    printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' || \
      [ -z "$name" ] || err "$sk: name '$name' must be lowercase-hyphenated"
    [ "${#desc}" -gt 1024 ] && err "$sk: description exceeds the 1024-character limit"
    [ "${#desc}" -lt 30 ] && [ -n "$desc" ] && wrn "$sk: description is very short; Claude matches skills on this text"
    words=$(wc -w < "$sk" | tr -d '[:space:]')
    [ "$words" -gt 3000 ] 2>/dev/null && wrn "$sk is ${words} words. Move detail into references/ so the body stays under ~2000."
  done <<< "$skills"
  ok "checked $(printf '%s\n' "$skills" | grep -c .) skill(s)"
fi

# ---------------------------------------------------------------------------
head_ "Agents"
# ---------------------------------------------------------------------------
agents=$(find . -maxdepth 4 -path '*agents/*.md' -not -path './.git/*' 2>/dev/null | sort)
if [ -z "$agents" ]; then
  ok "no agents found"
else
  while IFS= read -r a; do
    [ -z "$a" ] && continue
    head -1 "$a" | grep -q '^---$' || { err "$a does not start with YAML frontmatter"; continue; }
    fm=$(awk 'NR>1{ if ($0=="---") exit; print }' "$a")
    printf '%s' "$fm" | grep -q '^name:' || err "$a has no 'name'"
    printf '%s' "$fm" | grep -q '^description:' || err "$a has no 'description'"
    mdl=$(printf '%s' "$fm" | sed -n 's/^model:[[:space:]]*//p' | head -1)
    case "$mdl" in
      ""|sonnet|opus|haiku|fable|inherit|claude-*) ;;
      *) wrn "$a: unrecognized model '$mdl'. Valid: sonnet, opus, haiku, fable, inherit, or a full model id." ;;
    esac
  done <<< "$agents"
  ok "checked $(printf '%s\n' "$agents" | grep -c .) agent(s)"
fi

# ---------------------------------------------------------------------------
head_ "Repository hygiene"
# ---------------------------------------------------------------------------
if git rev-parse --git-dir >/dev/null 2>&1; then
  git ls-files --error-unmatch .claude/settings.local.json >/dev/null 2>&1 && \
    err ".claude/settings.local.json is tracked in git. It is a personal file; add it to .gitignore and untrack it."
  [ -f .gitignore ] || wrn "no .gitignore in this repository"
  for p in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    [ -f "$p" ] && { jq empty "$p" 2>/dev/null && ok "$p parses" || err "$p is not valid JSON"; }
  done
else
  ok "not a git repository; skipping hygiene checks"
fi

# ---------------------------------------------------------------------------
printf '\n== Summary ==\n%d error(s), %d warning(s)\n' "$ERRORS" "$WARNINGS"
[ "$ERRORS" -eq 0 ] || exit 1
