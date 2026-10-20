#!/usr/bin/env bash
# Prépare la machine de déploiement (Ubuntu ou Amazon Linux). À lancer une fois, en root.
# La machine est dédiée à ce site : le script remplace la config nginx par défaut.
#
#   sudo bash deploy/bootstrap-deploy-host.sh
#
# Ensuite, depuis la machine Jenkins :
#   ssh-keygen -t ed25519 -f jenkins-deploy -N ""
#   coller la clé publique dans /home/deploy/.ssh/authorized_keys
#   enregistrer la clé privée dans Jenkins (credential deploy-ssh-key)
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Lancez ce script avec sudo." >&2
  exit 1
fi

DEPLOY_PATH="${DEPLOY_PATH:-/var/www/static-website}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
SRC="$(cd "$(dirname "$0")" && pwd)"

if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  apt-get install -y nginx curl tar
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y nginx curl tar
elif command -v yum >/dev/null 2>&1; then
  yum install -y nginx curl tar
else
  echo "Gestionnaire de paquets inconnu." >&2
  exit 1
fi

if id nginx >/dev/null 2>&1; then
  NGINX_USER="nginx"
elif id www-data >/dev/null 2>&1; then
  NGINX_USER="www-data"
else
  echo "Utilisateur nginx introuvable." >&2
  exit 1
fi

if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$DEPLOY_USER"
fi

mkdir -p "$DEPLOY_PATH/releases" /home/"$DEPLOY_USER"/.ssh
chmod 755 "$DEPLOY_PATH"
chmod 700 /home/"$DEPLOY_USER"/.ssh
touch /home/"$DEPLOY_USER"/.ssh/authorized_keys
chmod 600 /home/"$DEPLOY_USER"/.ssh/authorized_keys
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$DEPLOY_PATH" /home/"$DEPLOY_USER"/.ssh

install -m 755 "$SRC/reload-static-site" /usr/local/sbin/reload-static-site
install -m 440 "$SRC/sudoers-deploy" /etc/sudoers.d/deploy-static-website
visudo -cf /etc/sudoers.d/deploy-static-website

if [ -f /etc/nginx/nginx.conf ] && [ ! -f /etc/nginx/nginx.conf.before-static-website ]; then
  cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf.before-static-website
fi
sed "s#__NGINX_USER__#${NGINX_USER}#g" "$SRC/nginx/nginx.conf" > /etc/nginx/nginx.conf
rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

install -m 644 "$SRC/nginx/security-headers.conf" /etc/nginx/conf.d/security-headers.conf
sed "s#__DEPLOY_PATH__#${DEPLOY_PATH}#g" "$SRC/nginx/static-website.conf" \
  > /etc/nginx/conf.d/static-website.conf

# Page minimale pour que nginx démarre avant le premier déploiement Jenkins.
if [ ! -L "$DEPLOY_PATH/current" ]; then
  mkdir -p "$DEPLOY_PATH/releases/bootstrap"
  printf '%s\n' '<!DOCTYPE html><html><head><title>Welcome</title></head><body><h1>Dimension</h1><p>En attente du premier déploiement.</p></body></html>' \
    > "$DEPLOY_PATH/releases/bootstrap/index.html"
  ln -sfn "$DEPLOY_PATH/releases/bootstrap" "$DEPLOY_PATH/current"
  chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$DEPLOY_PATH"
fi

if command -v getenforce >/dev/null 2>&1; then
  mode="$(getenforce 2>/dev/null || true)"
  if [ "$mode" = "Enforcing" ] || [ "$mode" = "Permissive" ]; then
    chcon -R -t httpd_sys_content_t "$DEPLOY_PATH" || true
  fi
fi

nginx -t
systemctl enable nginx
systemctl restart nginx

echo
echo "Machine prête."
echo "Ajoutez la clé publique Jenkins dans /home/${DEPLOY_USER}/.ssh/authorized_keys"
echo "Ouvrez le port 22 depuis l'EC2 Jenkins, et le port 80 vers les visiteurs."
echo "Racine du site : ${DEPLOY_PATH}/current"
