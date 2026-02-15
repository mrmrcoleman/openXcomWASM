#!/usr/bin/env bash
# Phase 1: Build OpenXcom for desktop (SDL2). Run from repo root.
# Requires: cmake, SDL2, SDL2_mixer, SDL2_image, SDL2_gfx, yaml-cpp
#   macOS: brew install cmake sdl2 sdl2_mixer sdl2_image yaml-cpp
#   SDL2_gfx: brew install sdl2_gfx (or build from source if not in brew)

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENXCOM="${ROOT}/OpenXcom"
BUILD_DIR="${OPENXCOM}/build"

if [[ ! -d "$OPENXCOM" ]]; then
  echo "OpenXcom submodule not found at $OPENXCOM. Initialize it first:"
  echo "  git submodule update --init"
  exit 1
fi

echo "Configuring OpenXcom (Release) in ${BUILD_DIR}..."
cmake -B "$BUILD_DIR" -S "$OPENXCOM" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_PACKAGE=OFF

echo "Building..."
cmake --build "$BUILD_DIR" --config Release

echo "Done. Binary: ${BUILD_DIR}/bin/openxcom (or openxcom.app on macOS with CREATE_BUNDLE)"
