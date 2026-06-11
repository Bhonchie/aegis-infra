# Aegis — Build Progress Tracker

**Server:** GEEKOM A7 MAX | **Hostname:** `aegis` | **IP:** `192.168.1.100`
**OS:** Ubuntu Server 26.04 LTS | **Stack:** Docker + Docker Compose + Portainer
**Last Updated:** 2026-06-10

---

## Phase 1 — Foundation ✅ COMPLETE

- [x] Ubuntu Server 26.04 LTS installed ✅ 2026-04-29
- [x] Static IP 192.168.1.100 — netplan on enp2s0 ✅ 2026-04-29
- [x] SSH key auth from Windows (ed25519, no password) ✅ 2026-04-29
- [x] ufw firewall configured ✅ 2026-04-29
- [x] Docker 29.4.1 + Compose v5.1.3 installed ✅ 2026-04-29
- [x] Portainer CE live at http://192.168.1.100:9000 ✅ 2026-04-29
- [x] Aegis hardwired to Netgear GS316, moved to network closet ✅ 2026-04-29
- [x] Jellyfin deployed — hardware transcoding via /dev/dri → Radeon 780M ✅ 2026-04-30
- [x] Finance Hub deployed ✅ 2026-05-30

---

## Phase 1b — Management Stack ✅ COMPLETE (2026-05-31)

All services deployed under `/opt/services/` with named Docker networks for isolation.

### Running Services

| Container | URL | Status | Notes |
|---|---|---|---|
| `finance-hub-backend` | internal only | ✅ healthy | FastAPI, port 8000 internal |
| `finance-hub-frontend` | https://finance.home / https://tyche.local | ✅ up | nginx, SSL via NPM |
| `jellyfin` | https://jellyfin.project-aegis.io | ✅ up | port 8096 internal |
| `portainer` | https://portainer.home | ✅ up | port 9000 on host |
| `nginx-proxy-manager` | http://192.168.1.100:81 (admin) | ✅ up | ports 80/443/81 on host |
| `uptime-kuma` | no proxy host currently | ✅ healthy | port 3001 internal |
| `homarr` | https://homarr.project-aegis.io | ✅ up | port 7575 internal |
| `homer` | https://project-aegis.io | ✅ up | port 8080 internal, guest landing page |
| `watchtower` | no UI | ✅ healthy | weekly Sunday 3am, Finance Hub + Homer excluded |
| `adguardhome` | http://192.168.1.100:3000 | ✅ up | DNS rewrites + blocklists configured |
| `github-runner` | no UI | ⚠️ crash-looping | fix deferred — unrelated to current phase |

### Docker Networks

| Network | Containers | Notes |
|---|---|---|
| `proxy-net` | nginx-proxy-manager, homer | NPM front door |
| `finance-hub_finance-net` | finance-hub-backend, finance-hub-frontend, NPM | Isolated — no lateral movement |
| `media-net` | jellyfin, NPM | Isolated from finance |
| `mgmt-net` | uptime-kuma, homarr, NPM | Internal management |
| `adguard-net` | adguardhome | DNS server, isolated |
| `bridge` (default) | portainer | Legacy — portainer only |

### SSL Certificates in NPM

| Cert | Type | Covers | Expires |
|---|---|---|---|
| mkcert wildcard | Custom (uploaded) | `*.home`, `finance.home`, `192.168.1.100` | Aug 2028 |
| tyche.local | Custom (uploaded) | `tyche.local` | Aug 2028 |
| *.project-aegis.io | Let's Encrypt (Cloudflare DNS) | `*.project-aegis.io`, `project-aegis.io` | ~Sep 2026 (auto-renews) |

CA root for trusting *.home on other devices: `C:\Users\reyna\AppData\Local\mkcert\rootCA.pem`

### NPM Proxy Hosts (current as of 2026-06-10)

