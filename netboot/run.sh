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

if [ -L /assets ]; then
  rm -f /assets
elif [ -d /assets ]; then
  rm -rf /assets
else
  rm -f /assets || true
fi
ln -s "${PATH_ASSETS}" /assets

if [ -L /config ]; then
  rm -f /config
elif [ -d /config ]; then
  if grep -q " /config " /proc/mounts; then
    echo "[netboot addon] /config ist ein Mount und wird nicht ersetzt."
  else
    rm -rf /config
  fi
else
  rm -f /config || true
fi

if [ ! -e /config ]; then
  ln -s "${PATH_CONFIG}" /config
fi

mkdir -p /config/nginx/site-confs /config/menus/remote /config/menus/local

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
echo "[netboot addon] Mapping Config: ${PATH_CONFIG} -> /config"
echo "[netboot addon] Starte netboot.xyz (WebUI ${WEB_APP_PORT}, HTTP ${NGINX_PORT}, TFTP 69/udp)..."
exec /start.sh
