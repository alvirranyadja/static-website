#!/usr/bin/env bash
# Vérifie que le site répond et que les fichiers statiques sont servis.
set -euo pipefail

URL="${1:?url}"
URL="${URL%/}"
BODY="$(mktemp)"
ERR="$(mktemp)"
trap 'rm -f "$BODY" "$ERR"' EXIT

echo "Vérification de ${URL}/"
code="$(curl -sS --retry 5 --retry-connrefused --retry-delay 2 --max-time 20 \
  -o "$BODY" -w "%{http_code}" "${URL}/")"
if [ "$code" != "200" ]; then
  echo "Page d'accueil : HTTP ${code}" >&2
  exit 1
fi
if ! grep -q "Dimension" "$BODY"; then
  echo "La page d'accueil ne contient pas le titre attendu." >&2
  exit 1
fi

curl -fsS --retry 3 --retry-connrefused --retry-delay 2 --max-time 20 \
  -o /dev/null "${URL}/assets/css/main.css"
curl -fsS --retry 3 --retry-connrefused --retry-delay 2 --max-time 20 \
  -o /dev/null "${URL}/images/bg.jpg"

code404="$(curl -sS --max-time 20 -o "$ERR" -w "%{http_code}" \
  "${URL}/this-page-does-not-exist")"
if [ "$code404" != "404" ]; then
  echo "Page inconnue : HTTP ${code404}, 404 attendu." >&2
  exit 1
fi
if ! grep -q "Page not found" "$ERR"; then
  echo "La page 404 personnalisée n'est pas servie." >&2
  exit 1
fi

echo "Vérification OK"
