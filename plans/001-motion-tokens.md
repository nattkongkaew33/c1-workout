# 001 — Add motion easing tokens and use them on existing transitions

- **Status**: TODO
- **Commit**: 74a0b50
- **Severity**: LOW
- **Category**: Easing & duration / Cohesion & tokens
- **Estimated scope**: 1 file (`index.html`), ~8 one-line CSS edits

## Problem

Every transition in the app uses a weak built-in keyword (`ease`, `ease-out`) or no easing at all, and there are no shared motion tokens. Plans 003–008 depend on the tokens added here.

Current code, verbatim:

```css
/* index.html:69 */
.row .wcard{-webkit-touch-callout:none;-webkit-user-drag:none;-webkit-user-select:none;user-select:none;transition:transform .15s,box-shadow .15s,border-color .15s}
/* index.html:320 */
.ptr.back{transition:transform .2s,opacity .2s}
/* index.html:327 */
#app.swl>:not(.foodbar){animation:swl .22s ease-out}#app.swr>:not(.foodbar){animation:swr .22s ease-out}
/* index.html:331 */
#app.swanim>:not(.foodbar){transition:transform .15s ease-out,opacity .15s ease-out}
/* index.html:333 */
.fsw .fitem{position:relative;z-index:1;transition:transform .2s ease-out}
```

## Target

Three tokens on `:root`, and the lines above using them:

```css
--ease-out:cubic-bezier(0.23, 1, 0.32, 1);
--ease-in-out:cubic-bezier(0.77, 0, 0.175, 1);
--ease-drawer:cubic-bezier(0.32, 0.72, 0, 1);
```

## Repo conventions to follow

- Design tokens live in the first `:root{...}` block in `index.html` (starts at line 21, comment `/* "Chalk & plates" ... */` on line 22). Values are written `--name:value;` with no space after the colon.
- `html[data-theme="light"]` overrides colours only; do NOT copy the motion tokens there.
- CSS is minified one-rule-per-line; keep that style.

## Steps

1. In the `:root{` block, after the line `  --glow:#1b2146;`, insert:
   ```css
     --ease-out:cubic-bezier(0.23, 1, 0.32, 1); --ease-in-out:cubic-bezier(0.77, 0, 0.175, 1); --ease-drawer:cubic-bezier(0.32, 0.72, 0, 1);
   ```
2. `index.html:69` — replace `transition:transform .15s,box-shadow .15s,border-color .15s` with
   `transition:transform .15s var(--ease-out),box-shadow .15s ease,border-color .15s ease`.
3. `index.html:320` — replace the line with
   `.ptr.back{transition:transform .2s var(--ease-out),opacity .2s var(--ease-out)}`.
4. `index.html:327` — replace both `ease-out` with `var(--ease-out)`:
   `#app.swl>:not(.foodbar){animation:swl .22s var(--ease-out)}#app.swr>:not(.foodbar){animation:swr .22s var(--ease-out)}`.
5. `index.html:331` — replace with
   `#app.swanim>:not(.foodbar){transition:transform .15s var(--ease-out),opacity .15s var(--ease-out)}`.
6. `index.html:333` — replace with
   `.fsw .fitem{position:relative;z-index:1;transition:transform .2s var(--ease-out)}`.
7. Bump `CACHE` in `sw.js` by one version (e.g. `c1-workout-v30` → `c1-workout-v31`) if this plan ships on its own.

## Boundaries

- Do NOT touch the sheet rules at `index.html:339-342` (plan 003 rewrites them).
- Do NOT touch `.pl-fill` (`:396`) or `.pbar i` (`:207`) (plan 007).
- Do NOT change any duration in this plan; easing only.
- Do NOT change markup or JS.
- If a line doesn't match the excerpt above, STOP and report.

## Verification

- **Mechanical**: open `index.html` in Chromium at 390×844; DevTools console shows no CSS parse warnings; `getComputedStyle(document.documentElement).getPropertyValue('--ease-out')` returns `cubic-bezier(0.23, 1, 0.32, 1)`.
- **Feel check** (touch emulation on, Animations panel at 10%):
  - Swipe a day on Food and let go short: the page snaps back fast at first, then settles — no slow start.
  - Swipe a logged food left and release: the row reaches its open position quickly and decelerates.
  - Pull to refresh and release short: the indicator flies back without a lazy start.
- **Done when**: no `transition`/`animation` in the edited lines uses a bare `ease-out` keyword or omits easing on `transform`.
