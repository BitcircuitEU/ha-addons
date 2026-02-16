#!/bin/bash
set -euo pipefail

DNSMASQ_CONF="${DNSMASQ_CONF:-/data/dnsmasq.conf}"
DNSMASQ_PID="/run/dnsmasq.pid"
LEASE_FILE="/data/dnsmasq.leases"
DHCP_INTERFACE="${DHCP_INTERFACE:-eth0}"

start_dnsmasq() {
  if [ ! -f "${DNSMASQ_CONF}" ]; then
    echo "[dnsmasq-control] Keine Konfiguration gefunden: ${DNSMASQ_CONF}"
    return 1
  fi

  dnsmasq \
    --keep-in-foreground \
    --conf-file="${DNSMASQ_CONF}" \
    --pid-file="${DNSMASQ_PID}" \
    --dhcp-leasefile="${LEASE_FILE}" \
    --interface="${DHCP_INTERFACE}" \
    --except-interface=lo \
    --bind-interfaces \
    --log-facility=- &
}

is_running() {
  [ -f "${DNSMASQ_PID}" ] && kill -0 "$(cat "${DNSMASQ_PID}")" 2>/dev/null
}

case "${1:-}" in
  ensure)
    if is_running; then
      echo "[dnsmasq-control] dnsmasq laeuft bereits."
      exit 0
    fi
    start_dnsmasq
    ;;
  restart)
    if is_running; then
      kill -TERM "$(cat "${DNSMASQ_PID}")" || true
      sleep 1
    fi
    start_dnsmasq
    ;;
  stop)
    if is_running; then
      kill -TERM "$(cat "${DNSMASQ_PID}")" || true
    fi
    ;;
  status)
    if is_running; then
      echo "running"
    else
      echo "stopped"
    fi
    ;;
  *)
    echo "Usage: $0 {ensure|restart|stop|status}"
    exit 1
    ;;
esac
