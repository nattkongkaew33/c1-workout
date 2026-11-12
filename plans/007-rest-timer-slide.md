# 007 — Rest timer bar: slide up from behind the nav, colour cross-fade

- **Status**: DONE
- **Commit**: 74a0b50
- **Severity**: LOW (missed opportunity)
- **Category**: Missed opportunities
- **Estimated scope**: 1 file (`index.html`), 1 CSS line, ~7 one-token JS edits
- **Depends on**: 001 (tokens)

## Problem

The rest-timer bar pops into place above the bottom nav after every set and vanishes on Skip/finish. It also snaps between colours (yellow rest → green "up" / hold → amber "ready") with no transition.

```css
/* index.html:311 (excerpt) */
.timer{position:fixed;left:0;right:0;bottom:calc(58px + env(safe-area-inset-bottom,0px));z-index:5;background:var(--blue);...}
```

Show/hide sites (all `tEl.hidden=...`):

```js
// index.html:1477
function stopWorkoutUI(){clearInterval(tick);tEl.hidden=true;wake(false)}
// index.html:1530 (startTimer)
...textContent="Rest · "+name;tEl.hidden=false;draw();...
// index.html:1532 (timerStop) — two occurrences
...return now<h.go?(endHoldUI(),tEl.hidden=true):finishHold(...)}clearInterval(tick);tEl.hidden=true;restCancel()};
// index.html:1543 (startHold)
  tEl.hidden=false;tEl.classList.add("hold","ready");...
// index.html:1550, 1551 (finishHold)
...if(!h||secs<1){tEl.hidden=true;return}
...if(!t||t.d){tEl.hidden=true;return}
```

It appears tens of times per workout, so the motion stays short.

## Target

- Show: `translateY(100%)→0`, **200ms** `var(--ease-out)`. The nav (z-index 6) is above the timer (z-index 5), so the bar slides out from behind it.
- Hide: back to `translateY(100%)` in 200ms, then `hidden`.
- Background/colour changes: **200ms** `ease`.

```css
.timer{transform:translateY(100%);transition:transform 200ms var(--ease-out),background-color 200ms ease,color 200ms ease}.timer.on{transform:none}
```

## Steps

1. Insert the Target CSS line directly after `index.html:386` (`.timer{border-radius:22px 22px 0 0}`).
2. Directly after `index.html:1510` (`let left=0,tick=null,...;const tEl=document.getElementById("timer");`) add:
   ```js
   let timerT;function showTimer(){clearTimeout(timerT);if(tEl.hidden){tEl.hidden=false;void tEl.offsetWidth}tEl.classList.add("on")}
   function hideTimer(){if(tEl.hidden)return;tEl.classList.remove("on");clearTimeout(timerT);timerT=setTimeout(()=>{if(!tEl.classList.contains("on"))tEl.hidden=true},200)}
   ```
3. Replace every `tEl.hidden=false` with `showTimer()` (2 sites: `:1530`, `:1543`) and every `tEl.hidden=true` with `hideTimer()` (5 sites: `:1477`, `:1532` ×2, `:1550`, `:1551`). In `:1532` the expression `(endHoldUI(),tEl.hidden=true)` becomes `(endHoldUI(),hideTimer())`.
4. `grep -n 'tEl.hidden' index.html` — only the lines inside `showTimer`/`hideTimer` remain. Otherwise STOP.
5. Bump `CACHE` in `sw.js`.

## Boundaries

- `startTimer` is called right after `finishHold` hides the bar (`index.html:1555`). `showTimer` cancels the pending hide, so the bar stays up. Do not reorder those calls.
- Do NOT touch the timer's layout, markup, sounds, notifications or the `wake()` calls.

## Verification

- **Feel check** (390×844, Animations at 10%):
  - Tick a set: the timer slides up from behind the nav; content scroll is unaffected.
  - Tap Skip: it slides down behind the nav and disappears.
  - Let the rest run out: yellow cross-fades to green.
  - Timed hold → Done: the bar stays visible and switches to the rest timer without sliding down and back up.
  - Leave the workout (finish/discard): the bar slides away.
  - Reduced motion emulated: no slide; colour fades remain.
- **Done when**: the bar never appears or disappears in a single frame.