| Domain | Backend | SSL Cert | Notes |
|---|---|---|---|
| `project-aegis.io` | homer:8080 | LE wildcard | Guest landing page — Tailscale required |
| `jellyfin.project-aegis.io` | jellyfin:8096 | LE wildcard | Guest + owner — Tailscale required |
| `homarr.project-aegis.io` | homarr:7575 | LE wildcard | Owner only (app auth) — Tailscale required |
| `finance.home` | finance-hub-frontend:443 HTTPS | mkcert *.home | Owner only — AdGuard DNS required |
| `portainer.home` | 192.168.1.100:9000 | mkcert *.home | Owner only — AdGuard DNS required |
| `tyche.local` | finance-hub-frontend:443 HTTPS | tyche.local custom | Owner only — mDNS (LAN) |

> **Note:** `jellyfin.home`, `homarr.home`, `uptime.home`, `adguard.home` proxy hosts were removed.
> All *.project-aegis.io URLs require Tailscale. All *.home URLs require AdGuard DNS on device.

### AdGuard Home

- DNS rewrites: `*.home` → 192.168.1.100, `tyche.local` → 192.168.1.100
- Blocklists: OISD Full (494k rules), Steven Black (81k), HaGeZi Pro (218k)
- Upstream DNS: 1.1.1.1 + 8.8.8.8
- Admin: http://192.168.1.100:3000

### Finance Hub CI/CD

- GitHub Actions self-hosted runner on Aegis (`github-runner` container) — currently crash-looping
- Workflow: `.github/workflows/deploy.yml` — push to `main` → auto-deploy

---

## Phase 1c — Tailscale + Domain (project-aegis.io) ✅ COMPLETE (2026-06-10)

Goal: VPN-gated remote access. Owners get full LAN access via Tailscale. Guests get Jellyfin only via Homer landing page at project-aegis.io. Nothing publicly accessible without VPN.

### Architecture

```
[Internet] → DNS: project-aegis.io → 100.97.183.96 (Tailscale IP — unreachable without VPN)
                                              ↓ [Must be on Tailscale tailnet]
                                    [Aegis NPM port 443]
                                              ↓
                     ┌────────────────────────┼──────────────────────┐
                homer:8080             jellyfin:8096        homarr:7575
             (guest landing)           (guest+owner)        (owner only)
```

### Tailscale

- **Aegis Tailscale IP:** `100.97.183.96`
- **Devices on tailnet:**
  - `aegis` (100.97.183.96) — Linux server, subnet router
  - `ironclad` (100.96.43.77) — Josh's Windows desktop
  - `pixel-9a` (100.96.3.36) — Josh's Android phone
- **Subnet route:** `192.168.1.0/24` advertised + approved — owners get full LAN access remotely
- **`--accept-dns=false`** — CRITICAL: prevents Tailscale from overwriting /etc/resolv.conf and breaking AdGuard
- **IP forwarding:** enabled + persistent (`/etc/sysctl.d/99-tailscale.conf`)
- **UDP GRO fix:** applied + persistent (`/etc/networkd-dispatcher/routable.d/50-tailscale`)
- **ACL:** `group:owners` = reynaja93@gmail.com → full access. `group:guests` = [] → port 443 only

### Cloudflare DNS (project-aegis.io)

- A record `@` → 100.97.183.96 (DNS only, gray cloud)
- A record `*` → 100.97.183.96 (DNS only, gray cloud)
- API token `aegis-letsencrypt-dns` — Zone:Read + DNS:Edit (scoped to project-aegis.io only)

### Infrastructure Repo

- **GitHub:** https://github.com/Bhonchie/aegis-infra (private)
- All service compose files, scripts, docs version-controlled there

---

## ⏳ Pending Items

### Security (do before inviting guests)
- [ ] MFA on Tailscale account ⚠️
- [ ] MFA on Cloudflare account ⚠️
- [ ] BGW320 IP Passthrough confirmed OFF
- [ ] Cloudflare API token saved in password manager

### Tailscale Device Coverage
- [ ] Tailscale installed on wife's devices
- [ ] End-to-end test: cellular on phone (WiFi off) → https://project-aegis.io
- [ ] Subnet routing verified from off-network (ping 192.168.1.1)

### Known Issues
- `github-runner` container crash-looping — deferred fix
- `uptime.home` and `adguard.home` have no NPM proxy host — add back if needed
- AdGuard DNS still not pushed to all home devices automatically (BGW320 DHCP DNS locked by AT&T — Phase 3 fix)
- Wife's devices need mkcert CA root installed for *.home green padlock

