---
description: Explain why a specific line of code exists — git blame + commit context
argument-hint: <file>:<line> (e.g. src/auth.ts:42)
---

Explain why the code at $ARGUMENTS exists.

Steps:

1. Parse the argument as `<file>:<line>`. If it's not in that form, ask the user for a file and line.
2. Run `git blame -L <line>,<line> <file>` to find the commit that last touched that line.
3. Run `git show <sha>` to get the commit message and the surrounding change.
4. Read the code around the line (at least 20 lines of context) to understand what it does.
5. If the commit message is vague ("fix bug", "update"), look at other files changed in the same commit — they often reveal the real intent.

Output in this shape:

```
## Line
<file>:<line> — quote the line

## Last changed
<short sha> by <author> on <date>

## Why
1–3 sentences explaining what this line accomplishes AND the motivation
(from the commit + surrounding code). Be honest if the commit message
is uninformative and you're inferring.

## Related context
Other notable things the same commit touched (if any).
```

If the line has never meaningfully changed (blame points to the initial commit with a generic message), say so — sometimes the truthful answer is "this has always been here and no one documented why."
