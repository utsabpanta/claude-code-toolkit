#!/usr/bin/env bash
# context-brief.sh — SessionStart
#
# Injects the repository state Claude would otherwise spend three tool calls
# discovering: branch, divergence from upstream, uncommitted work, and any open
# PR for the branch. Advisory context only.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

git rev-parse --git-dir >/dev/null 2>&1 || allow

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ -z "$branch" ] && allow

parts="Repository state at session start: branch ${branch}."

dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d '[:space:]')"
if [ -n "$dirty" ] && [ "$dirty" -gt 0 ] 2>/dev/null; then
  parts="$parts ${dirty} file(s) with uncommitted changes."
else
  parts="$parts Working tree clean."
fi

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"
if [ -n "$upstream" ]; then
  counts="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null)"
  behind="$(printf '%s' "$counts" | awk '{print $1}')"
  ahead="$(printf '%s' "$counts" | awk '{print $2}')"
  [ "${ahead:-0}" != "0" ] && parts="$parts ${ahead} commit(s) ahead of ${upstream}."
  [ "${behind:-0}" != "0" ] && parts="$parts ${behind} commit(s) behind ${upstream} - consider pulling before starting work."
fi

if command -v gh >/dev/null 2>&1; then
  pr="$(gh pr view --json number,title,isDraft -q '"#\(.number) \(.title)" + (if .isDraft then " (draft)" else "" end)' 2>/dev/null)"
  [ -n "$pr" ] && parts="$parts Open PR for this branch: ${pr}."
fi

add_context "$parts"
