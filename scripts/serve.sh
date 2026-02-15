#!/usr/bin/env bash
# Serve the WASM build locally for browser testing.
# Copies web/ assets alongside dist/ artifacts and starts a local server.

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT}/dist"

if [[ ! -f "${DIST_DIR}/openxcom.js" ]]; then
  echo "No WASM build found in ${DIST_DIR}/. Run build-wasm.sh first."
  exit 1
fi

# Copy web assets alongside WASM artifacts
cp -v "${ROOT}/web/index.html" "${DIST_DIR}/"
cp -v "${ROOT}/web/play.html"  "${DIST_DIR}/" 2>/dev/null || true

echo ""
echo "Serving at http://localhost:8080"
echo "Press Ctrl+C to stop."
echo ""
python3 -m http.server 8080 --directory "${DIST_DIR}"
