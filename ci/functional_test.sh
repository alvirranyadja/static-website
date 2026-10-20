#!/usr/bin/env bash
# Test de fonctionnement après déploiement : pages, médias et en-têtes de sécurité.
set -euo pipefail

: "${SITE_URL:?SITE_URL manquant}"
if ! [[ "$SITE_URL" =~ ^https?://[A-Za-z0-9._:-]+(/.*)?$ ]]; then
  echo "SITE_URL invalide." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/ci/healthcheck.sh" "$SITE_URL"

URL="${SITE_URL%/}"
check_headers() {
  local target="$1"
  local hdr
  hdr="$(mktemp)"
  curl -sS --retry 3 --retry-connrefused --retry-delay 2 --max-time 20 \
    -D "$hdr" -o /dev/null "$target"
  local name
  for name in \
    "X-Frame-Options: SAMEORIGIN" \
    "X-Content-Type-Options: nosniff" \
    "Referrer-Policy: strict-origin-when-cross-origin" \
    "Content-Security-Policy:" \
    "Permissions-Policy:"
  do
    if ! grep -qi "^${name}" "$hdr"; then
      echo "En-tête absent sur ${target} : ${name}" >&2
      rm -f "$hdr"
      exit 1
    fi
  done
  rm -f "$hdr"
}

check_headers "${URL}/"
check_headers "${URL}/assets/css/main.css"
echo "Test de fonctionnement OK"
