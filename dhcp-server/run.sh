#!/bin/bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
STATE_FILE="/data/config.json"
DNSMASQ_CONF="/data/dnsmasq.conf"

DHCP_INTERFACE="eth0"
WEB_PORT="18123"

if [ -f "${OPTIONS_FILE}" ]; then
  DHCP_INTERFACE="$(jq -r '.dhcp_interface // "eth0"' "${OPTIONS_FILE}")"
fi

export DHCP_INTERFACE
export WEB_PORT
export STATE_FILE
export DNSMASQ_CONF

mkdir -p /data

if [ ! -f "${STATE_FILE}" ]; then
  cat >"${STATE_FILE}" <<'EOF'
{
  "subnet_cidr": "192.168.1.0/24",
  "range_start": "192.168.1.100",
  "range_end": "192.168.1.200",
  "lease_time": "12h",
  "router": "192.168.1.1",
  "dns_servers": "1.1.1.1,8.8.8.8",
  "domain_name": "lan",
  "ntp_server": "",
  "additional_options": "",
  "static_leases": ""
}
EOF
fi

# Erzeuge beim Start immer eine gueltige dnsmasq.conf aus der gespeicherten GUI-Konfiguration.
python3 - <<'PY'
from app import load_config, render_dnsmasq_config, DNSMASQ_CONF
DNSMASQ_CONF.write_text(render_dnsmasq_config(load_config()), encoding="utf-8")
PY

if ! dnsmasq --test --conf-file="${DNSMASQ_CONF}" >/tmp/dnsmasq-test.log 2>&1; then
  echo "[dhcp addon] dnsmasq Konfiguration ist ungueltig:"
  cat /tmp/dnsmasq-test.log || true
  exit 1
fi

echo "[dhcp addon] Starte DHCP Server Manager..."
/usr/local/bin/dnsmasq-control ensure >/tmp/dnsmasq-control.log 2>&1 || true
cat /tmp/dnsmasq-control.log || true

cleanup() {
  echo "[dhcp addon] Stoppe Dienste..."
  /usr/local/bin/dnsmasq-control stop || true
  pkill -TERM -f "gunicorn.*app:app" || true
}

trap cleanup SIGINT SIGTERM

exec gunicorn \
  --workers 1 \
  --threads 4 \
  --bind "0.0.0.0:${WEB_PORT}" \
  --chdir / \
  app:app
