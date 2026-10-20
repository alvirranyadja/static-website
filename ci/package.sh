#!/usr/bin/env bash
# Crée l'artefact versionné et son empreinte SHA-256.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_NUMBER="${BUILD_NUMBER:-local}"
DIST="$ROOT/dist"
BUILD_DIR="$DIST/build"
ARCHIVE="$DIST/site-${BUILD_NUMBER}.tar.gz"
CHECKSUM="$DIST/site-${BUILD_NUMBER}.tar.gz.sha256"

if [ ! -f "$BUILD_DIR/index.html" ] || [ ! -f "$BUILD_DIR/build-info.json" ]; then
  echo "Build absent. Lancez ci/build.sh." >&2
  exit 1
fi

rm -f "$ARCHIVE" "$CHECKSUM"
tar -czf "$ARCHIVE" -C "$BUILD_DIR" .
test -s "$ARCHIVE"

(
  cd "$DIST"
  sha256sum "site-${BUILD_NUMBER}.tar.gz" > "site-${BUILD_NUMBER}.tar.gz.sha256"
  sha256sum -c "site-${BUILD_NUMBER}.tar.gz.sha256"
)

echo "Artefact : $ARCHIVE"
echo "Empreinte : $(cat "$CHECKSUM")"
