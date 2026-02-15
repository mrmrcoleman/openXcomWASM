# OpenXcom → WASM

Port [OpenXcom](https://openxcom.org) to WebAssembly so it runs in the browser. Demo scope: menu, user-provided or hosted assets, local saves (IDBFS), export/import saves.

**OpenXcom fork:** [github.com/mrmrcoleman/OpenXcom](https://github.com/mrmrcoleman/OpenXcom)

## Repo layout

- **`docs/IMPLEMENTATION_PLAN.md`** — Full phase-by-phase implementation plan (for you or another LLM).
- **`docs/PROMPTS_BY_PHASE.md`** — Copy-paste prompts for each phase.
- **`OpenXcom/`** — Your fork of OpenXcom (clone or submodule; see below).
- **`scripts/`** — `build-desktop.sh` (Phase 1), `build-wasm.sh` (Phase 2).
- **`web/`** — Browser glue (HTML, JS bootstrap, asset UI). To be added as you implement.
- **`dist/`** — WASM build artifacts (openxcom.js, openxcom.wasm, openxcom.html) after `scripts/build-wasm.sh`.

## Quick setup

1. **Clone your fork into this repo:**

   ```bash
   git clone https://github.com/mrmrcoleman/OpenXcom.git
   ```

   Or add as submodule:

   ```bash
   git submodule add https://github.com/mrmrcoleman/OpenXcom.git
   ```

2. **Install dependencies**
   - **macOS (Homebrew):** If you don’t have Homebrew: [install it](https://brew.sh) (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`), then add it to your PATH as the installer suggests. Then:
     ```bash
     brew install cmake sdl2 sdl2_mixer sdl2_image sdl2_gfx yaml-cpp
     ```
   - **Emscripten (for WASM):** [Installation guide](https://emscripten.org/docs/getting_started/downloads.html). Ensure `emcmake`, `emmake` are on `PATH`.

3. **Desktop build (Phase 1):**

   ```bash
   ./scripts/build-desktop.sh
   ```

   Binary: `OpenXcom/build/bin/openxcom` (or `.app` on macOS). If this fails (e.g. SDL2 not found or SDL 1.2 vs 2), see **Phase 1** in `docs/IMPLEMENTATION_PLAN.md`.

4. **WASM build (Phase 2):**

   ```bash
   ./scripts/build-wasm.sh
   ```

   Output: `dist/openxcom.js`, `dist/openxcom.wasm`, `dist/openxcom.html`. OpenXcom’s CMake has been patched in-repo to add Emscripten link flags and HTML output.

5. **Follow the plan:**  
   Work through `docs/IMPLEMENTATION_PLAN.md` phases 0–12 for FS, assets, and persistence.

## Goals (demo)

- Run in browser; boot to menu.
- Load assets via user upload (zip) or hosted pack.
- Saves in `/user` persist in IndexedDB (IDBFS).
- Export/import saves for cross-device without a backend.

## Non-goals (for now)

Cloud sync, full mod UI, audio polish, mobile tuning.
