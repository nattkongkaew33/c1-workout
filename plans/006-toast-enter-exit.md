# 006 — Toast: rise and fade in, fade out

- **Status**: DONE
- **Commit**: 74a0b50
- **Severity**: LOW (missed opportunity)
- **Category**: Missed opportunities / Interruptibility
- **Estimated scope**: 1 file (`index.html`), 1 CSS line, 2 JS edits
- **Depends on**: 001 (tokens)

## Problem

The toast (Saved, Added, Deleted + Undo, PRs) appears and disappears in one frame:

```css
/* index.html:343 */
.toast{position:fixed;left:50%;transform:translateX(-50%);bottom:calc(140px + env(safe-area-inset-bottom,0px));z-index:12;...}
```
```js
// index.html:1556
let toastT;function toast(m,act,fn){const t=document.getElementById("toast");t.textContent=m;if(act){const b=document.createElement("button");b.type="button";b.textContent=act;b.onclick=()=>{t.hidden=true;fn()};t.appendChild(b)}t.hidden=false;clearTimeout(toastT);toastT=setTimeout(()=>t.hidden=true,act?5000:2600)}
// index.html:1197
  document.getElementById("toast").hidden=true;fsOpen({mode:"aiprep",img,meal,hint:""})}
```

Toasts are often fired back to back (e.g. "Loading photo…" then a result), so the motion must be a transition (retargets), never a keyframe (restarts).

## Target

- Enter: `opacity 0→1`, `translateY(8px)→0`, **200ms** `var(--ease-out)`.
- Exit: same in reverse, 200ms, then `hidden`.
- A new toast while one is showing: text swaps in place, no re-entrance.
- `translateX(-50%)` centering must stay in every transform.

```css
.toast{opacity:0;transform:translateX(-50%) translateY(8px);transition:opacity 200ms var(--ease-out),transform 200ms var(--ease-out)}.toast.on{opacity:1;transform:translateX(-50%)}
```

## Repo conventions to follow

- `void el.offsetWidth` before adding a class, as in `slide()` (`index.html:1916`).

## Steps

1. Insert the Target CSS line directly **after** `index.html:382` (`.toast{background:var(--blue);color:var(--on-acc);box-shadow:...}`).
2. Replace `index.html:1556` with:
   ```js
   let toastT;function toast(m,act,fn){const t=document.getElementById("toast");t.textContent=m;t.classList.remove("pr");if(act){const b=document.createElement("button");b.type="button";b.textContent=act;b.onclick=()=>{hideToast();fn()};t.appendChild(b)}
     const was=!t.hidden&&t.classList.contains("on");t.hidden=false;if(!was)void t.offsetWidth;t.classList.add("on");clearTimeout(toastT);toastT=setTimeout(hideToast,act?5000:2600)}
   function hideToast(){const t=document.getElementById("toast");t.classList.remove("on");clearTimeout(toastT);toastT=setTimeout(()=>{if(!t.classList.contains("on"))t.hidden=true},200)}
   ```
   (`t.classList.remove("pr")` is used by plan 008; harmless before it.)
3. `index.html:1197` — replace `document.getElementById("toast").hidden=true;` with `hideToast();`.
4. `grep -n 'toast").hidden\|t.hidden=true' index.html` — only the line inside `hideToast` should remain. Otherwise STOP.
5. Bump `CACHE` in `sw.js`.

## Boundaries

- Do NOT change toast text, timings (5000 / 2600 ms) or position.
- Do NOT use `@keyframes` for the toast.

## Verification

- **Feel check** (390×844, Animations at 10%):
  - Food → add a food: "Added to …" rises 8px and fades in, stays centered, fades out after ~2.6s.
  - Delete a food (swipe left → Delete): the Undo toast appears; tap Undo: it fades out and the food returns.
  - Trigger two toasts fast (add two foods quickly): the second only swaps text; no flicker or second entrance.
  - Reduced motion emulated: fades only, no rise.
- **Done when**: no toast path shows or hides in a single frame, and Undo still works.
