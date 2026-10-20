#!/usr/bin/env bash
set -euo pipefail

BASE="${1:?chemin}"

if [ ! -f "$BASE/previous_target" ]; then
  echo "Aucune release précédente à restaurer." >&2
  exit 1
fi

previous="$(tr -d '\r' < "$BASE/previous_target")"
if [ ! -d "$previous" ] || [ ! -f "$previous/index.html" ]; then
  echo "Release précédente inutilisable : $previous" >&2
  exit 1
fi

ln -sfn "$previous" "$BASE/current"
echo "Rollback vers $previous"
rm -f /tmp/remote-rollback.sh
