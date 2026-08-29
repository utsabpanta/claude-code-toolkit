# Demo

`toolkit.gif` in the README is generated from `toolkit.tape` with
[VHS](https://github.com/charmbracelet/vhs), so it can be re-recorded whenever
the toolkit changes rather than hand-captured.

## Regenerate

```bash
brew install vhs jq bats-core        # or: go install github.com/charmbracelet/vhs@latest
cd "$(git rev-parse --show-toplevel)"
vhs demo/toolkit.tape
```

Writes `demo/toolkit.gif`. Run it from the repository root — the tape uses
paths relative to it.

## Editing

Keep it under about 40 seconds. The four beats are deliberate:

1. A guardrail refusing a `.env` write, with the reason Claude receives.
2. A force push caught in the `+refspec` spelling most guards miss.
3. The test suite, which is the credibility claim.
4. `doctor.sh` finding real problems.

`Sleep` after each command must exceed how long that command takes, or the
recording cuts off mid-output. The `bats` and `doctor.sh` steps are the slow
ones.

## Swapping it into the README

The README currently shows a static code block in the hero slot, so nothing is
broken before the GIF exists. Once you have recorded and committed
`toolkit.gif`, open `README.md`, delete that code block, and uncomment the
`<img>` tag directly above it.

## Committing

`.gitignore` ignores `demo/*.gif` except `toolkit.gif`, so the README image is
tracked and experiments are not. Keep it under about 5 MB; trim the `Sleep`
values or the `Height` if it grows past that.
