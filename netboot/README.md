# Home Assistant Add-on: netboot.xyz PXE Server

Dieses Add-on stellt `netboot.xyz` als lokalen PXE-Server bereit (TFTP + HTTP + Web-Konfiguration).

## Architektur

- Unterstuetzt: `amd64`, `aarch64`
- Benoetigt einen **externen DHCP-Server** (dieses Add-on bringt keinen DHCP-Dienst mit)

## Konfiguration

```yaml
web_app_port: 3000
nginx_port: 80
```

- `web_app_port`: Port fuer die netboot.xyz Verwaltungsoberflaeche (Standard `3000`).
- `nginx_port`: Port fuer bereitgestellte Assets/Dateien (Standard `80`).

## Externer DHCP (Beispiel)

Im externen DHCP muessen `next-server` und `boot-file-name` gesetzt werden.

Typische Boot-Dateien:

- BIOS: `netboot.xyz.kpxe`
- UEFI x64: `netboot.xyz.efi`
- UEFI ARM64: `netboot.xyz-arm64.efi`

`next-server` ist die IP von Home Assistant (bzw. des Hosts, auf dem dieses Add-on laeuft).

## Hinweise

- Das Add-on verwendet `host_network: true`, damit PXE/TFTP im LAN korrekt funktioniert.
- Die Web-Konfiguration ist unter `http://<HA-IP>:3000` erreichbar.
- Fuer die Home-Assistant-Seitenleiste wird intern ein Ingress-Proxy verwendet, um
  absolute Webpfade der netboot.xyz UI kompatibel zu machen.
