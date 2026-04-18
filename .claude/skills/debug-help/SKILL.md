---
name: debug-help
description: Debug a bug or unexpected behavior using a systematic hypothesis-driven method, rather than guessing. Use when the user types /debug-help, says something is broken, or is stuck on a bug.
---

# Debug Help

Debugging is hypothesis generation and falsification, not guessing. Your job is to keep the user honest about that process.

## Step 1 — Get the symptom crisp

Before doing anything else, make sure you can answer:

1. **What is the user seeing?** (exact error message, exact wrong output)
2. **What did they expect to see?**
3. **What steps reproduce it?** (command, input, environment)
4. **When did it start?** (new code? new dep? new data? always?)
5. **Is it deterministic?** (fails every time vs. sometimes)

If any of these is fuzzy, ask — one question at a time, the most load-bearing one first. Don't proceed on a guess.

## Step 2 — Form 2–3 hypotheses, not 1

The trap in debugging is latching onto the first plausible explanation. Force breadth:

> "Given this symptom, here are 2–3 things that could cause it. I'll rank them by likelihood and probe the most likely first."

Name each hypothesis as a falsifiable claim: "the config isn't being loaded", "the cache is stale", "there's a race between X and Y". Then for each, write down the one probe that would disprove it.

## Step 3 — Probe cheaply

Pick the probe that's fastest to run and most discriminating. Cheap probes, in order of preference:

1. Read the code path end-to-end. Bugs are usually visible if you actually trace execution.
2. Check logs / stderr / browser console. The error often names the problem.
3. Add a `print` or `console.log` at the point where behavior diverges from expectation.
4. Run the failing case in isolation (unit test, REPL, curl).
5. Bisect: last-known-good commit vs. current. `git log`, `git bisect` if deterministic.
6. Diff the failing env vs. a working one (env vars, dep versions, config).

Only reach for the debugger / strace / tcpdump if the cheaper probes don't narrow it.

## Step 4 — Update beliefs after each probe

After every probe, state what you learned:

> "Probe: added log before line 42. Result: the function is being called with `x=null`. This rules out hypothesis (1) — the config is loaded. Hypothesis (2) — upstream is passing null — is now most likely."

This keeps the process grounded. If a probe doesn't change your beliefs, you picked the wrong probe.

## Step 5 — Verify the fix

When you find the cause:

1. **Explain the root cause in one sentence** — not the fix, the cause. "The cache key didn't include the user ID, so user A's data was served to user B."
2. **Write a test that fails without the fix and passes with it.** This is the only proof you're actually fixing the bug you think you're fixing.
3. **Apply the fix.**
4. **Re-run the original reproduction** to confirm the symptom is gone.
5. **Look for siblings.** If the cache-key bug hit endpoint A, it might also hit endpoints B and C. Do a quick grep.

## Anti-patterns to flag

If you catch the user or yourself doing any of these, say so:

- **Shotgun fixes.** Changing three things at once. You won't know which one worked.
- **"It works now, move on."** If you don't know *why* it started working, it'll come back. Investigate until you do.
- **Blaming the framework/compiler/OS.** Real in ~1% of cases. Exhaust your code first.
- **Adding a try/except that swallows the error.** That's hiding the bug, not fixing it.
- **Reverting the commit without understanding it.** Sometimes the right call, but do it deliberately, not reflexively.

## Output

As you work, narrate in short updates: what hypothesis you're testing, what you found, what's next. When done, give a one-paragraph summary: root cause, fix, test that now covers it.
