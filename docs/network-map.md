# Aegis — Network & Service Map
> Last updated: 2026-06-10
> Update this file whenever a service is added, removed, or reconfigured.

---

## Physical Network

```
[AT&T Fiber ONT]
        │
[AT&T BGW320-500]  ← 192.168.1.254 (gateway + WiFi AP)
        │              Main SSID: Reyna
        │              Guest SSID: Reyna DMZ Lounge (LAN-isolated)
        │              DNS: locked — cannot push custom DNS via DHCP (AT&T limitation)
        │
[Netgear GS316]    ← 16-port unmanaged switch (no VLANs — Phase 3)
        │
[Aegis]            ← 192.168.1.100 static (enp2s0 ethernet, primary)
                       100.97.183.96 (Tailscale VPN IP)
                       Ubuntu 26.04 LTS, Docker 29.4.1
```

---

## Tailscale Overlay Network

```
[Tailnet: reynaja93@gmail.com]
        │
        ├── aegis        100.97.183.96  (subnet router → 192.168.1.0/24)
        ├── ironclad     100.96.43.77   (Josh's Windows desktop)
        └── pixel-9a     100.96.3.36    (Josh's Android phone)
```

- Aegis advertises subnet `192.168.1.0/24` — owners can reach all LAN devices remotely
- `--accept-dns=false` on Aegis — Tailscale does NOT overwrite /etc/resolv.conf (protects AdGuard)
- Tailscale DNS: points to 100.97.183.96 (AdGuard via Tailscale IP) + 1.1.1.1 fallback
- ACL: owners → full access. guests → port 443 on aegis only (Homer landing page)

---

## Docker Services

| Container | Image | Status | Host Ports | Docker Network(s) |
|---|---|---|---|---|
| `finance-hub-backend` | local build | ✅ healthy | none (internal) | finance-hub_finance-net |
| `finance-hub-frontend` | local build | ✅ up | none (internal) | finance-hub_finance-net |
| `jellyfin` | lscr.io/linuxserver/jellyfin | ✅ up | 8096 | media-net |
| `portainer` | portainer/portainer-ce | ✅ up | 9000, 9443 | bridge |
| `nginx-proxy-manager` | jc21/nginx-proxy-manager | ✅ up | 80, 443, 81 | proxy-net + all service nets |
| `homer` | b4bz/homer:v24.05.1 | ✅ up | none (internal) | proxy-net |
| `uptime-kuma` | louislam/uptime-kuma | ✅ healthy | none (internal) | mgmt-net |
| `homarr` | ghcr.io/ajnart/homarr | ✅ up* | none (internal) | mgmt-net |
| `watchtower` | containrrr/watchtower | ✅ healthy | none | host socket |
| `adguardhome` | adguard/adguardhome | ✅ up | 53 (DNS), 3000 | adguard-net |
| `github-runner` | myoung34/github-runner | ⚠️ crashing | none | host socket |

*Homarr reports unhealthy via Docker health check — known false negative, app works fine.

---

## Docker Networks

| Network | Containers | Isolation |
|---|---|---|
| `proxy-net` | nginx-proxy-manager, homer | NPM + Homer only |
| `finance-hub_finance-net` | backend, frontend, NPM | Isolated — no path to media or mgmt |
| `media-net` | jellyfin, NPM | Isolated from finance |
| `mgmt-net` | uptime-kuma, homarr, NPM | Internal management only |
| `adguard-net` | adguardhome | DNS — isolated |
| `bridge` (default) | portainer | Legacy — portainer only (not on mgmt-net) |

> NPM is the only container that joins multiple networks by design — it's the reverse proxy front door.

---

## Access Points

### Public-facing (Tailscale required — DNS resolves to 100.97.183.96)

| Service | URL | Who |
|---|---|---|
| Homer (landing page) | https://project-aegis.io | Owners + guests |
| Jellyfin | https://jellyfin.project-aegis.io | Owners + guests |
| Homarr (owner dashboard) | https://homarr.project-aegis.io | Owners (app auth) |

### LAN / Owner-only (AdGuard DNS or mDNS required)

