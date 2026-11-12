# 002 — Reduced motion: drop movement, keep fades

- **Status**: TODO
- **Commit**: 74a0b50
- **Severity**: MEDIUM
- **Category**: Accessibility
- **Estimated scope**: 1 file (`index.html`), 1 CSS line replaced

## Problem

```css
/* index.html:501 — current */
@media (prefers-reduced-motion:reduce){*{transition:none!important}}
```

With iOS Reduce Motion on, this kills **every** transition, including opacity and colour fades that help comprehension. A sheet or page that springs back after a short swipe jumps instantly. Meanwhile the infinite scanner line still moves:

```css
/* index.html:355 */
.scan .frame::after{...;animation:scanline 1.6s ease-in-out infinite alternate}
```

Reduced motion should mean fewer and gentler animations, not zero.

## Target

```css
@media (prefers-reduced-motion:reduce){*,*::before,*::after{transition-property:opacity,color,background-color,border-color,box-shadow!important}.scan .frame::after{animation:none}}
```

Why this works: transitions on `transform` (all movement) are dropped everywhere, while opacity/colour transitions keep running with their existing durations. Finger-driven transforms set from JS still follow the finger (user-controlled motion is fine). The refresh spinners (`rspin`) are kept on purpose: they show loading by rotating in place, with no movement across the screen.

## Repo conventions to follow

- Reduced-motion rules already exist as one-liners, e.g. `index.html:328`:
  `@media (prefers-reduced-motion:reduce){#app.swl>*,#app.swr>*{animation:none!important}}` — keep that line as is.

## Steps

1. Replace `index.html:501` (the line quoted above) with the Target line exactly.
2. Do not edit `index.html:328`. Leave `index.html:342` alone too (plan 003 removes it).
3. Bump `CACHE` in `sw.js` if shipping on its own.

## Boundaries

- Do NOT add `animation:none` for `rspin`.
- Do NOT touch JS.
- If line 501 doesn't match, search for `prefers-reduced-motion:reduce){*{transition:none` and edit that; if absent, STOP.

## Verification

- **Mechanical**: no console CSS errors at 390×844.
- **Feel check**: DevTools → Rendering → "Emulate CSS prefers-reduced-motion: reduce".
  - Swipe a Food day short and let go: the content stops sliding back (jumps), but if opacity was reduced it fades back.
  - Open the barcode scanner: the red line is static.
  - Tap ↻ Refresh: the icon still spins.
  - Turn emulation off: everything moves as before.
- **Done when**: with reduce on, no element moves via a CSS transition or the scan keyframe; opacity transitions still play.