---

## Phase 2 — Home Automation
*Planned — not started*

- [ ] Deploy Home Assistant
- [ ] Integrate Ecobee thermostat (HomeKit Device — local control)
- [ ] Integrate Samsung fridge + oven (SmartThings OAuth)
- [ ] Deploy Immich — import Google Photos (~100GB via Google Takeout)
- [ ] Configure Immich phone auto-backup
- [ ] Deploy Frigate NVR + connect cameras via POE-SW501
- [ ] Deploy Ollama (local LLM)

---

## Phase 3 — Network Hardening
*Requires managed switch purchase*

- [ ] Buy managed switch (Netgear GS308E or similar)
- [ ] Configure VLANs: Main / IoT / Kids / Servers / Work
- [ ] Replace BGW320 DHCP with Aegis/AdGuard DHCP → pushes DNS automatically to all devices
- [ ] AdGuard per-VLAN parental control rules + time schedules for kids

---

## Hardware Still Needed

| Item | For | Status |
|---|---|---|
| Terramaster D4-320 | Storage enclosure | Not yet ordered |
| 4× WD Red Plus 6TB (CMR) | NAS drives | Not yet ordered |
| Managed switch (Netgear GS308E or similar) | Phase 3 VLANs + DNS routing | Not yet ordered |

---

## Notes & Decisions Log

| Date | Note |
|---|---|
| 2026-04-29 | Ubuntu 26.04 LTS installed — codename "Resolute", kernel 7.0.0-14 |
| 2026-04-29 | Ethernet: enp2s0 / MAC: 38:f7:cd:da:5e:c4. Static IP via netplan. Gateway 192.168.1.254 |
| 2026-04-29 | Docker 29.4.1 + Compose v5.1.3 installed |
| 2026-04-30 | Switched from Plex to Jellyfin — free, open source, hardware transcoding |
| 2026-04-30 | Art Gallery library in Jellyfin — wife's 16 masterworks (AIC public domain) |
| 2026-05-30 | Finance Hub Phase 2 complete |
| 2026-05-31 | Full management stack deployed — NPM, Homarr, Uptime Kuma, Watchtower, AdGuard |
| 2026-05-31 | Docker networks restructured — service isolation enforced |
| 2026-05-31 | mkcert wildcard cert — covers *.home, valid Aug 2028 |
| 2026-05-31 | Finance Hub moved off host ports 80/443 — NPM now owns those ports |
| 2026-06-01 | GitHub Actions self-hosted runner deployed — Finance Hub CI/CD live |
| 2026-06-01 | Guest WiFi "Reyna DMZ Lounge" created — visitors isolated from LAN |
| 2026-06-01 | Main WiFi password rotated |
| 2026-06-01 | BGW320 DNS config locked by AT&T — cannot push AdGuard DNS via DHCP |
| 2026-06-08 | project-aegis.io purchased on Cloudflare Registrar |
| 2026-06-08 | Tailscale v1.98.4 installed. Subnet route approved. IP: 100.97.183.96 |
| 2026-06-08 | Tailscale ACL configured. DNS configured (100.97.183.96 + 1.1.1.1 fallback) |
| 2026-06-08 | Cloudflare DNS A records set. LE wildcard cert issued via DNS challenge |
| 2026-06-08 | Homer deployed as guest landing page (pinned v24.05.1, Watchtower excluded) |
| 2026-06-08 | aegis-infra GitHub repo created: https://github.com/Bhonchie/aegis-infra |
| 2026-06-10 | IP forwarding + UDP GRO fix applied and made persistent on Aegis |
| 2026-06-10 | All project-aegis.io NPM proxy hosts confirmed working |
| 2026-06-10 | finance.home proxy host added (NPM → finance-hub-frontend:443 HTTPS) |
| 2026-06-10 | tyche.local cert uploaded to NPM, proxy host added — tyche.local restored |
| 2026-06-10 | portainer.home proxy host fixed (NPM → 192.168.1.100:9000) |
| 2026-06-10 | home-infra docs merged into aegis-infra repo |
