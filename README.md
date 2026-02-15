# OpenXcomWASM

Play [OpenXcom](https://openxcom.org) in your browser. The full C++ engine compiled to WebAssembly — no plugins, no install, works offline after first visit.

**Live demo:** [playxcom.online](https://playxcom.online)

**Powered by:** [OpenXcom fork](https://github.com/mrmrcoleman/OpenXcom) (SDL2, Emscripten patches)

## Features

- Full OpenXcom engine running natively in the browser via WebAssembly
- Game data and saves stored locally in IndexedDB (nothing leaves your machine)
- Persistent saves across browser sessions
- Export/import saves as `.zip` for backup or cross-device transfer
- Service worker for offline play after first visit
- Landing page with getting-started guide

## Quick start

```bash
# Clone with submodules (pulls the OpenXcom fork automatically)
git clone --recursive https://github.com/mrmrcoleman/OpenXcomWASM.git
cd OpenXcomWASM

# Install Emscripten SDK
# https://emscripten.org/docs/getting_started/downloads.html
# Ensure emcmake and emmake are on PATH

# Build
./scripts/build-wasm.sh

# Serve locally
./scripts/serve.sh
# Open http://localhost:8080
```

## Repo layout

```
OpenXcomWASM/
  OpenXcom/          Git submodule — the patched OpenXcom fork
  scripts/
    build-wasm.sh    Build the WASM binary
    build-desktop.sh Build native binary (for testing)
    serve.sh         Local dev server (copies web assets + serves dist/)
    deploy-gh-pages.sh  Deploy to GitHub Pages
  web/
    index.html       Landing page
    play.html        Game page (HTML shell for Emscripten)
    sw.js            Service worker for offline caching
    jszip.min.js     JSZip library (bundled for offline support)
  dist/              Build output (WASM artifacts + web assets)
```

## Building

### Prerequisites

- [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html) with `emcmake` and `emmake` on PATH
- CMake 3.14+

### WASM build

```bash
./scripts/build-wasm.sh
```

Output goes to `dist/`. The build script automatically pulls the OpenXcom submodule if needed.

To preload game data into the build (for development only):

```bash
GAME_DATA=/path/to/UFO ./scripts/build-wasm.sh
```

### Desktop build (for testing)

```bash
brew install cmake sdl2 sdl2_mixer sdl2_image sdl2_gfx yaml-cpp   # macOS
./scripts/build-desktop.sh
```

## How it works

The OpenXcom C++ engine is compiled to WebAssembly using Emscripten. Static game data (common/standard resources) is preloaded into the WASM virtual filesystem. User-provided game data (the `UFO/` directory from a legitimate copy of X-COM) is uploaded once and persisted in IndexedDB via Emscripten's IDBFS. Saves are synced to IndexedDB every 30 seconds during gameplay.

A service worker caches all static assets after first load, enabling full offline play.

## License

GPL v3 — same as [OpenXcom](https://github.com/SupSuper/OpenXcom).

X-COM: UFO Defense is copyright Mythos Games / MicroProse. You need a legitimate copy of the game data to play.
