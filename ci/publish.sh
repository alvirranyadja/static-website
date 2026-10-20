#!/usr/bin/env bash
# Envoie l'artefact et bascule la release. Le test de fonctionnement est une étape séparée.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ssh_common.sh
source "$ROOT/ci/ssh_common.sh"
ssh_init

ARCHIVE="$ROOT/dist/site-${BUILD_NUMBER}.tar.gz"
CHECKSUM="$ROOT/dist/site-${BUILD_NUMBER}.tar.gz.sha256"
RENDERED="$ROOT/dist/static-website.conf"

if [ ! -f "$ARCHIVE" ] || [ ! -f "$CHECKSUM" ]; then
  echo "Artefact ou empreinte absent." >&2
  exit 1
fi

(
  cd "$ROOT/dist"
  sha256sum -c "site-${BUILD_NUMBER}.tar.gz.sha256"
)

sed "s#__DEPLOY_PATH__#${DEPLOY_PATH}#g" \
  "$ROOT/deploy/nginx/static-website.conf" > "$RENDERED"

echo "Envoi de la release ${BUILD_NUMBER} vers ${DEPLOY_USER}@${DEPLOY_HOST}"
scp "${SSH_OPTS[@]}" "$ARCHIVE" "${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/site-${BUILD_NUMBER}.tar.gz"
scp "${SSH_OPTS[@]}" "$RENDERED" "${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/static-website.conf"
scp "${SSH_OPTS[@]}" "$ROOT/deploy/nginx/security-headers.conf" "${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/security-headers.conf"
scp "${SSH_OPTS[@]}" "$ROOT/ci/remote-deploy.sh" "${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/remote-deploy.sh"
scp "${SSH_OPTS[@]}" "$ROOT/ci/remote-rollback.sh" "${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/remote-rollback.sh"

ssh_remote "bash /tmp/remote-deploy.sh '${BUILD_NUMBER}' '${DEPLOY_PATH}' '/tmp/site-${BUILD_NUMBER}.tar.gz'"
ssh_remote "sudo /usr/local/sbin/reload-static-site install-config"
echo "Release ${BUILD_NUMBER} publiée"
