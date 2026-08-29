#!/usr/bin/env bash
# guard-dependency-add.sh — PostToolUse(Edit|Write)
#
# When a dependency manifest changes, prompt for a supply-chain check rather
# than letting a new transitive dependency tree land unexamined. Advisory only.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

file="$(hook_field '.tool_input.file_path // .tool_input.path')"
[ -z "$file" ] && allow

case "$(basename "$file")" in
  package.json|requirements.txt|requirements.in|pyproject.toml|go.mod|Cargo.toml|Gemfile|composer.json|pubspec.yaml|build.gradle|build.gradle.kts|pom.xml) ;;
  *) allow ;;
esac

add_context "A dependency manifest was just modified ($file). Before treating this as done, confirm for any newly added package: it is actually needed rather than a few lines of code; it is currently maintained; its name is not a typosquat of a more popular package; and its license is compatible. Run the ecosystem audit command (npm audit, pip-audit, cargo audit, govulncheck) if one is available."
