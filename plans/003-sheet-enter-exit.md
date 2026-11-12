# 003 — Bottom sheet: interruptible slide in and out, fading scrim

- **Status**: DONE
- **Commit**: 74a0b50
- **Severity**: MEDIUM
- **Category**: Physicality & origin / Interruptibility
- **Estimated scope**: 1 file (`index.html`): 4 CSS lines replaced, ~6 JS edits
- **Depends on**: 001 (tokens)

## Problem

Bottom sheets are the most-used overlay (every food add, settings, day change, finish workout). Entry is a one-shot keyframe that starts at 40% height and 40% opacity with the weak built-in `ease-out`. Every close except drag-down (Close button, tap scrim, Esc, Save/Add) vanishes instantly, and the scrim pops on and off.

```css
/* index.html:339-342 — current */
@keyframes shup{from{transform:translateY(40%);opacity:.4}}
.sheet:not([hidden]){animation:shup .2s ease-out}
.sheet.snap{transition:transform .18s ease-out}.scrim.snap{transition:opacity .18s}
@media (prefers-reduced-motion:reduce){.sheet:not([hidden]){animation:none}}
```

```js
// index.html:1070
function fsOpen(st){FS=st;fsDraw();sheet.hidden=false;scrim.hidden=false}
// index.html:1409 (inside openSheet)
  sheet.hidden=false;scrim.hidden=false;
// index.html:1412
function closeSheet(){sheet.hidden=true;scrim.hidden=true;sheet.classList.remove("snap");scrim.classList.remove("snap");sheet.style.transform="";scrim.style.opacity=""}
// index.html:1467 (end of openFinish)
...WS={date,confirm};drawFinish();sheet.hidden=false;scrim.hidden=false}
```

Drag-to-close (`initSheetDrag`, `index.html:1918-1934`) uses the `.snap` class:

```js
  sheet.addEventListener("touchstart",ev=>{s=null;if(ev.touches.length>1||sheet.classList.contains("snap")||sheet.querySelector(".scan")||ev.target.closest("input,textarea,select")||scrolled(ev.target))return;
...
    if(!s.on){if(dy<-6||Math.abs(dx)>Math.max(8,Math.abs(dy))){s=null;return}if(dy<8)return;s.on=true}
...
  const end=cancel=>{if(!s||!s.on){s=null;return}const d=s;s=null;const h=sheet.offsetHeight;
    sheet.classList.add("snap");scrim.classList.add("snap");
    if(!cancel&&d.v>-.2&&(d.dy>Math.min(150,h*.3)||(d.dy>30&&d.v>.5))){sheet.style.transform="translateY(105%)";scrim.style.opacity=0;
      setTimeout(()=>{FS=null;WS=null;closeSheet()},180)}
    else{sheet.style.transform="";scrim.style.opacity="";setTimeout(()=>{sheet.classList.remove("snap");scrim.classList.remove("snap")},200)}};
```

## Target

- Open: sheet `translateY(100%)` → `0` in **240ms** `var(--ease-drawer)`; scrim opacity 0 → 1 in 240ms.
- Close (any path): sheet → `translateY(100%)` and scrim → 0 in **200ms**, then `hidden`.
- Re-opening during a close retargets from the current position (CSS transition, not keyframes).
- Drag follows the finger with no transition; on release it animates from where it is.

CSS replacing lines 339-342:

```css
.sheet{transform:translateY(100%);transition:transform 240ms var(--ease-drawer)}.sheet.on{transform:none}
.scrim{opacity:0;transition:opacity 240ms var(--ease-drawer)}.scrim.on{opacity:1}
.sheet.closing,.scrim.closing{transition-duration:200ms;pointer-events:none}
.sheet.drag,.scrim.drag{transition:none}
```

