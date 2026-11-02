# C1 Workout – project notes for Claude Code

Personal workout + nutrition app for Natt. Single-file web app (PWA) hosted on GitHub Pages,
also wrapped as an iPhone app (Capacitor) that loads the live site.

- Live site: https://nattkongkaew33.github.io/c1-workout/
- Repo: nattkongkaew33/c1-workout (branch `main`; GitHub Pages deploys on every push, ~1 min)
- iPhone app project: `c1-ios/` on the MacBook (Capacitor 8, appId `com.natt.c1workout`)

## Files (repo root)
- `index.html` – the whole app: HTML + CSS + JS in one file. Edit this directly.
- `sw.js` – service worker. **Bump `CACHE` (e.g. `c1-workout-v30` → `v31`) on every release** or phones keep the old version.
- `manifest.json`, `icon-180.png`, `icon-192.png`, `icon-512.png`
- `.nojekyll` – keeps GitHub Pages from running Jekyll.

## Release checklist
1. Edit `index.html`.
2. Bump the cache version in `sw.js`.
3. Commit and push to `main`. In the app, tap ↻ Refresh (Workout tab) to load it.
4. Only rebuild the iPhone app (Xcode ▶) when native plugins or `capacitor.config.json` / `Info.plist` change.

## App structure (index.html)
- Hash routes: `#week` (home/Today), `#w-YYYY-MM-DD` (workout logger), `#food`, `#calendar`,
  `#progress`, `#plan`, `#coach`, `#coach-new`, `#coach-p-<id>`. `render()` dispatches on the hash.
- Theme "chalk & plates": CSS tokens on `:root` (`--bg #0e1222`, accent `--blue` = bumper yellow `#ffd23f`,
  text on accent `--on-acc`). Fonts: Big Shoulders Display (titles), IBM Plex Sans Thai (body), IBM Plex Mono (numbers).
- Signature UI: `plate()` SVG ring (home hero + Food calories).
- iOS: every typed field must be ≥16px (else iPhone zooms); viewport has `maximum-scale=1`.
- Week day cards are `div[data-go]` (not links) so hold-and-drag (`initDrag`) works without iOS link preview.

## Data (localStorage, on the phone only)
`c1-sessions` workouts, `c1-log`, `c1-prog` multi-week plan, `c1-sched` per-date overrides, `c1-first`,
`c1-unit` kg/lb (weights stored in kg), `c1-bw` body weight {date: kg}, `c1-sound`, `c1-food` food log
{date:[{id,meal,name,g,per(per 100 g),q,u,sv}]}, `c1-nut` targets, `c1-presets` saved foods/meals (foods can have `bc` barcode),
`c1-dayadj` training/rest-day calorie shift, `c1-lib` exercise library, `c1-clients` coach plans, `c1-theme` dark/light,
keys: `c1-aikey` (Claude), `c1-aimodel`, `c1-usdakey`, `c1-ytkey` (YouTube).
Backup/restore: `backupData()` / `applyImport()` – include new data keys there, never API keys.
Changes must stay compatible with existing saved data (users' logs must survive updates).

## Features worth knowing
- Food: search (local list + Open Food Facts), barcode live scan (ZXing, any angle) → My foods → Open Food Facts → USDA;
  defaults to 1 serving as labelled; AI photo/label via Claude API from the browser; units (serving/g/oz/ml);
  auto meal by time (<200 cal = snack); recent foods; copy meal/day; training vs rest-day targets.
- Coach tab: exercise library (+ auto most-viewed YouTube video via YouTube Data API) and AI client plans; never touches the user's own plan.
- iPhone app only: rest-timer local notifications (`@capacitor/local-notifications`), Apple Health weight sync (`@capgo/capacitor-health`).

## Rules
- Never put API keys in code, commits or messages. The user pastes keys in the app (Food → ⚙, Coach → Library).
- Keep the user's own program (`PROG`, `S`, `LOG`, `SCHED`) untouched by Coach features.
- Test in a phone-sized browser (390×844) before pushing.
