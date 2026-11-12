# 008 — Celebrate a personal record

- **Status**: DONE
- **Commit**: 74a0b50
- **Severity**: LOW (missed opportunity)
- **Category**: Missed opportunities
- **Estimated scope**: 1 file (`index.html`), 3 CSS lines, ~3 JS edits
- **Depends on**: 001 (tokens), 006 (toast `.on` class and `t.classList.remove("pr")` in `toast()`)

## Problem

A new PR (🏆) is the rarest, most emotional moment in the app, and it gets the same plain toast as "Saved". Sites:

```js
// index.html:1631 (set checkmark handler)
      const pr=prType(histBest(e.n,date),t);if(pr){toast(`🏆 ${pr}! ${e.n} · ${...}${t.r}`);setTimeout(()=>beep([523,659,784,1047],.12,.03,.5),700)}}
// index.html:1554 (finishHold)
  const pr=prType(histBest(e.n,h.date),t);toast(pr?`🏆 ${pr}! ${e.n} · ${secs}s`:`✓ Set ${h.j+1} logged · ${secs}s`);if(pr)setTimeout(()=>beep([523,659,784,1047],.12,.03,.5),700);
```

Because it's rare, it can use a playful keyframe. It's a one-shot, so a keyframe is fine here (no interruption concern).

## Target

- The PR toast pops: scale `0.9 → 1.06 → 1` over **420ms**, using `var(--ease-out)` between keyframes, plus a short glow ring in the accent colour that fades out.
- A double-tap vibration `[20,40,20]` where supported.
- With reduced motion: no pop, the toast just fades in (plan 006).

```css
@keyframes prpop{0%{transform:translateX(-50%) scale(.9)}60%{transform:translateX(-50%) scale(1.06)}100%{transform:translateX(-50%) scale(1)}}
@keyframes prglow{from{box-shadow:0 0 0 0 color-mix(in srgb,var(--blue) 70%,transparent),0 10px 30px -10px rgba(0,0,0,.6)}to{box-shadow:0 0 0 14px transparent,0 10px 30px -10px rgba(0,0,0,.6)}}
.toast.on.pr{animation:prpop 420ms var(--ease-out),prglow 700ms var(--ease-out)}
@media (prefers-reduced-motion:reduce){.toast.on.pr{animation:none}}
```

## Steps

1. Insert the four Target CSS lines directly after the `.toast{opacity:0;...}.toast.on{...}` line added by plan 006. If that line isn't there, STOP: plan 006 must ship first.
2. Directly after `function hideToast(){...}` (added by plan 006) add:
   ```js
   function celebrate(){const t=document.getElementById("toast");t.classList.remove("pr");void t.offsetWidth;t.classList.add("pr");try{navigator.vibrate&&navigator.vibrate([20,40,20])}catch(e){}}
   ```
3. `index.html:1631` — change `if(pr){toast(`…`);setTimeout(` to `if(pr){toast(`…`);celebrate();setTimeout(` (insert `celebrate();` right after the `toast(...)` call; keep the message template exactly).
4. `index.html:1554` — after the `toast(pr?…:…);` call, change `if(pr)setTimeout(` to `if(pr){celebrate();setTimeout(()=>beep([523,659,784,1047],.12,.03,.5),700)}` (remove the trailing `;` duplication carefully so the line stays valid).
5. Bump `CACHE` in `sw.js`.

## Boundaries

- Do NOT change PR detection (`prType`, `histBest`), the beep, or toast timings.
- Do NOT add celebration to non-PR toasts.

## Verification

- **Feel check**: in a workout, enter a weight above your previous best and tick the set (or test with a fresh exercise name).
  - The 🏆 toast pops slightly past full size and settles; an accent ring expands and fades; the chime plays ~0.7s later.
  - A following normal toast ("Saved") shows without the pop (`pr` class removed).
  - In Animations panel at 10%: the toast stays horizontally centered through the pop.
  - Reduced motion emulated: no pop or ring.
- **Done when**: only PR toasts pop, and the console is clean.
