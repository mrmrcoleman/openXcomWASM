#!/usr/bin/env bash
# Phase 2: Build OpenXcom for WASM with Emscripten. Run from repo root.
# Requires: Emscripten SDK (emcmake, emmake), and OpenXcom with Emscripten CMake support.
#   Install: https://emscripten.org/docs/getting_started/downloads.html

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENXCOM="${ROOT}/OpenXcom"
BUILD_DIR="${OPENXCOM}/build-wasm"
DIST_DIR="${ROOT}/dist"

if [[ ! -d "$OPENXCOM" ]]; then
  echo "OpenXcom submodule not found at $OPENXCOM. Initialize it first:"
  echo "  git submodule update --init"
  exit 1
fi

if ! command -v emcmake &>/dev/null; then
  echo "Emscripten not found. Install the SDK and ensure emcmake/emmake are on PATH."
  echo "  https://emscripten.org/docs/getting_started/downloads.html"
  exit 1
fi

echo "Configuring OpenXcom for WASM in ${BUILD_DIR}..."
emcmake cmake -B "$BUILD_DIR" -S "$OPENXCOM" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_PACKAGE=OFF

echo "Building (this can take a while)..."
emmake cmake --build "$BUILD_DIR" --config Release

mkdir -p "$DIST_DIR"
echo "Copying artifacts to ${DIST_DIR}..."
cp -v "${BUILD_DIR}/bin/openxcom.js"   "${DIST_DIR}/" 2>/dev/null || true
cp -v "${BUILD_DIR}/bin/openxcom.wasm" "${DIST_DIR}/" 2>/dev/null || true
cp -v "${BUILD_DIR}/bin/openxcom.html" "${DIST_DIR}/" 2>/dev/null || true
# Emscripten may output .html as the main target name
if [[ -f "${BUILD_DIR}/bin/openxcom.html" ]]; then
  cp -v "${BUILD_DIR}/bin/openxcom.html" "${DIST_DIR}/"
fi

echo "Done. Check ${DIST_DIR}/ for openxcom.js, openxcom.wasm, openxcom.html"
