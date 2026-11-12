# 004 — Press feedback on buttons, set checkmarks and day cards

- **Status**: DONE
- **Commit**: 74a0b50
- **Severity**: MEDIUM
- **Category**: Physicality & origin
- **Estimated scope**: 1 file (`index.html`), 3 CSS lines added
- **Depends on**: 001 (tokens)

## Problem

`grep -n ':active' index.html` returns nothing. No pressable element reacts to touch; feedback only arrives when `render()` rebuilds the page. The set checkmark is tapped dozens of times per workout with sweaty thumbs:

```css
/* index.html:233 */
.chk{width:38px;height:38px;border-radius:50%;border:2px solid var(--muted);background:transparent;cursor:pointer;display:grid;place-items:center}
/* index.html:56 */
.btn{height:44px;padding:0 16px;border-radius:10px;border:1px solid var(--line);background:var(--card);font-weight:600;font-size:15px;cursor:pointer}
```

## Target

Subtle scale on press, 160ms strong ease-out, from center:

```css
/* press feedback */
.btn,.chk,.arrows button,.fhead button,.todayb,.seg button,.more,.nav a,.timer button,.back{transition:transform 160ms var(--ease-out)}
.btn:active,.arrows button:active,.fhead button:active,.todayb:active,.seg button:active,.more:active,.nav a:active,.timer button:active,.back:active{transform:scale(0.97)}
.chk:active{transform:scale(0.95)}.wcard[data-go]:active{transform:scale(0.98)}
```

- The `.wcard` already has `transition:transform .15s var(--ease-out),...` from `index.html:69` (after plan 001), so it needs no extra transition.
- During a hold-and-drag the card gets an inline `transform` (`index.html:1437`), which wins over `:active`. The drag is unaffected.
- iOS Safari only applies `:active` when a `touchstart` listener exists; `initPull` already adds one on `document` (`index.html:1870`).

## Repo conventions to follow

- The second-pass style block (`/* ---------- v2 look: chalk & plates ---------- */`, `index.html:362`) is where look refinements go.

## Steps

1. Insert the three Target CSS lines immediately **before** the line
   `@media (prefers-reduced-motion:reduce){*{transition:none!important}}` (index.html:501; after plan 002 it reads `@media (prefers-reduced-motion:reduce){*,*::before,*::after{transition-property:...`). Putting them last keeps them from being overridden by earlier `.btn`/`.nav a` rules.
2. Check that none of the listed selectors already has a `transition` that this would overwrite: `grep -nE '^\.(btn|chk|nav a|todayb|more|back)[^{]*\{[^}]*transition' index.html` — expected: no matches. If there is one, merge the properties instead of overwriting, or STOP.
3. Bump `CACHE` in `sw.js`.

## Boundaries

- Do NOT use a scale smaller than 0.95 or larger than 0.98.
- Do NOT add `:hover` motion (touch fires false hovers).
- Do NOT add press feedback to inputs or the `.fsw .fitem` swipe rows (their transform is used by swipe-to-delete).

## Verification

- **Mechanical**: 390×844, no console errors.
- **Feel check** (touch emulation, Animations at 10%):
  - Press and hold a `.btn`: it shrinks slightly within ~160ms; release returns it.
  - Tap a set checkmark: it dips to 95% on touch; the tick appears after release (re-render). No double animation.
  - Long-press a Today day card to drag it: the card lifts and follows the finger (the scale on press is replaced by the drag transform).
  - Bottom nav tab press dips subtly; the tab doesn't jump when the page changes.
  - Reduced motion emulated: no scale change on press.
- **Done when**: every listed element visibly responds to touch-down on an iPhone.
