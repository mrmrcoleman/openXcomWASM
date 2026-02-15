# Phase-by-phase prompts for implementers

Use these as self-contained prompts for an LLM (or yourself) when implementing each phase. Assume the **xcom-wasm** workspace contains the OpenXcom fork in `OpenXcom/` and the plan in `docs/IMPLEMENTATION_PLAN.md`.

---

## Phase 0 — Repo and environment

**Prompt:**  
“In the xcom-wasm workspace we are porting OpenXcom to WASM. Phase 0: (1) Add a README that tells me to clone https://github.com/mrmrcoleman/OpenXcom into `OpenXcom/` and to install Emscripten. (2) Add a .gitignore that ignores `build-wasm/`, `OpenXcom/build*/`, and common Emscripten/build artifacts. (3) If OpenXcom is not present, document the exact clone command and the optional submodule alternative.”

---

## Phase 1 — Codebase baseline and SDL2

**Prompt:**  
“OpenXcom in `OpenXcom/` currently builds with CMake. I want to use SDL2 for a future WASM build (Emscripten uses SDL2). (1) Determine whether the project already builds with SDL2 on this system (e.g. install SDL2, SDL2_mixer, SDL2_image, SDL2_gfx, yaml-cpp and run CMake). (2) If it only supports SDL 1.2, list the files that use SDL 1.2 APIs (SDL_* vs SDL2 renames, surface vs texture, etc.) and propose a minimal set of changes or a branch to get a working SDL2 desktop build. Do not change Emscripten yet; focus on a clean desktop SDL2 build.”

---

## Phase 2 — Emscripten toolchain and first WASM build

**Prompt:**  
“We have OpenXcom in `OpenXcom/` building on desktop with CMake and SDL2. Add a WASM build that uses Emscripten. (1) Create a build script or CMake preset that runs `emcmake cmake` and `emmake make` (or equivalent) from a directory like `build-wasm/`. (2) Use Emscripten flags: `-sUSE_SDL=2`, `-sALLOW_MEMORY_GROWTH=1`, `-sMODULARIZE=1`, `-sEXPORT_NAME=OpenXcomModule`. Add `-sASYNCIFY=1` if the build or startup needs async. (3) Disable or stub any platform-specific code (e.g. Windows/Apple) for the WASM target. (4) If the project uses threads, disable them for this target. Goal: produce `openxcom.js`, `openxcom.wasm`, and an HTML that loads the module and shows a canvas. The game may not fully run yet; we just need a successful link and something that opens/draws.”

---

## Phase 3 — Browser platform layer (paths and entrypoint)

**Prompt:**  
“OpenXcom is building to WASM. We need a browser-friendly platform layer. (1) Ensure the game uses fixed paths: data dir = `/data`, user dir = `/user`. (2) Expose a C entrypoint callable from JS, e.g. `extern \"C\" int openxcom_main(int argc, char **argv);`, and make the real `main()` call it or be it. (3) Ensure the game does not start until JS has created `/data` and `/user` and populated them; document that the JS bootstrap must call this entrypoint only after preparing the FS. (4) Ensure stdout/stderr are visible in the browser console. List any OpenXcom source files that hardcode paths or argv so we can point them at `/data` and `/user`.”

---

## Phase 4 — Virtual filesystem and IDBFS persistence

**Prompt:**  
“We have a WASM build of OpenXcom and an HTML/JS loader. Implement Emscripten virtual FS and persistence. (1) In the JS that loads the Emscripten module, create `/user` and mount IDBFS on it. (2) Before starting the game, run `FS.syncfs(true, callback)` to load IndexedDB into the in-memory FS. (3) After the game starts, register a periodic callback (e.g. every 15 seconds) and on `pagehide`/`visibilitychange` to run `FS.syncfs(false, callback)` to persist changes to IndexedDB. (4) Add a small test: write a file under `/user`, refresh the page, and confirm the file still exists after sync. Document the exact place in our bootstrap where we call the game entrypoint (after syncfs(true)).”

---

## Phase 5 — Asset provisioning (demo)

