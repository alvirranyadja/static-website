#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ssh_common.sh
source "$ROOT/ci/ssh_common.sh"
ssh_init

ssh_remote "bash /tmp/remote-rollback.sh '${DEPLOY_PATH}'"
ssh_remote "sudo /usr/local/sbin/reload-static-site"
echo "Retour arrière effectué"
