#!/usr/bin/env bash
# Exécuté sur la machine de déploiement. Bascule atomique via un lien symbolique.
set -euo pipefail

RELEASE="${1:?release}"
BASE="${2:?chemin}"
ARCHIVE="${3:?archive}"

if ! [[ "$RELEASE" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Release invalide." >&2
  exit 1
fi
if ! [[ "$BASE" =~ ^/[A-Za-z0-9._/-]+$ ]]; then
  echo "Chemin invalide." >&2
  exit 1
fi

mkdir -p "$BASE/releases"
rm -rf "$BASE/releases/$RELEASE"
mkdir -p "$BASE/releases/$RELEASE"
tar -xzf "$ARCHIVE" -C "$BASE/releases/$RELEASE"
test -f "$BASE/releases/$RELEASE/index.html"
chmod -R a+rX "$BASE/releases/$RELEASE"

if [ -L "$BASE/current" ]; then
  previous="$(readlink -f "$BASE/current" || true)"
  if [ -n "${previous}" ] && [ -d "${previous}" ]; then
    printf '%s\n' "$previous" > "$BASE/previous_target"
  fi
fi

ln -sfn "$BASE/releases/$RELEASE" "$BASE/current"
printf '%s\n' "$RELEASE" > "$BASE/current_release"

ls -1dt "$BASE"/releases/*/ 2>/dev/null | tail -n +6 | while IFS= read -r dir; do
  if [ -n "$dir" ] && [ "$dir" != "$BASE/releases/$RELEASE/" ]; then
    rm -rf "$dir"
  fi
done

rm -f "$ARCHIVE" /tmp/remote-deploy.sh
echo "Release active : $BASE/releases/$RELEASE"
