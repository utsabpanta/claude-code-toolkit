---
description: Compare two or more options with a structured tradeoff matrix
argument-hint: <option A> vs <option B> [vs option C ...]
---

Produce a tradeoff analysis of: $ARGUMENTS

If $ARGUMENTS doesn't clearly contain two or more options, ask the user to specify them.

## Process

1. **State each option neutrally in one sentence.** Don't pre-load with opinions.
2. **Pick 4–6 axes of comparison** relevant to the decision. Common ones:
   - Implementation effort
   - Ongoing maintenance cost
   - Reversibility
   - Performance / scalability
   - Operational complexity
   - Team familiarity
   - Security / compliance exposure
   - Time to ship
   - Dependency / lock-in risk
   Pick the axes that actually matter here — skip the irrelevant ones.

3. **Score each option on each axis.** Use concrete wording ("2 weeks", "none", "high — new infra to operate") over symbols (✅/❌) — concrete is more useful than ceremonial.

4. **Write a recommendation paragraph.** Which option, under what conditions, and what would change your mind.

## Output

```
## Options
- **A:** <one-line description>
- **B:** <one-line description>

## Tradeoff matrix

| Axis | Option A | Option B |
|---|---|---|
| Implementation effort | ... | ... |
| Maintenance cost | ... | ... |
| Reversibility | ... | ... |
| ... | ... | ... |

## Recommendation
<Which option, 2–3 sentences on why, and what would change your mind. Be honest if it's a coin-flip.>

## What we're implicitly choosing
<Name the tradeoff the recommendation accepts. Every choice costs something — make it explicit.>
```

## Rules
- If one option is clearly better on every axis, say so. Don't fabricate balance.
- If you lack information on an axis, write "unknown — would need to check X" instead of guessing.
- Keep the matrix readable — long cells ruin it. One short phrase per cell.
