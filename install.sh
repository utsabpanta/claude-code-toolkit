#!/usr/bin/env bash
# install.sh — copy skills, agents, hooks, output styles, and status line into ~/.claude/
#
# Usage:
#   ./install.sh                # interactive: asks what to install
#   ./install.sh --all          # install everything
#   ./install.sh --skills       # just skills
#   ./install.sh --commands     # just slash commands
#   ./install.sh --agents       # just agents
#   ./install.sh --hooks        # just hooks (scripts only; you still edit settings.json)
#   ./install.sh --output-styles
#   ./install.sh --statusline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/.claude"
DEST="$HOME/.claude"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
info() { printf '  \033[36m•\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

install_skills() {
  echo "Installing skills to $DEST/skills/ ..."
  mkdir -p "$DEST/skills"
  for skill in "$SRC/skills"/*/; do
    name=$(basename "$skill")
    target="$DEST/skills/$name"
    if [ -e "$target" ]; then
      warn "skip $name (already exists — remove it first to overwrite)"
    else
      cp -r "$skill" "$target"
      ok "$name"
    fi
  done
}

install_commands() {
  echo "Installing slash commands to $DEST/commands/ ..."
  mkdir -p "$DEST/commands"
  for cmd in "$SRC/commands"/*.md; do
    name=$(basename "$cmd")
    target="$DEST/commands/$name"
    if [ -e "$target" ]; then
      warn "skip $name (already exists)"
    else
      cp "$cmd" "$target"
      ok "$name"
    fi
  done
}

install_agents() {
  echo "Installing agents to $DEST/agents/ ..."
  mkdir -p "$DEST/agents"
  for agent in "$SRC/agents"/*.md; do
    name=$(basename "$agent")
    target="$DEST/agents/$name"
    if [ -e "$target" ]; then
      warn "skip $name (already exists)"
    else
      cp "$agent" "$target"
      ok "$name"
    fi
  done
}

install_hooks() {
  echo "Installing hook scripts to $DEST/hooks/ ..."
  mkdir -p "$DEST/hooks"
  for hook in "$SRC/hooks"/*.sh; do
    name=$(basename "$hook")
    target="$DEST/hooks/$name"
    cp "$hook" "$target"
    chmod +x "$target"
    ok "$name"
  done
  echo
  warn "Hooks are NOT active until you register them in ~/.claude/settings.json."
  warn "See HOOKS.md (or each script's header comment) for the settings block to add."
}

install_output_styles() {
  echo "Installing output styles to $DEST/output-styles/ ..."
  mkdir -p "$DEST/output-styles"
  for style in "$SRC/output-styles"/*.md; do
    name=$(basename "$style")
    target="$DEST/output-styles/$name"
    if [ -e "$target" ]; then
      warn "skip $name (already exists)"
    else
      cp "$style" "$target"
      ok "$name"
    fi
  done
  echo
  info "Activate a style via /config in Claude Code, or add \"outputStyle\": \"<name>\" to settings.json"
}

install_statusline() {
  echo "Installing status line to $DEST/statusline/ ..."
  mkdir -p "$DEST/statusline"
  cp "$SRC/statusline/statusline.sh" "$DEST/statusline/"
  chmod +x "$DEST/statusline/statusline.sh"
  ok "statusline.sh"
  echo
  warn "Status line is NOT active until you register it in ~/.claude/settings.json."
  warn 'Add: {"statusLine":{"type":"command","command":"'"$DEST"'/statusline/statusline.sh"}}'
}

install_all() {
  install_skills
  echo
  install_commands
  echo
  install_agents
  echo
  install_output_styles
  echo
  install_hooks
  echo
  install_statusline
}

interactive() {
  echo "What would you like to install? (space-separated; default: skills commands agents output-styles)"
  echo "  options: skills commands agents hooks output-styles statusline all"
  read -rp "> " choice
  choice=${choice:-skills commands agents output-styles}

  for item in $choice; do
    case "$item" in
      skills) install_skills ;;
      commands) install_commands ;;
      agents) install_agents ;;
      hooks) install_hooks ;;
      output-styles) install_output_styles ;;
      statusline) install_statusline ;;
      all) install_all ;;
      *) warn "unknown option: $item" ;;
    esac
    echo
  done
}

case "${1:-}" in
  --all)          install_all ;;
  --skills)       install_skills ;;
  --commands)     install_commands ;;
  --agents)       install_agents ;;
  --hooks)        install_hooks ;;
  --output-styles) install_output_styles ;;
  --statusline)   install_statusline ;;
  -h|--help)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    ;;
  "")             interactive ;;
  *)              echo "Unknown flag: $1. Use --help." && exit 1 ;;
esac

echo
echo "Done. Restart Claude Code to pick up new skills/agents/settings."
