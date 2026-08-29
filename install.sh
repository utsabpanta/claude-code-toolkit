#!/usr/bin/env bash
# install.sh - copy skills, agents, hooks, output styles, and status line into ~/.claude/
#
# Prefer the plugin install; it wires hooks for you and this script cannot:
#   /plugin marketplace add utsabpanta/claude-code-toolkit
#   /plugin install guardrails@claude-code-toolkit
#
# Usage:
#   ./install.sh                # interactive: asks what to install
#   ./install.sh --all          # install everything
#   ./install.sh --skills       # just skills
#   ./install.sh --agents       # just agents
#   ./install.sh --hooks        # just hooks (scripts only; you still edit settings.json)
#   ./install.sh --output-styles
#   ./install.sh --statusline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/plugins/guardrails"
PACK="$SCRIPT_DIR/plugins/team-power-pack"
DEST="$HOME/.claude"

ok()   { printf '  \033[32m[ok]\033[0m %s\n' "$1"; }
info() { printf '  \033[36m[--]\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m[!!]\033[0m %s\n' "$1"; }

install_skills() {
  echo "Installing skills to $DEST/skills/ ..."
  mkdir -p "$DEST/skills"
  for skill in "$GUARD/skills"/*/ "$PACK/skills"/*/; do
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

install_agents() {
  echo "Installing agents to $DEST/agents/ ..."
  mkdir -p "$DEST/agents"
  for agent in "$PACK/agents"/*.md; do
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
  mkdir -p "$DEST/hooks/lib"
  cp "$GUARD/hooks/lib/common.sh" "$DEST/hooks/lib/common.sh"
  chmod +x "$DEST/hooks/lib/common.sh"
  ok "lib/common.sh (required by every hook)"
  for hook in "$GUARD/hooks"/*.sh; do
    name=$(basename "$hook")
    target="$DEST/hooks/$name"
    cp "$hook" "$target"
    chmod +x "$target"
    ok "$name"
  done
  echo
  warn "Hooks are NOT active until you register them in ~/.claude/settings.json."
  warn "See docs/hooks.md for the settings block, or install the plugin instead:"
  warn "  /plugin marketplace add utsabpanta/claude-code-toolkit"
  warn "  /plugin install guardrails@claude-code-toolkit   (wires hooks automatically)"
}

install_output_styles() {
  echo "Installing output styles to $DEST/output-styles/ ..."
  mkdir -p "$DEST/output-styles"
  for style in "$PACK/output-styles"/*.md; do
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
  cp "$PACK/statusline/statusline.sh" "$DEST/statusline/"
  chmod +x "$DEST/statusline/statusline.sh"
  ok "statusline.sh"
  echo
  warn "Status line is NOT active until you register it in ~/.claude/settings.json."
  warn 'Add: {"statusLine":{"type":"command","command":"'"$DEST"'/statusline/statusline.sh"}}'
}

install_all() {
  install_skills
  echo
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
  echo "What would you like to install? (space-separated; default: skills agents output-styles)"
  echo "  options: skills agents hooks output-styles statusline all"
  read -rp "> " choice
  choice=${choice:-skills agents output-styles}

  for item in $choice; do
    case "$item" in
      skills) install_skills ;;
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
  --agents)       install_agents ;;
  --hooks)        install_hooks ;;
  --output-styles) install_output_styles ;;
  --statusline)   install_statusline ;;
  --commands)     echo "Slash commands are now skills. Use --skills." && exit 1 ;;
  -h|--help)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    ;;
  "")             interactive ;;
  *)              echo "Unknown flag: $1. Use --help." && exit 1 ;;
esac

echo
echo "Done. Restart Claude Code to pick up new skills/agents/settings."
