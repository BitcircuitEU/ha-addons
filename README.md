# Terhorst.IO Home Assistant Add-on Repository

Dieses Repository ist ein **Home Assistant Add-on Repository** (nicht HACS-Integration).

## Repository in Home Assistant hinzufuegen

1. Home Assistant -> **Einstellungen** -> **Add-ons** -> **Add-on-Store**
2. Oben rechts auf die drei Punkte -> **Repositories**
3. GitHub-URL dieses Repos einfuegen (z. B. `https://github.com/BitcircuitEU/ha-addons`)
4. Add-on installieren und starten

## Enthaltene Add-ons

- `netboot`: netboot.xyz PXE Server
- `dhcp-server`: DHCP Server Manager (dnsmasq + Web-GUI)

## Struktur

- `repository.yaml`: Metadaten fuer das Add-on-Repository
- `netboot/`: netboot.xyz Add-on
- `dhcp-server/`: DHCP Server Add-on

## Wichtiger Hinweis zu HACS

HACS ist in erster Linie fuer Integrationen, Frontend-Karten und Themes.
Add-ons werden in Home Assistant ueber den Add-on-Store als **Custom Repository** eingebunden.