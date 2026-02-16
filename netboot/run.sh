#!/bin/bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"

MENU_VERSION=""
WEB_APP_PORT="3000"
NGINX_PORT="85"
PATH_ASSETS="/media/netboot/image"
PATH_CONFIG="/media/netboot/config"
TFTPD_OPTS=""

if [ -f "${OPTIONS_FILE}" ]; then
  MENU_VERSION="$(jq -r '.menu_version // ""' "${OPTIONS_FILE}")"
  WEB_APP_PORT="$(jq -r '.web_app_port // 3000' "${OPTIONS_FILE}")"
  NGINX_PORT="$(jq -r '.nginx_port // 85' "${OPTIONS_FILE}")"
  PATH_ASSETS="$(jq -r '.path // "/media/netboot/image"' "${OPTIONS_FILE}")"
  PATH_CONFIG="$(jq -r '.path_config // "/media/netboot/config"' "${OPTIONS_FILE}")"
  TFTPD_OPTS="$(jq -r '.tftpd_opts // ""' "${OPTIONS_FILE}")"
fi

export WEB_APP_PORT
export NGINX_PORT
export TFTPD_OPTS

mkdir -p "${PATH_ASSETS}" "${PATH_CONFIG}"
# Webapp laeuft als non-root User (nbxyz). Auf Host-Mounts (/media/...) fehlen
# sonst haeufig Schreibrechte und der Webprozess crasht in einer Restart-Schleife.
chmod 0777 "${PATH_ASSETS}" "${PATH_CONFIG}" || true

if [ -L /assets ]; then
  rm -f /assets
elif [ -d /assets ]; then
  rm -rf /assets
else
  rm -f /assets || true
fi
ln -s "${PATH_ASSETS}" /assets

# WICHTIG:
# /config komplett zu ersetzen kann den Webapp-Dienst (Port 3000) brechen.
# Deshalb bleibt /config als Basis erhalten und nur relevante Inhalte werden nach path_config ausgelagert.
mkdir -p /config
mkdir -p "${PATH_CONFIG}/menus"
chmod 0777 "${PATH_CONFIG}/menus" || true

if [ -L /config/menus ]; then
  rm -f /config/menus
elif [ -d /config/menus ]; then
  if [ -n "$(ls -A /config/menus 2>/dev/null)" ]; then
    cp -a /config/menus/. "${PATH_CONFIG}/menus/" || true
  fi
  rm -rf /config/menus
fi
ln -s "${PATH_CONFIG}/menus" /config/menus

mkdir -p /config/nginx/site-confs /config/menus/remote /config/menus/local
chmod 0777 /config/menus /config/menus/remote /config/menus/local || true

if [ -n "${MENU_VERSION}" ]; then
  export MENU_VERSION
  echo "[netboot addon] Verwende festes netboot.xyz Menu-Release: ${MENU_VERSION}"
else
  echo "[netboot addon] Kein MENU_VERSION gesetzt - lade beim ersten Start das neueste Release."
fi

# Workaround fuer HA Ingress:
# netboot.xyz nutzt teilweise absolute Pfade (z. B. /socket.io), die unter Ingress brechen.
# Wir haengen deshalb einen internen Nginx-Rewrite-Proxy auf Port 8099 davor.
mkdir -p /config/nginx/site-confs
cat >/config/nginx/site-confs/ingress.conf <<EOF
server {
    listen 8099;
    location / {
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Ingress-Path \$http_x_ingress_path;
        # sub_filter funktioniert nur zuverlaessig mit unkomprimiertem Upstream-Body
        proxy_set_header Accept-Encoding "";
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://127.0.0.1:${WEB_APP_PORT};
        proxy_redirect off;
        proxy_buffering off;
        sub_filter_once off;
        sub_filter_types text/html text/css application/javascript application/json;
        sub_filter '<head>' '<head><base href="\$http_x_ingress_path/">';
        sub_filter 'href="/' 'href="\$http_x_ingress_path/';
        sub_filter 'src="/' 'src="\$http_x_ingress_path/';
        sub_filter "href='/" "href='\$http_x_ingress_path/";
        sub_filter "src='/" "src='\$http_x_ingress_path/";
        sub_filter 'action="/' 'action="\$http_x_ingress_path/';
        sub_filter "action='/" "action='\$http_x_ingress_path/";
        sub_filter 'url(/' 'url(\$http_x_ingress_path/';
        sub_filter '"/socket.io' '"\$http_x_ingress_path/socket.io';
        sub_filter "'/socket.io" "'\$http_x_ingress_path/socket.io";
    }

    location /socket.io/ {
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://127.0.0.1:${WEB_APP_PORT}/socket.io/;
    }
}
EOF

echo "[netboot addon] Mapping Assets: ${PATH_ASSETS} -> /assets"
echo "[netboot addon] Mapping Config-Menus: ${PATH_CONFIG}/menus -> /config/menus"
echo "[netboot addon] Schreibtest Assets-Pfad: $( [ -w "${PATH_ASSETS}" ] && echo ok || echo fail )"
echo "[netboot addon] Schreibtest Config-Pfad: $( [ -w "${PATH_CONFIG}/menus" ] && echo ok || echo fail )"
echo "[netboot addon] Starte netboot.xyz (WebUI ${WEB_APP_PORT}, HTTP ${NGINX_PORT}, TFTP 69/udp)..."
exec /start.sh