| Service | URL | Notes |
|---|---|---|
| Finance Hub | https://finance.home | Requires AdGuard DNS on device |
| Finance Hub | https://tyche.local | mDNS via Avahi (LAN only) |
| Portainer | https://portainer.home | Requires AdGuard DNS on device |
| Portainer | http://192.168.1.100:9000 | LAN direct |
| AdGuard | http://192.168.1.100:3000 | LAN direct |
| NPM Admin | http://192.168.1.100:81 | LAN direct |

> **Security note:** Admin services (Finance Hub, Portainer, AdGuard) are deliberately NOT exposed
> under `project-aegis.io`. Even guests on Tailscale can't reach them by domain name.

---

## NPM Proxy Hosts

| Domain | Backend | Cert | Verify SSL |
|---|---|---|---|
| `project-aegis.io` | homer:8080 | LE wildcard *.project-aegis.io | N/A |
| `jellyfin.project-aegis.io` | jellyfin:8096 | LE wildcard | N/A |
| `homarr.project-aegis.io` | homarr:7575 | LE wildcard | N/A |
| `finance.home` | finance-hub-frontend:443 HTTPS | mkcert *.home | Off (mkcert cert) |
| `portainer.home` | 192.168.1.100:9000 HTTP | mkcert *.home | N/A |
| `tyche.local` | finance-hub-frontend:443 HTTPS | tyche.local custom | Off (mkcert cert) |

---

## SSL Certificates

| Cert | Location | Covers | Expires |
|---|---|---|---|
| mkcert wildcard | `D:\Josh\Dev\certs\homelab.crt` + `.key` | `*.home`, `finance.home`, `192.168.1.100` | Aug 2028 |
| tyche.local mkcert | `/opt/finance-hub/nginx/certs/tyche.local.crt` | `tyche.local` | Aug 2028 |
| LE wildcard | NPM (auto-renews via Cloudflare DNS challenge) | `*.project-aegis.io`, `project-aegis.io` | ~Sep 2026 |

CA root for trusting *.home on other devices: `C:\Users\reyna\AppData\Local\mkcert\rootCA.pem`

---

## AdGuard Home

- **Admin:** http://192.168.1.100:3000
- **DNS rewrites:** `*.home` → 192.168.1.100, `tyche.local` → 192.168.1.100
- **Blocklists:** OISD Full (494k), Steven Black (81k), HaGeZi Pro (218k)
- **Upstream DNS:** 1.1.1.1, 8.8.8.8
- **DNS routing to devices:** ⏳ Pending — BGW320 DHCP DNS locked. Fix in Phase 3.

---

## Port Reference

| Port | Protocol | Service | Exposed To |
|---|---|---|---|
| 53 | TCP/UDP | AdGuard Home | Host (DNS) |
| 80 | TCP | Nginx Proxy Manager | Host (HTTP → HTTPS redirect) |
| 81 | TCP | NPM Admin UI | Host (LAN only) |
| 443 | TCP | Nginx Proxy Manager | Host (HTTPS — also Tailscale) |
| 3000 | TCP | AdGuard Admin | Host (LAN only) |
| 8096 | TCP | Jellyfin | Host (LAN only) |
| 9000 | TCP | Portainer | Host (LAN only) |
| 41641 | UDP | Tailscale | Host (Tailscale VPN — outbound only, no port forward needed) |

---

## Security Notes

- **VPN-gated domain:** project-aegis.io DNS resolves to Tailscale IP — unreachable without Tailscale
- **No port forwarding on BGW320** — Tailscale handles all remote connectivity
- **Admin services off public domain:** Finance Hub, Portainer, AdGuard have no project-aegis.io proxy hosts
- **Guest ACL is port-level:** guests reach aegis:443 → NPM routes by Host header → only Homer/Jellyfin have *.project-aegis.io hostnames
- **Lateral movement blocked:** Jellyfin and Finance Hub on separate Docker networks
- **NPM is the only multi-network container** — by design as the reverse proxy front door
- **Portainer = root-equivalent** — Docker socket access. Keep restricted to owner devices
- **Guest WiFi isolated** — Reyna DMZ Lounge cannot reach 192.168.1.x
- **Watchtower skips Finance Hub and Homer** — controlled updates only

---

## Phase 3 — What Changes

When managed switch arrives:
- VLANs: Main / IoT / Kids / Servers / Work
- Move DHCP to Aegis (AdGuard) — automatically pushes DNS=192.168.1.100 to all devices
- Per-VLAN AdGuard filtering rules (kids devices get strict rules + time schedules)
