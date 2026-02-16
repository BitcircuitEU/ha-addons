# Home Assistant Add-on: DHCP Server Manager

Dieses Add-on stellt einen verwaltbaren DHCP-Server auf Basis von `dnsmasq` bereit.
Die Verwaltung erfolgt ueber eine Web-GUI in Home Assistant (Ingress/Seitenleiste).

## Funktionen

- DHCP-Bereich konfigurieren (Start/Ende, Lease-Zeit)
- DHCP-Optionen setzen (Router, DNS, Domain, NTP)
- Zusätzliche `dhcp-option` Eintraege
- Statische Leases (`MAC,IP,Hostname`)
- Zweite GUI-Seite fuer aktive Lease-Uebersicht
- Konfigurationsvalidierung vor Uebernahme

## Add-on Optionen

```yaml
dhcp_interface: eth0
```

- `dhcp_interface`: Netzwerkinterface, auf dem DHCP angeboten wird.

## Hinweise

- Das Add-on verwendet `host_network: true`.
- Stelle sicher, dass kein anderer DHCP-Server im selben Segment aktiv ist.
- Die GUI ist ueber die Seitenleiste (Ingress) und optional direkt via `:18123` erreichbar.

## Test-Checkliste

- Add-on startet ohne Fehler und GUI ist in der HA-Seitenleiste sichtbar.
- Ein Testclient erhaelt eine Lease aus dem eingestellten Bereich.
- Aenderung von Router/DNS in der GUI wird nach Speichern uebernommen.
- Ungueltige Eingaben (z. B. falsche IP) werden mit Fehlermeldung abgewiesen.
