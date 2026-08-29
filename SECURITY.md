# Security

## What this toolkit is and is not

The `guardrails` plugin bounds **accident and mistake**. It stops an agent from
overwriting your `.env`, force-pushing over a colleague's work, or running
`rm -rf /` because it misread a path.

It is **not** a security boundary against a determined process. A hook is a shell
script the harness runs; anything already executing on your machine can bypass
it. Do not treat it as a sandbox. For actual isolation, use Claude Code's
`sandbox` settings.

## Reporting a vulnerability

If you find a way to make a hook in this repository take a destructive action, or
a hook that leaks credentials into a log, open a
[GitHub Security Advisory](https://github.com/utsabpanta/claude-code-toolkit/security/advisories/new)
rather than a public issue.

For a guardrail that simply fails to catch something, a normal issue is fine —
that is a coverage gap, not a vulnerability.

## What we consider a vulnerability here

- A hook that writes credentials, tokens, or file contents to a location the user
  did not choose. Hook payloads contain both.
- A guardrail whose bypass is not obvious from reading it.
- A hook that can be made to execute attacker-controlled input.
- A policy profile that grants more than it documents.

## What we do not

- A guardrail failing to catch a new variant of a dangerous command. Open an
  issue with the variant.
- Claude Code behavior itself. Report that to
  [anthropics/claude-code](https://github.com/anthropics/claude-code/issues).

## Before you install anything from this repository

Every hook is a shell script that will run automatically with your permissions.
Read it first. That applies to this repository and to every other collection of
Claude Code hooks, including the ones with more stars than this one.

```bash
less plugins/guardrails/hooks/guard-secrets.sh
./scripts/doctor.sh .
```
