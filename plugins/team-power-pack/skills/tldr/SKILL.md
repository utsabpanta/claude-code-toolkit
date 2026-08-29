---
name: tldr
description: This skill should be used when the user types /tldr, or asks for a three-bullet summary of a file, a function, or a diff.
argument-hint: [file path, git ref, or "staged"]
disable-model-invocation: true
allowed-tools: Bash(git:*), Read, Grep, Glob
---

Summarize the following in exactly 3 bullets: $ARGUMENTS

- If it's a **file path**: read the file and summarize what it does, its main exported functions/types, and any gotchas worth knowing.
- If it's `staged` or `HEAD` or a **git ref**: run the appropriate `git diff` and summarize what the change does, why (from commit messages), and anything risky.
- If the argument is **missing or unclear**: ask one brief question.

Rules:
- Exactly 3 bullets. No headers, no preamble, no "here's the summary".
- Each bullet ≤ 20 words.
- Lead with the most important fact — a reader skimming only the first bullet should still get the gist.
