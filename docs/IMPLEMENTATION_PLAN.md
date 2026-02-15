# OpenXcom → WASM Implementation Plan

**Goal (demo scope):** OpenXcom runs in-browser, boots to menu, loads assets (user-import or demo pack), supports local saves via IndexedDB (IDBFS), and supports manual export/import of the `/user` save directory.

**Codebase:** Work from your fork: [github.com/mrmrcoleman/OpenXcom](https://github.com/mrmrcoleman/OpenXcom). Clone it into this repo (e.g. as `OpenXcom/` subdir) or use it as a submodule.

**Non-goals for now:** Cloud sync, mods browser UI, audio polish, perfect performance, mobile support.

---

## Important context: SDL and your fork

- **Upstream OpenXcom** still documents SDL 1.2 (SDL_mixer1.2, SDL_gfx, etc.). The [SDL2 branch is considered abandoned](https://openxcom.org/forum/index.php?topic=12139.0) (Nov 2024).
- **CMake:** Upstream `CMakeLists.txt` already uses `find_package(SDL2 COMPONENTS mixer gfx image)` when not using the bundled `deps/` (Windows). So the build system can target SDL2; the **source code** may still use SDL 1.2 APIs and need migration.
- **Recommendation:** Prefer **SDL2** for WASM. Use Emscripten’s `-sUSE_SDL=2`. If your fork builds on desktop with SDL2, proceed to Emscripten. If not, Phase 1 includes an SDL1.2 → SDL2 migration (or identifying a minimal patch set).

---

## Phase 0 — Repo and environment

- [ ] Clone your fork (e.g. into `OpenXcom/` in this repo) or add as submodule.
- [ ] Install [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html) and ensure `emcc`, `emcmake`, `emmake` are on PATH.
- [ ] Confirm desktop build of OpenXcom from your fork (CMake + SDL2 if available) so “normal” is defined.

**Deliverable:** Clean desktop build; Emscripten installed; repo layout decided (monorepo vs separate wrapper repo).

---

## Phase 1 — Codebase baseline and SDL2

- [ ] Build OpenXcom from your fork on your machine (Linux/macOS/Windows) with CMake.
- [ ] If the project only builds with SDL 1.2 (e.g. via `deps/`), either:
  - Migrate to SDL2 in your fork (window, renderer, event, mixer, image, gfx equivalents), or  
  - Find and apply existing SDL2 patches/forks (e.g. from Android/Switch ports) and merge into your fork.
- [ ] Freeze dependency versions: SDL2, SDL2_mixer, SDL2_image, SDL2_gfx (or in-tree/custom build), yaml-cpp.

**Deliverable:** Desktop build succeeds with SDL2; you have a single known-good baseline before WASM.

---

## Phase 2 — Emscripten toolchain and first WASM build

- [ ] Add Emscripten support:
  - Use a toolchain file or `emcmake cmake` with a dedicated build directory (e.g. `build-wasm`).
  - Recommended Emscripten flags (in CMake or in a wrapper script):
    - `-sUSE_SDL=2`
    - `-sALLOW_MEMORY_GROWTH=1`
    - `-sASYNCIFY=1` (for async FS/asset loading if needed)
    - `-sMODULARIZE=1` and `-sEXPORT_NAME=OpenXcomModule`
- [ ] Disable or stub platform-specific code (e.g. Windows-only, Apple-specific) for the WASM target.
- [ ] If the code uses threads, disable them initially (compile-time option or stubs) to avoid shared-array-buffer / cross-origin isolation requirements.

**Deliverable:** Build produces `openxcom.html` + `openxcom.wasm` + `openxcom.js`; something draws (e.g. window/canvas) even if the game logic fails later.

---

## Phase 3 — Browser platform layer (paths and entrypoint)

- [ ] Define a minimal platform layer so the game does not assume a real OS:
  - **Paths:** Data dir = `/data`, user dir = `/user`, config = under `/user` or same.
  - **Arguments:** No real `argc`/`argv`; pass fixed or config-driven “args” from JS.
  - **Entrypoint:** Expose a C entry JS can call after the FS is ready, e.g.  
    `extern "C" int openxcom_main(int argc, char **argv);`  
    and ensure the game starts only after JS has prepared the filesystem.
- [ ] Ensure logging (stdout/stderr) is visible in the browser console.

**Deliverable:** Game can start when `/data` and `/user` exist and contain the expected layout; no reliance on host filesystem or argv.

---

## Phase 4 — Virtual filesystem and IDBFS persistence

**Layout:**

- `/data` — read-only-ish (X-COM data, OpenXcom resources, optional mod pack).
- `/user` — config + saves; persistent across reloads.

**IDBFS (in JS glue, e.g. custom loader or `pre.js`):**

```js
FS.mkdir('/user');
FS.mount(IDBFS, {}, '/user');
// On startup: load from IndexedDB into memory
FS.syncfs(true, function (err) {
  if (err) console.error(err);
  // then start game
});
// After saves or periodically: flush memory → IndexedDB
FS.syncfs(false, function (err) {
  if (err) console.error(err);
});
```

- [ ] Implement the above in your HTML/JS bootstrap.
- [ ] Verify: create a test file under `/user`, refresh page, file still exists.

**Deliverable:** Persistence works for `/user`; game and config can be pointed at `/data` and `/user`.

---

## Phase 5 — Asset provisioning (demo-friendly)

Choose one path; implement in this order:

**Option A — User import (best for legal + demo):**

- [ ] UI: “Upload your X-COM data folder or zip.”
- [ ] Accept zip upload; unpack into `/data/` with the structure OpenXcom expects (e.g. `UFO/`, `TFTD/`).
- [ ] Optionally persist uploaded assets (e.g. store zip in IndexedDB and unpack on load, or copy unpacked tree into an IDBFS-backed path).

**Option B — Download asset pack from your static host:**

- [ ] Host an `assets.zip` (or similar) on the same origin (e.g. GitHub Pages).
- [ ] On first load, fetch and unpack into `/data`.
- [ ] Cache in IndexedDB so subsequent loads don’t re-download.

- [ ] If assets are missing, show “Import assets” (or “Download demo assets”) and do not start the game until `/data` is populated.

**Deliverable:** First run shows import/download flow; after assets are present, game can boot from `/data`.

---

## Phase 6 — Bootstrap sequence (JS)

- [ ] Single boot flow:
  1. Instantiate the Emscripten module (e.g. `OpenXcomModule`).
  2. Set up canvas (or use default from SDL).
  3. Create `/user`, mount IDBFS, run `FS.syncfs(true, callback)`.
  4. Ensure assets: if not present, show import UI and wait; if present, ensure `/data` is populated.
  5. Call into WASM: e.g. `Module.ccall('openxcom_main', 'number', ['number','number'], [argc, argvPtr])` or `Module.callMain(args)`.
  6. Register “flush saves” hooks: e.g. every 10–30 s and on `visibilitychange` / `beforeunload` call `FS.syncfs(false, callback)`.

**Deliverable:** Deterministic startup; no race where C++ runs before the FS is ready.

---

## Phase 7 — Input and rendering

- [ ] Rely on Emscripten’s SDL2: render target = canvas; keyboard/mouse from browser events.
- [ ] Confirm menu is usable with mouse and keyboard.

**Deliverable:** Menu is navigable and responsive.

---

## Phase 8 — Audio (defer but plan)

- [ ] Browser audio: require user gesture before starting. Add “Click to start” (or “Click to play”) overlay that resumes the main loop / unlocks audio if needed.
- [ ] If SDL_mixer causes issues, stub or disable audio for the demo and document.

**Deliverable:** Either working audio after click or cleanly disabled audio.

---

## Phase 9 — Saves and config

- [ ] Ensure OpenXcom writes saves and config under `/user` (runtime config or patched defaults).
- [ ] Run `FS.syncfs(false)` periodically and/or after save events if detectable; otherwise a timer is acceptable.

**Deliverable:** Save in-game → refresh → continue from save.

---

## Phase 10 — Export / Import saves (cross-device, no backend)

- [ ] **Export:** Zip (or tar) the contents of `/user` (optionally excluding caches), trigger browser download.
- [ ] **Import:** User uploads zip → clear or merge `/user` → unpack into `/user` → `FS.syncfs(false)` → reload or restart game.

**Deliverable:** Export on device A, import on device B, continue playing.

---

## Phase 11 — Packaging and deployment

- [ ] Build outputs (e.g. `openxcom.js`, `openxcom.wasm`, `openxcom.html`) go to a `dist/` (or similar).
- [ ] Simple static `index.html` with canvas, asset import UI, and export/import save buttons.
- [ ] Deploy to GitHub Pages or any static host; add cache headers or a simple service worker if desired.

**Deliverable:** Public URL serves the demo.

---

## Phase 12 — Debugging checklist

Common failure modes:

| Symptom | Likely cause |
|--------|----------------|
| Game starts before files exist | Bootstrap order; use Asyncify or delay `openxcom_main` until after `syncfs(true)` and asset unpack. |
| Missing files / wrong paths | Normalize all data/user paths to `/data` and `/user`; no relative paths assuming CWD. |
| Save doesn’t persist | Forgot `FS.syncfs(false)` after writes. |
| Works once, fails on refresh | Assets or `/user` not loaded from IDBFS or not re-unpacked on load. |
| No audio | User gesture required; add “Click to start” and ensure context resume. |

---

## Minimal acceptance criteria (Phase 1 demo)

- [ ] Loads to main menu.
- [ ] User can import X-COM data (zip) or use a hosted demo pack.
- [ ] New game starts.
- [ ] Save goes to `/user` and persists after refresh.
- [ ] Export/import saves works (download zip, upload on another device/browser).

---

## Suggested repo layout (this workspace)

```
xcom-wasm/
├── OpenXcom/          # Your fork (clone or submodule)
├── docs/
│   └── IMPLEMENTATION_PLAN.md   # This file
├── web/               # Optional: HTML/JS bootstrap, asset UI, deploy
│   ├── index.html
│   ├── bootstrap.js
│   └── ...
├── build-wasm/        # Emscripten build dir (gitignore)
└── README.md
```

You can keep the OpenXcom tree in a separate repo and only keep the `web/` and build scripts in `xcom-wasm` if you prefer.

---

## References

- [Emscripten SDL2](https://emscripten.org/docs/porting/multimedia.html#sdl-2)
- [Emscripten filesystem (IDBFS)](https://emscripten.org/docs/api_reference/Filesystem-API.html#idbfs)
- [OpenXcom forum – SDL2 branch status](https://openxcom.org/forum/index.php?topic=12139.0)
- Your fork: [github.com/mrmrcoleman/OpenXcom](https://github.com/mrmrcoleman/OpenXcom)
