# Home Assistant Add-on: netboot.xyz PXE Server

Dieses Add-on stellt `netboot.xyz` als lokalen PXE-Server bereit (TFTP + HTTP + Web-Konfiguration).

## Architektur

- Unterstuetzt: `amd64`, `aarch64`
- Benoetigt einen **externen DHCP-Server** (dieses Add-on bringt keinen DHCP-Dienst mit)

## Konfiguration

```yaml
menu_version: ""
web_app_port: 3000
nginx_port: 85
path: /media/netboot/image
path_config: /media/netboot/config
tftpd_opts: ""
```

- `menu_version`: Optional feste netboot.xyz Release-Version.
- `web_app_port`: Port fuer die netboot.xyz Verwaltungsoberflaeche (Standard `3000`).
- `nginx_port`: Port fuer bereitgestellte Assets/Dateien (Standard `85`).
- `path`: Host-Pfad fuer Assets/Images.
- `path_config`: Host-Pfad fuer persistente Menue-Konfiguration (`/config/menus`).
- `tftpd_opts`: Optionale TFTP-Server Parameter.

## Externer DHCP (Beispiel)

Im externen DHCP muessen `next-server` und `boot-file-name` gesetzt werden.

Typische Boot-Dateien:

- BIOS: `netboot.xyz.kpxe`
- UEFI x64: `netboot.xyz.efi`
- UEFI ARM64: `netboot.xyz-arm64.efi`

`next-server` ist die IP von Home Assistant (bzw. des Hosts, auf dem dieses Add-on laeuft).

## Hinweise

- Das Add-on verwendet `host_network: true`, damit PXE/TFTP im LAN korrekt funktioniert.
- Das Add-on ist auf `full_access: true` gesetzt, damit du im Add-on den Schutzmodus deaktivieren
  und Vollzugriff auf den Host fuer gemappte Pfade nutzen kannst.
- Die Web-Konfiguration ist unter `http://<HA-IP>:3000` erreichbar.
- Fuer die Home-Assistant-Seitenleiste wird intern ein Ingress-Proxy verwendet, um
  absolute Webpfade der netboot.xyz UI kompatibel zu machen.
- `path_config` wird bewusst nur fuer Menue-Daten genutzt, damit die netboot Webapp stabil bleibt.
- Das Startskript setzt Schreibrechte auf `path`/`path_config`, damit die Webapp nicht
  in einen Restart-Loop faellt, wenn Host-Mounts nur root-schreibbar sind.
