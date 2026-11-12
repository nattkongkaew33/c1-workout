# Animation plans

From an `improve-animations` audit of `index.html` at commit `74a0b50`. Each plan is self-contained; run them in order.
All edits are in `index.html`. Bump `CACHE` in `sw.js` once per release (one bump covers several plans shipped together).

| # | Plan | Severity | Status | Depends on |
|---|---|---|---|---|
| 001 | [Motion easing tokens](001-motion-tokens.md) | LOW | TODO | — |
| 002 | [Reduced motion: drop movement, keep fades](002-reduced-motion.md) | MEDIUM | TODO | — |
| 003 | [Bottom sheet slide in/out + scrim fade](003-sheet-enter-exit.md) | MEDIUM | TODO | 001 |
| 004 | [Press feedback](004-press-feedback.md) | MEDIUM | TODO | 001 |
| 005 | [Plate ring + workout bar animate](005-plate-ring-progress-bar.md) | LOW | TODO | 001 |
| 006 | [Toast enter/exit](006-toast-enter-exit.md) | LOW | TODO | 001 |
| 007 | [Rest timer slide](007-rest-timer-slide.md) | LOW | TODO | 001 |
| 008 | [PR celebration](008-pr-celebration.md) | LOW | TODO | 001, 006 |

## Recommended order

1. **001** first: every other plan uses its `--ease-out` / `--ease-drawer` tokens.
2. **002** next: its global reduced-motion rule is why the later plans need no reduced-motion rules of their own (except 008's keyframe).
3. **003 → 004**: the most-felt improvements.
4. **005, 006, 007** in any order.
5. **008** after 006.

## Already right (leave alone)

- Finger-following swipes, swipe-to-delete with resistance past the stop, and drag-to-close use velocity-based decisions.
- The scanner line uses `ease-in-out` (correct for constant back-and-forth motion).
- Tab switches don't animate (correct: they're used many times a day).

## Release

Per `CLAUDE.md`: test at 390×844, bump `sw.js` `CACHE`, push to `main`, then tap ↻ Refresh in the app.
