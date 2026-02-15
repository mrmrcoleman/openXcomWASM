#!/usr/bin/env bash
# Build OpenXcom for desktop (SDL2).
# Requires: cmake, SDL2, SDL2_mixer, SDL2_image, SDL2_gfx, yaml-cpp
#   macOS: brew install cmake sdl2 sdl2_mixer sdl2_image sdl2_gfx yaml-cpp
#
# Set OPENXCOM_SRC to a path to build from a local clone instead of the
# pinned submodule. Example:
#   OPENXCOM_SRC=../OpenXcom ./scripts/build-desktop.sh

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

BUILD_DIR="${OPENXCOM}/build"

if [[ ! -d "$OPENXCOM/src" ]]; then
  if [[ -n "${OPENXCOM_SRC:-}" ]]; then
    echo "No OpenXcom source tree found at $OPENXCOM (missing src/ directory)."
  else
    echo "OpenXcom submodule not initialized. Run:"
    echo "  git submodule update --init"
  fi
  exit 1
fi

echo "Configuring OpenXcom (Release) in ${BUILD_DIR}..."
cmake -B "$BUILD_DIR" -S "$OPENXCOM" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_PACKAGE=OFF

echo "Building..."
cmake --build "$BUILD_DIR" --config Release

echo "Done. Binary: ${BUILD_DIR}/bin/openxcom (or openxcom.app on macOS with CREATE_BUNDLE)"
