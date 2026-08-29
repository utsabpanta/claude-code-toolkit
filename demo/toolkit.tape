# VHS tape for the README demo GIF.
#
#   brew install vhs      # or: go install github.com/charmbracelet/vhs@latest
#   vhs demo/toolkit.tape # writes demo/toolkit.gif
#
# Records the two things that matter: a guardrail refusing a write, and
# doctor.sh finding the bug this toolkit exists for.

Output demo/toolkit.gif

Set Shell "bash"
Set FontSize 16
Set Width 1200
Set Height 760
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 45ms
Set PlaybackSpeed 1.0

# Give the viewer a beat before anything moves.
Sleep 1.5s

Type "# 1. A hook that actually blocks a write to .env"
Enter
Sleep 1s

Type `echo '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/app/.env"}}' \`
Enter
Type "  | plugins/guardrails/hooks/guard-secrets.sh | jq -r '.hookSpecificOutput.permissionDecisionReason'"
Enter
Sleep 3s

Type "# 2. A force push, including the refspec spelling most guards miss"
Enter
Sleep 1s

Type `echo '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push origin +main:main"}}' \`
Enter
Type "  | plugins/guardrails/hooks/guard-force-push.sh | jq -r '.hookSpecificOutput.permissionDecision'"
Enter
Sleep 3s

Type "# 3. Every hook is tested. This is the regression test for the exit-1 bug."
Enter
Sleep 1s

Type "bats tests/ | tail -6"
Enter
Sleep 5s

Type "# 4. Audit any repo's Claude Code setup"
Enter
Sleep 1s

Type "./scripts/doctor.sh . | tail -14"
Enter
Sleep 5s

Sleep 2s
