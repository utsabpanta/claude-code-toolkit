#!/usr/bin/env bash
# guard-destructive.sh — PreToolUse(Bash)
#
# Two tiers:
#   deny — commands that are unrecoverable and effectively never intended
#   ask  — commands that are legitimate but destroy work if the agent misjudged
#
# Tune the patterns to your environment; this errs toward asking, not blocking.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

cmd="$(hook_field '.tool_input.command')"
[ -z "$cmd" ] && allow

m() { printf '%s' "$cmd" | grep -qE "$1"; }

# --- Tier 1: unrecoverable ---------------------------------------------------
m 'rm[[:space:]]+(-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+)+(/|/\*|~|~/\*|\$HOME|\$\{HOME\})([[:space:]]|$)' \
  && deny "Refused: this deletes the filesystem root or the entire home directory. There is no recovery path."
m 'mkfs(\.|[[:space:]])' \
  && deny "Refused: mkfs formats a filesystem and destroys every file on the target device."
m 'dd[[:space:]]+.*of=/dev/(sd|nvme|disk|hd)' \
  && deny "Refused: writing raw blocks to a block device destroys the partition table."
m '>[[:space:]]*/dev/(sd|nvme|disk|hd)' \
  && deny "Refused: redirecting output onto a raw block device corrupts the disk."
m ':\(\)[[:space:]]*\{[[:space:]]*:\|:' \
  && deny "Refused: that is a fork bomb."
m '(curl|wget)[[:space:]][^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh' \
  && deny "Refused: piping a downloaded script straight into a shell executes unreviewed remote code. Download it, read it, then run it."
m 'chmod[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*777[[:space:]]+/([[:space:]]|$)' \
  && deny "Refused: chmod 777 on / makes every file on the system world-writable."

# --- Tier 2: destroys work, but sometimes correct ----------------------------
m 'git[[:space:]]+reset[[:space:]]+(--hard|.*[[:space:]]--hard)' \
  && ask "git reset --hard discards every uncommitted change in the working tree. Confirm this is intended and that nothing valuable is unstaged."
m 'git[[:space:]]+clean[[:space:]]+(-[a-zA-Z]*[fd][a-zA-Z]*)' \
  && ask "git clean deletes untracked files permanently. They are not in git, so they cannot be recovered. Confirm before proceeding."
m 'git[[:space:]]+(branch[[:space:]]+(-D|--delete[[:space:]]+--force)|checkout[[:space:]]+--[[:space:]])' \
  && ask "This discards a branch or local file changes with no recovery path. Confirm before proceeding."
m '(DROP|TRUNCATE)[[:space:]]+(TABLE|DATABASE|SCHEMA)' \
  && ask "This SQL drops or truncates a table, database, or schema. Confirm the target is not production and that a backup exists."
m 'DELETE[[:space:]]+FROM[[:space:]]+[A-Za-z_.\"]+[[:space:]]*(;|$)' \
  && ask "This DELETE has no WHERE clause and will remove every row in the table. Confirm this is intended."
m 'rm[[:space:]]+(-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+)+' \
  && ask "This is a recursive or forced delete. Confirm the path is correct before it runs."
m 'chmod[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*777' \
  && ask "chmod 777 makes files world-writable. Use a narrower mode unless there is a specific reason."

allow
