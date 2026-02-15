#!/usr/bin/env bash
# Deploy the dist/ directory to the gh-pages branch for GitHub Pages.
# Usage: ./scripts/deploy-gh-pages.sh
#
# Prerequisites:
#   - dist/ must contain the built WASM artifacts + HTML pages
#   - The openXcomWASM repo must have a remote named 'origin'

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT}/dist"

if [[ ! -f "${DIST_DIR}/openxcom.wasm" ]]; then
  echo "No WASM build found in ${DIST_DIR}/. Run build-wasm.sh first."
  exit 1
fi

if [[ ! -f "${DIST_DIR}/index.html" ]]; then
  echo "No index.html in ${DIST_DIR}/. Run build-wasm.sh or serve.sh first."
  exit 1
fi

echo "Files to deploy:"
ls -lh "${DIST_DIR}/"
echo ""

# Use a temporary worktree to build the gh-pages branch
TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

cd "${ROOT}"

# Create gh-pages branch if it doesn't exist
if ! git rev-parse --verify gh-pages >/dev/null 2>&1; then
  echo "Creating gh-pages branch..."
  git checkout --orphan gh-pages
  git rm -rf . >/dev/null 2>&1 || true
  git commit --allow-empty -m "Initialize gh-pages"
  git checkout main
fi

# Copy dist contents to temp dir
cp -r "${DIST_DIR}"/* "${TMPDIR}/"

# Switch to gh-pages, replace contents, commit, switch back
git checkout gh-pages
# Remove old files (except .git)
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} +
# Copy new files
cp -r "${TMPDIR}"/* .
git add -A

if git diff --cached --quiet; then
  echo "No changes to deploy."
  git checkout main
  exit 0
fi

git commit -m "Deploy $(date +%Y-%m-%d_%H:%M:%S)"
echo ""
echo "Deployed to gh-pages branch. Push with:"
echo "  git push origin gh-pages"
echo ""
echo "Then enable GitHub Pages in repo Settings > Pages > Source: gh-pages branch."

git checkout main
