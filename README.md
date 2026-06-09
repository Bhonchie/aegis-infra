# aegis-infra

Infrastructure-as-code for Aegis — GEEKOM A7 MAX home server running Ubuntu 26.04 LTS.

## Architecture

All services run in Docker via Docker Compose. Access is gated by Tailscale VPN:
- **Owners** (josh + wife): full access to home LAN (192.168.1.0/24) via subnet router
- **Guests**: Tailscale invite → Homer landing page → Jellyfin only

Domain: `project-aegis.io` — DNS A records point to Tailscale IP `100.97.183.96`.
Public DNS resolves the domain, but the IP is only reachable inside the tailnet.

See `docs/network-topology.md` for the full picture.

## Server

| | |
|---|---|
| Hardware | GEEKOM A7 MAX (Ryzen 9 7940HS, 16GB DDR5, 1TB NVMe) |
| OS | Ubuntu Server 26.04 LTS |
| Hostname | `aegis` |
| LAN IP | `192.168.1.100` (static) |
| Tailscale IP | `100.97.183.96` |
| SSH | `ssh aegis` (ed25519 key auth) |

## Services

| Service | URL | Notes |
|---|---|---|
| Homer | `https://project-aegis.io` | Guest landing page |
| Jellyfin | `https://jellyfin.project-aegis.io` | Media server |
| Homarr | `https://homarr.project-aegis.io` | Owner dashboard |
| Finance Hub | `https://finance.home` | Owner only — not on public domain |
| Portainer | `https://portainer.home` | Owner only |
| AdGuard | `https://adguard.home` | Owner only |
| Uptime Kuma | `https://uptime.home` | Owner only |
| NPM Admin | `http://192.168.1.100:81` | LAN only |

## Rebuild from Scratch

```bash
git clone git@github.com:Bhonchie/aegis-infra.git
cd aegis-infra
cp .env.example .env
# Fill in .env values, then:
bash scripts/create-networks.sh
bash scripts/tailscale-up.sh
# Approve subnet route at login.tailscale.com
# Then start services:
for svc in adguard nginx-proxy-manager jellyfin homer homarr uptime-kuma portainer watchtower; do
  docker compose -f services/$svc/docker-compose.yml up -d
done
```

## Key Docs

- `docs/tailscale-acl.hujson` — ACL policy (apply at login.tailscale.com/admin/acls)
- `docs/dns-records.md` — Cloudflare + AdGuard DNS config
- `docs/network-topology.md` — Docker networks and access flow

## Security Notes

- Finance Hub, Portainer, AdGuard, Uptime Kuma are **LAN/Tailscale-owner only** — never expose under project-aegis.io
- Homer image pinned to `v24.05.1` (Watchtower excluded) — update manually after reviewing changelog
- Cloudflare API token scoped to Zone:Read + DNS:Edit for project-aegis.io only
- mkcert root CA key lives at `C:\Users\reyna\AppData\Local\mkcert\rootCA-key.pem` — back up securely