**Prompt:**  
“OpenXcom in the browser expects game data under `/data` (e.g. UFO/TFTD folder structure). Implement demo-friendly asset provisioning. (1) Add a simple UI: if `/data` is empty or missing required structure, show a screen that says ‘Import your X-COM data’ and provide a file input that accepts a ZIP. (2) On ZIP upload, use JS (e.g. JSZip or Emscripten’s support) to unpack the ZIP into the virtual FS under `/data`, preserving paths. (3) After unpacking, call the game entrypoint (or show a ‘Start game’ button that does). (4) Optionally: persist the uploaded ZIP in IndexedDB and on next load unpack again so the user doesn’t re-upload every time. Prefer a single ZIP containing the expected folder layout (e.g. UFO/, TFTD/).”

---

## Phase 6 — Bootstrap sequence (JS)

**Prompt:**  
“Tie the full startup flow together in one JS bootstrap. Order of operations: (1) Instantiate the Emscripten module (OpenXcomModule). (2) Create `/user`, mount IDBFS, run FS.syncfs(true). (3) Check if `/data` has the required assets; if not, show the import UI and do not call the game. (4) When assets are ready, call the game entrypoint (e.g. openxcom_main) with argv pointing data at `/data` and user at `/user`. (5) Register flush: every 20 seconds and on visibilitychange/beforeunload, run FS.syncfs(false). Ensure the game never runs before syncfs(true) and asset check are done. Document any Asyncify requirements if we block on syncfs.”

---

## Phase 7 — Input and rendering

**Prompt:**  
“Confirm that in our Emscripten + SDL2 build, the OpenXcom menu is usable in the browser. (1) Verify that keyboard and mouse events are passed through to SDL (default Emscripten behavior). (2) Verify that rendering goes to the canvas and is visible. (3) If anything is broken (e.g. fullscreen, resolution, or input focus), list the minimal fixes. No new features; just ensure menu navigation works with mouse and keyboard.”

---

## Phase 8 — Audio (defer or minimal)

**Prompt:**  
“Browser audio often requires a user gesture. (1) Add a ‘Click to start’ or ‘Click to play’ overlay that the user must click before we start the game or unmute audio; use it to resume the Emscripten main loop or unlock the AudioContext if needed. (2) If SDL_mixer causes build or runtime issues under Emscripten, document how to stub or disable audio so the rest of the demo still runs. Goal: either working audio after click or cleanly disabled audio.”

---

## Phase 9 — Saves and config

**Prompt:**  
“OpenXcom must write saves and config under `/user` so they persist via IDBFS. (1) Find where OpenXcom resolves the user/config directory and ensure it uses `/user` (or a path under it) when built for WASM. (2) Ensure we run FS.syncfs(false) after save operations; if we can’t hook save events, keep the periodic and beforeunload sync. (3) Test: start a new game, save, refresh the page, and confirm the save is still there and loadable.”

---

## Phase 10 — Export / Import saves

**Prompt:**  
“Add cross-device save transfer without a backend. (1) Export: Add a button that zips the contents of `/user` (e.g. using JSZip) and triggers a download. (2) Import: Add a button that lets the user upload a zip; clear or merge `/user`, unpack the zip into `/user`, run FS.syncfs(false), then reload the page or restart the game. (3) Document that users can export on one device and import on another to continue.”

---

## Phase 11 — Packaging and deployment

**Prompt:**  
“Prepare the project for static deployment (e.g. GitHub Pages). (1) Put build outputs (openxcom.js, openxcom.wasm, index.html, and any assets) in a `dist/` directory. (2) Write a minimal index.html that loads the module, shows the canvas, and includes the asset-import and export/import save UI. (3) Add a short README section or script that builds the WASM and copies files to dist/. (4) Note any required HTTP headers (e.g. COOP/COEP if we use threads later) or CORS for assets.”

---

## Phase 12 — Debugging checklist

**Prompt:**  
“Using docs/IMPLEMENTATION_PLAN.md Phase 12 as reference, add a short DEBUGGING.md (or section in the main plan) that lists common failure modes and fixes: (1) Game starts before FS is ready → bootstrap order / Asyncify. (2) Missing files → path normalization to /data and /user. (3) Saves not persisting → FS.syncfs(false). (4) Works once then fails on refresh → IDBFS sync and asset re-unpack. (5) No audio → user gesture and context resume. Keep each item to 1–2 sentences.”

---

*After each phase, run the acceptance criteria from IMPLEMENTATION_PLAN.md that apply to that phase.*
