# 005 — Make the plate ring fill animate and move the workout bar to transform

- **Status**: TODO
- **Commit**: 74a0b50
- **Severity**: LOW
- **Category**: Performance / dead motion
- **Estimated scope**: 1 file (`index.html`), 2 CSS lines, ~5 JS edits
- **Depends on**: 001 (tokens)

## Problem

1. The signature plate ring has a fill transition that never plays: `render()` rebuilds the page via `app.innerHTML=...`, and `plate()` writes the final `stroke-dasharray` straight into the new element, so there is no "from" value.

```css
/* index.html:396 */
.pl-fill{fill:none;stroke-linecap:round;transition:stroke-dasharray .8s cubic-bezier(.2,.8,.2,1)}
```
```js
// index.html:724-726 (excerpt of plate())
function plate(pct,o={}){const sz=o.size||140,...,C=2*Math.PI*r,p=Math.max(0,Math.min(1,pct||0));
  ...<circle class="pl-fill" cx="${c}" cy="${c}" r="${r}" stroke-width="${sw}" stroke="${o.color||"var(--blue)"}" stroke-dasharray="${(C*p).toFixed(1)} ${C.toFixed(1)}" transform="rotate(-90 ${c} ${c})"${p===0?' stroke-opacity="0"':""}/>...
```
Callers: `index.html:732` and `:736` (home hero), `:1058` (Food calories).

2. The workout progress bar animates `width` (a layout property), and it's rebuilt on every set tick, so it also never animates:

```css
/* index.html:207 */
.pbar i{display:block;height:100%;width:0;background:var(--blue);transition:width .3s}
```
```html
<!-- index.html:796 -->
<div class="pbar"><i id="pfill"></i></div>
```
```js
// index.html:1506 (in tickWorkout)
  document.getElementById("pfill").style.width=(tot?dn/tot*100:0)+"%";
```

## Target

- Ring: on each render, the fill animates from the value shown last time for the same ring to the new value, over **600ms** `var(--ease-out)`. On first sight after app launch it animates from 0.
- Bar: full-width element moved with `transform:translateX()`, **300ms** `var(--ease-out)`, from the previous value for the same workout date.

```css
.pl-fill{fill:none;stroke-linecap:round;transition:stroke-dasharray 600ms var(--ease-out)}
.pbar i{display:block;height:100%;width:100%;background:var(--blue);transform:translateX(-100%);transition:transform 300ms var(--ease-out)}
```

(`.pbar` has `overflow:hidden` and rounded corners, so the translated bar is clipped cleanly; translate keeps the fill's rounded end, which `scaleX` would squash.)

## Repo conventions to follow

- Reflow-before-change trick already used in `slide()` (`index.html:1916`): `void app.offsetWidth`.
- Module-level state is plain `let`/`const` near its feature (e.g. `const SCROLL={}` at `index.html:1937`).

## Steps

1. `index.html:396` → replace with the Target `.pl-fill` line.
2. `index.html:207` → replace with the Target `.pbar i` line. Leave `index.html:480-481` (`.pbar{height:10px...}`, `.pbar i{border-radius:5px}`) as they are.
3. In `plate()`, add a key attribute: in the `<circle class="pl-fill" ...` string, right after `class="pl-fill"`, insert `${o.key?` data-k="${o.key}"`:""}`.
4. Pass keys: add `key:"hero"` to the options object of both `plate(` calls in `todayHero` (`index.html:732`, `:736`), and `key:"food"` to the call at `index.html:1058`.
5. Directly above `function render(){` (`index.html:1844`) add:
   ```js
   const PLATE={};
   function playPlates(){app.querySelectorAll(".pl-fill[data-k]").forEach(c=>{const k=c.dataset.k,to=c.getAttribute("stroke-dasharray"),from=PLATE[k]||"0 "+to.split(" ")[1];PLATE[k]=to;if(from===to)return;
     c.style.transition="none";c.setAttribute("stroke-dasharray",from);void c.getBoundingClientRect();c.style.transition="";c.setAttribute("stroke-dasharray",to)})}
   ```
6. Change `function render(){try{renderPage()}catch(e){...}}` so it calls `playPlates()` right after `renderPage()`: `function render(){try{renderPage();playPlates()}catch(e){console.error(e);showCrash(e)}}` (keep the existing catch body exactly).
7. Progress bar: at `index.html:796` change `<i id="pfill"></i>` to `<i id="pfill" style="transform:translateX(${pbarFrom(date)})"></i>` (`date` is already in scope in `viewWorkout`; confirm by reading the function — if the variable has another name, use that).
8. Above `function tickWorkout(){` (`index.html:1501`) add:
   ```js
   let PBAR={d:"",v:0};const pbarFrom=d=>PBAR.d===d?`${(PBAR.v-1)*100}%`:"-100%";
   ```
9. In `tickWorkout`, replace `document.getElementById("pfill").style.width=(tot?dn/tot*100:0)+"%";` with:
   ```js
     const pf=document.getElementById("pfill"),pv=tot?dn/tot:0,pk=app.dataset.date;if(PBAR.d!==pk||PBAR.v!==pv||!pf.dataset.on){void pf.offsetWidth;pf.style.transform=`translateX(${(pv-1)*100}%)`;pf.dataset.on=1;PBAR={d:pk,v:pv}}
   ```
10. Bump `CACHE` in `sw.js`.

## Boundaries

- Do NOT change `plate()`'s geometry, ticks or colours.
- Do NOT add keys to plates other than the three listed.
- Do NOT use `width` for the bar anymore.
- Reduced motion: plan 002's rule drops `stroke-dasharray` and `transform` transitions automatically. Add nothing.

## Verification

- **Mechanical**: 390×844, no console errors on Today, Food and a workout.
- **Feel check** (Animations panel at 10%):
  - Reload on Today: the hero ring sweeps from 0 to its value once.
  - Food → add a 300-cal food: the ring sweeps from the old value to the new; it doesn't restart from 0.
  - Swipe to the previous Food day: the ring moves from today's value to that day's value.
  - In a workout, finish all sets of one exercise: the bar grows from its old length to the new one; unticking shrinks it back.
  - Open a different workout date: its bar fills from empty once.
- **Done when**: both animations visibly play on value change and `grep -n 'pfill").style.width' index.html` returns nothing.
