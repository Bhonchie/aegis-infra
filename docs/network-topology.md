# Network Topology

## Physical Network

```
[AT&T Fiber ONT]
      |
[BGW320-500] — 192.168.1.254 — gateway + WiFi AP
      |         Main SSID: Reyna
      |         Guest SSID: Reyna DMZ Lounge
      |
[Netgear GS316 — 16-port unmanaged]
      |
      ├── Port 1: Aegis (enp2s0) — 192.168.1.100 static
      └── All other home devices (DHCP from BGW320)
```

## Tailscale Overlay Network

```
Tailscale tailnet: tail8fa2e1.ts.net
Aegis Tailscale IP: 100.97.183.96

Owners → full access to 192.168.1.0/24 via subnet router
Guests → port 443 on Aegis only (NPM → Homer or Jellyfin)
```

## Docker Networks

| Network | Services | Purpose |
|---|---|---|
| `proxy-net` | nginx-proxy-manager, homer | NPM front door + guest landing |
| `finance-hub_finance-net` | finance-hub-backend, finance-hub-frontend, npm | Finance Hub isolation |
| `media-net` | jellyfin, npm | Media isolation |
| `mgmt-net` | uptime-kuma, homarr, portainer, npm | Management stack |
| `adguard-net` | adguardhome | DNS isolation |

## Access Flow

```
[Device on Tailscale]
        |
        ↓ DNS: project-aegis.io → 100.97.183.96
        |
[Aegis NPM :443]
        |
        ├── project-aegis.io → homer:8080 (guest landing page)
        ├── jellyfin.project-aegis.io → jellyfin:8096
        └── homarr.project-aegis.io → homarr:7575

[Device on LAN or Tailscale (owners)]
        |
        ↓ DNS: *.home → 192.168.1.100 (via AdGuard)
        |
[Aegis NPM :443]
        |
        ├── finance.home → finance-hub-frontend:443
        ├── portainer.home → portainer:9000
        ├── adguard.home → adguardhome:3000
        └── uptime.home → uptime-kuma:3001
```
