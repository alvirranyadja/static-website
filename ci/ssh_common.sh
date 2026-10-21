#!/usr/bin/env bash
# Prépare une connexion SSH qui n'accepte que la clé d'hôte épinglée.
set -euo pipefail

ssh_init() {
  : "${DEPLOY_HOST:?DEPLOY_HOST manquant}"
  : "${DEPLOY_USER:?DEPLOY_USER manquant}"
  : "${DEPLOY_PATH:?DEPLOY_PATH manquant}"
  : "${BUILD_NUMBER:?BUILD_NUMBER manquant}"
  : "${SSH_KEY:?SSH_KEY manquant}"

  if ! [[ "$DEPLOY_HOST" =~ ^[A-Za-z0-9._:-]+$ ]]; then
    echo "DEPLOY_HOST invalide." >&2
    exit 1
  fi
  if ! [[ "$DEPLOY_USER" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "DEPLOY_USER invalide." >&2
    exit 1
  fi
  if ! [[ "$DEPLOY_PATH" =~ ^/[A-Za-z0-9._/-]+$ ]]; then
    echo "DEPLOY_PATH invalide." >&2
    exit 1
  fi
  if ! [[ "$BUILD_NUMBER" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "BUILD_NUMBER invalide." >&2
    exit 1
  fi

  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  KNOWN="$ROOT/deploy/known_hosts"
  if [ ! -s "$KNOWN" ] || ! grep -q "^${DEPLOY_HOST} ssh-ed25519 " "$KNOWN"; then
    echo "Clé d'hôte absente pour ${DEPLOY_HOST} dans deploy/known_hosts." >&2
    exit 1
  fi
  if [ ! -f "$SSH_KEY" ]; then
    echo "Clé privée Jenkins introuvable." >&2
    exit 1
  fi
  SSH_OPTS=(-i "$SSH_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$KNOWN" -o ConnectTimeout=20)
}

ssh_remote() {
  ssh "${SSH_OPTS[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" "$@"
}
