---
name: test-gen
description: Generate tests for a given file, function, or recently-changed code, with deliberate coverage of edge cases and failure modes. Use when the user types /test-gen, asks to write tests, or says their code lacks coverage.
---

# Test Generator

Write tests that actually catch bugs, not tests that just run. A test that only covers the happy path is a partial test.

## Step 1 — Identify the target

If the user named a file or function, use that. Otherwise, ask:

- "What should I generate tests for? The current file, recently-changed code, or a specific function?"

Then read the target in full — function signature, body, and anything it depends on. Read callers too; they reveal the real-world inputs.

## Step 2 — Detect the test setup

Before writing anything, figure out the repo's conventions:

1. What test framework? (jest, vitest, pytest, go test, rspec, etc.) — check `package.json`, `pyproject.toml`, existing `*_test.*` files.
2. Where do tests live? (alongside source? `__tests__/`? `tests/`?)
3. What's the naming convention? (`foo.test.ts`, `test_foo.py`, `foo_test.go`)
4. What assertion style? (`expect().toBe()`, `assert foo == bar`, etc.)
5. How are fixtures/mocks handled? — look at an existing test file as a template.

If you can't tell, read 1–2 existing tests in the repo. Match their style exactly. A test file that looks alien will not be merged.

## Step 3 — Enumerate cases before writing

List out what you'll test. Don't skip this step — it's what separates real coverage from theater.

For each function or behavior, think through:

- **Happy path** — the canonical case the function is written for.
- **Boundary** — empty input, single-element input, max-size input, zero, negative, very large.
- **Invalid input** — wrong type, null, undefined, malformed, out of range. What *should* happen — error? silent default? document it.
- **Failure modes** — if this calls a network/DB/filesystem, what happens when that fails? When it times out? When it returns garbage?
- **Concurrency** — if this has shared state, what happens under parallel calls?
- **Idempotency** — if this is meant to be safe to retry, does a second call break things?

Not every function needs all of these. Use judgment — a pure function doesn't need concurrency tests.

Present the list to the user *before* writing tests if there are more than ~6 cases. Let them cut scope.

## Step 4 — Write the tests

- **One behavior per test.** If a test has multiple unrelated assertions, split it.
- **Describe the behavior in the test name,** not the mechanics. `returns empty array when input is empty` beats `test_empty`.
- **Arrange / act / assert** — visually separate setup, the call, and the check. Blank lines are fine.
- **Prefer real values over mocks.** Mock only what you must (network, time, randomness). Over-mocked tests pass while prod breaks.
- **Assert the specific thing you care about.** `toBe(42)` beats `toBeTruthy()`.
- **No shared mutable state between tests.** Each test sets up what it needs.

## Step 5 — Run them

Run the new tests and confirm they pass. If they don't, fix the tests (or the code, if the test revealed a real bug — flag this to the user). Report:

- How many tests you added
- Whether they pass
- Any case you *didn't* cover and why (e.g. "skipped concurrency case — would need refactoring the module to be testable")

## Anti-patterns to avoid

- ❌ Tests that just re-run the function and check the return value matches what the function returns. (A test must encode the *expected* behavior independently.)
- ❌ Tests that mock the function being tested.
- ❌ `expect(foo).toBeDefined()` as the only assertion.
- ❌ Deleting or weakening assertions to make a failing test pass.
- ❌ Snapshot tests for anything other than deterministic, stable output.