(The later `.sheet{position:fixed;...}` and `.scrim{...}` rules at `:344-345` don't set `transform`, `opacity` or `transition`, so there is no conflict.)

## Repo conventions to follow

- The repo already forces a reflow before restarting motion: `function slide(dir){app.classList.remove("swl","swr");void app.offsetWidth;app.classList.add(...)}` (`index.html:1916`). Use the same `void el.offsetWidth` trick.
- `sheet` and `scrim` are global element references already in scope.

## Steps

1. Replace `index.html:339-342` (the four CSS lines quoted above) with the four Target CSS lines.
2. Replace `index.html:1412` (`function closeSheet(){...}`) with:
   ```js
   let sheetT;
   function showSheet(){clearTimeout(sheetT);sheet.classList.remove("closing");scrim.classList.remove("closing");const was=!sheet.hidden&&sheet.classList.contains("on");sheet.hidden=false;scrim.hidden=false;if(!was){sheet.style.transform="";scrim.style.opacity="";void sheet.offsetWidth}sheet.classList.add("on");scrim.classList.add("on")}
   function closeSheet(){if(sheet.hidden)return;clearTimeout(sheetT);sheet.classList.remove("on","drag");scrim.classList.remove("on","drag");sheet.classList.add("closing");scrim.classList.add("closing");scrim.style.opacity="";
     sheetT=setTimeout(()=>{sheet.hidden=true;scrim.hidden=true;sheet.classList.remove("closing");scrim.classList.remove("closing");sheet.style.transform=""},200)}
   ```
3. `index.html:1070` — change `sheet.hidden=false;scrim.hidden=false}` to `showSheet()}`.
4. `index.html:1409` — change `  sheet.hidden=false;scrim.hidden=false;` to `  showSheet();`.
5. `index.html:1467` — at the end of `openFinish`, change `drawFinish();sheet.hidden=false;scrim.hidden=false}` to `drawFinish();showSheet()}`.
6. In `initSheetDrag`:
   a. touchstart: replace `sheet.classList.contains("snap")` with `sheet.classList.contains("closing")`.
   b. touchmove: change `if(dy<8)return;s.on=true}` to `if(dy<8)return;s.on=true;sheet.classList.add("drag");scrim.classList.add("drag")}`.
   c. Replace the whole `const end=cancel=>{...};` with:
   ```js
     const end=cancel=>{if(!s||!s.on){s=null;return}const d=s;s=null;const h=sheet.offsetHeight;
       sheet.classList.remove("drag");scrim.classList.remove("drag");
       if(!cancel&&d.v>-.2&&(d.dy>Math.min(150,h*.3)||(d.dy>30&&d.v>.5))){sheet.style.transform="translateY(100%)";FS=null;WS=null;closeSheet()}
       else{sheet.style.transform="";scrim.style.opacity=""}};
   ```
7. Search for any remaining `"snap"` references: `grep -n '"snap"\|\.snap' index.html` should return nothing. If something else uses `.snap`, STOP and report.
8. Bump `CACHE` in `sw.js`.

## Boundaries

- Do NOT change sheet content/markup or `fsDraw`, `drawFinish`, `openSheet` beyond the lines named.
- Do NOT change the dismiss thresholds (`h*.3`, `150`, `30`, `.5`, `-.2`).
- Do NOT add a reduced-motion rule; plan 002's global rule already drops the transform and keeps the fade. (If 002 is not applied yet, still do not add one.)
- Other code checks `sheet.hidden` to mean "a sheet is open" (`index.html:1447`, `:1870`, `:1885`). That is still correct: the sheet counts as open until its exit finishes.

## Verification

- **Mechanical**: at 390×844 with touch emulation, no console errors on: Food → + Add → Close; tap the scrim; press Esc; add a food (Save); Today → long-press... → day ⋯ menu → Close; Finish workout sheet.
- **Feel check** (Animations panel at 10%):
  - The sheet rises from the bottom edge and the scrim fades in together; no flash at 40% opacity.
  - Close / scrim / Esc / Save all slide the sheet down and fade the scrim; nothing vanishes in one frame.
  - Tap Close and immediately reopen the same sheet: it reverses from where it is, never restarts from the bottom.
  - Drag the sheet down halfway and release slowly: it springs back from the finger's position. Flick it down: it continues down from the finger and the scrim fades.
  - Reduced motion emulated: the sheet appears/disappears without sliding, the scrim still fades.
- **Done when**: every open/close path animates, `grep -c 'sheet.hidden=false' index.html` returns 0, and the existing toast after Save still shows.
