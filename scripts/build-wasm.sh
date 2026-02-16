#!/usr/bin/env bash
# Build OpenXcom for WASM with Emscripten.
# Requires: Emscripten SDK (emcmake, emmake)
#   Install: https://emscripten.org/docs/getting_started/downloads.html
#
# Environment variables:
#   OPENXCOM_SRC  — path to a local OpenXcom clone (instead of the pinned
#                   submodule). Example:
#                     OPENXCOM_SRC=../OpenXcom ./scripts/build-wasm.sh
#
#   GAME_DATA     — path to the proprietary UFO game data directory
#                   (e.g. ~/Library/Application Support/OpenXcom/UFO).
#                   When set, the data is preloaded into the WASM VFS.

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -n "${OPENXCOM_SRC:-}" ]]; then
  # Resolve to absolute path
  OPENXCOM="$(cd "${OPENXCOM_SRC}" 2>/dev/null && pwd)" || {
    echo "OPENXCOM_SRC path not found: ${OPENXCOM_SRC}"
    exit 1
  }
  echo "Using local source: ${OPENXCOM}"
else
  OPENXCOM="${ROOT}/OpenXcom"
fi

BUILD_DIR="${OPENXCOM}/build-wasm"
DIST_DIR="${ROOT}/dist"

if [[ ! -d "$OPENXCOM/src" ]]; then
  if [[ -n "${OPENXCOM_SRC:-}" ]]; then
    echo "No OpenXcom source tree found at $OPENXCOM (missing src/ directory)."
  else
    echo "OpenXcom submodule not initialized. Run:"
    echo "  git submodule update --init"
  fi
  exit 1
fi

if ! command -v emcmake &>/dev/null; then
  echo "Emscripten not found. Install the SDK and ensure emcmake/emmake are on PATH."
  echo "  https://emscripten.org/docs/getting_started/downloads.html"
  exit 1
fi

# Optional: resolve GAME_DATA to absolute path and pass to CMake
EXTRA_CMAKE_ARGS=""
if [[ -n "${GAME_DATA:-}" ]]; then
  UFO_PATH="$(cd "${GAME_DATA}" 2>/dev/null && pwd)" || {
    echo "GAME_DATA path not found: ${GAME_DATA}"
    exit 1
  }
  # Emscripten's file_packager cannot handle spaces in paths.
  # Work around by creating a symlink in /tmp if the path has spaces.
  if [[ "$UFO_PATH" == *" "* ]]; then
    UFO_LINK="/tmp/openxcom-ufo-data"
    rm -f "$UFO_LINK"
    ln -s "$UFO_PATH" "$UFO_LINK"
    UFO_PATH="$UFO_LINK"
    echo "Created symlink (path contains spaces): ${UFO_LINK} -> ${GAME_DATA}"
  fi
  EXTRA_CMAKE_ARGS="-DUFO_DATA_DIR=${UFO_PATH}"
  echo "Will preload UFO data from: ${UFO_PATH}"
fi

# If a cached build dir exists, remove CMake config files that embed absolute
# paths (e.g. the Emscripten SDK temp directory which changes every CI run).
# Object files are preserved so incremental compilation still works.
if [[ -f "$BUILD_DIR/CMakeCache.txt" ]]; then
  echo "Clearing stale CMake config (preserving object files for incremental build)..."
  rm -f  "$BUILD_DIR/CMakeCache.txt"
  rm -rf "$BUILD_DIR/CMakeFiles"
fi

echo "Configuring OpenXcom for WASM in ${BUILD_DIR}..."
emcmake cmake -B "$BUILD_DIR" -S "$OPENXCOM" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_PACKAGE=OFF \
  ${EXTRA_CMAKE_ARGS}

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
echo "Building with ${NPROC} parallel jobs (this can take a while on first build)..."
emmake cmake --build "$BUILD_DIR" --config Release -- -j"${NPROC}"

mkdir -p "$DIST_DIR"
echo "Copying artifacts to ${DIST_DIR}..."
cp -v "${BUILD_DIR}/bin/openxcom.js"   "${DIST_DIR}/" 2>/dev/null || true
cp -v "${BUILD_DIR}/bin/openxcom.wasm" "${DIST_DIR}/" 2>/dev/null || true
cp -v "${BUILD_DIR}/bin/openxcom.data" "${DIST_DIR}/" 2>/dev/null || true

# Copy web assets (landing page + game page + service worker + libs)
cp -v "${ROOT}/web/index.html"    "${DIST_DIR}/"
cp -v "${ROOT}/web/play.html"     "${DIST_DIR}/" 2>/dev/null || true
cp -v "${ROOT}/web/sw.js"         "${DIST_DIR}/" 2>/dev/null || true
cp -v "${ROOT}/web/jszip.min.js"  "${DIST_DIR}/" 2>/dev/null || true

echo "Done. Check ${DIST_DIR}/ for openxcom.js, openxcom.wasm, openxcom.data, index.html, play.html, sw.js"
