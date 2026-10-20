#!/usr/bin/env bash
# Produit le répertoire de build servi ensuite par nginx.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/dist/build"
JENKINS_HOST="${JENKINS_HOST:-16.192.73.184}"
DEPLOY_HOST="${DEPLOY_HOST:-16.192.253.80}"
BUILD_NUMBER="${BUILD_NUMBER:-local}"
LIBRARY_VERSION="${LIBRARY_VERSION:-local}"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp -a "$ROOT/index.html" "$ROOT/error" "$ROOT/assets" "$ROOT/images" "$ROOT/LICENSE.MD" "$BUILD_DIR/"

case "${BUILD_NUMBER}${COMMIT}${JENKINS_HOST}${DEPLOY_HOST}${LIBRARY_VERSION}" in
  *\"*|*'\'*)
    echo "Valeur de build invalide." >&2
    exit 1
    ;;
esac

cat > "$BUILD_DIR/build-info.json" <<EOF
{
  "name": "static-website",
  "build": "${BUILD_NUMBER}",
  "commit": "${COMMIT}",
  "jenkinsHost": "${JENKINS_HOST}",
  "deployHost": "${DEPLOY_HOST}",
  "libraryVersion": "${LIBRARY_VERSION}"
}
EOF

test -f "$BUILD_DIR/index.html"
test -f "$BUILD_DIR/build-info.json"
echo "Build ${BUILD_NUMBER} (${COMMIT}) dans ${BUILD_DIR}"
