---
description: Summarize a file, function, or diff in 3 bullets
argument-hint: [file or path or "HEAD" or "staged"]
---

Summarize the following in exactly 3 bullets: $ARGUMENTS

- If it's a **file path**: read the file and summarize what it does, its main exported functions/types, and any gotchas worth knowing.
- If it's `staged` or `HEAD` or a **git ref**: run the appropriate `git diff` and summarize what the change does, why (from commit messages), and anything risky.
- If the argument is **missing or unclear**: ask one brief question.

Rules:
- Exactly 3 bullets. No headers, no preamble, no "here's the summary".
- Each bullet ≤ 20 words.
- Lead with the most important fact — a reader skimming only the first bullet should still get the gist.
