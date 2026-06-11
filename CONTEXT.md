# Aegis Infrastructure — Claude Context

This file gives Claude full context on the Aegis home server build. Read this at the start of any
infrastructure session. Then run the session-start check below before touching anything.

---

## Session Start

```bash
ssh aegis "echo connected && docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

Also check `docs/progress.md` for current phase status.

---

## The Server

| | |
|---|---|
| Hardware | GEEKOM A7 MAX (Ryzen 9 7940HS, 16GB DDR5, 1TB NVMe, dual 2.5GbE) |
| OS | Ubuntu Server 26.04 LTS ("Resolute", kernel 7.0.0) |
| Hostname | `aegis` |
| LAN IP | `192.168.1.100` (static via netplan on enp2s0) |
| Tailscale IP | `100.97.183.96` |
| SSH | `ssh aegis` (ed25519 key, no password) |
| SSH config | `C:\Users\reyna\.ssh\config` → Host aegis → IdentityFile ~/.ssh/id_ed25519 |

---

## How Claude Connects

Via `Bash` tool: `ssh aegis "<command>"` works directly. Commands requiring sudo must be written
to `/tmp` as a script and run manually by Josh — sudo over non-interactive SSH fails.

---

## File Locations on Aegis

| Path | What's there |
|---|---|
| `/opt/services/` | All Docker Compose stacks (homer, homarr, jellyfin, NPM, etc.) |
| `/opt/finance-hub/` | Finance Hub backend + frontend (separate project) |
| `/opt/services/nginx-proxy-manager/data/` | NPM config, certs, proxy host confs |
| `/opt/finance-hub/nginx/certs/` | tyche.local mkcert cert + key |

---

## Network Architecture

```
[Internet]
    │
[AT&T BGW320-500]  192.168.1.254  (gateway — NO port forwarding configured)
    │
[Netgear GS316]    16-port unmanaged switch
    │
[Aegis]            192.168.1.100 (LAN) / 100.97.183.96 (Tailscale)
    │
[NPM :443]         Routes all HTTPS by hostname
    ├── project-aegis.io         → homer:8080      (guest landing)
    ├── jellyfin.project-aegis.io → jellyfin:8096  (media)
    ├── homarr.project-aegis.io  → homarr:7575     (owner dashboard)
    ├── finance.home             → finance-hub-frontend:443
    ├── portainer.home           → 192.168.1.100:9000
    └── tyche.local              → finance-hub-frontend:443
```

**VPN-gating:** `project-aegis.io` DNS resolves to `100.97.183.96` (Tailscale IP). Public DNS
reveals the IP, but it's only reachable inside the tailnet. No port forwarding. No public exposure.

---

## Tailscale

- **Auth:** reynaja93@gmail.com
- **Devices:** aegis (server), ironclad (Josh Windows desktop), pixel-9a (Josh phone)
- **Wife's devices:** not yet added
- **Subnet route:** `192.168.1.0/24` advertised + approved — owners reach all LAN devices remotely
- **CRITICAL flag:** `--accept-dns=false` — without this, Tailscale overwrites /etc/resolv.conf
  and breaks AdGuard DNS for all Docker containers. Never run `tailscale up` without this flag.
- **Script:** `scripts/tailscale-up.sh` has the correct command

### ACL Policy (admin console → Access Controls)

```json
{
  "groups": {
    "group:owners": ["reynaja93@gmail.com"],
    "group:guests": []
  },
  "hosts": { "aegis": "100.97.183.96" },
  "acls": [
    { "action": "accept", "src": ["group:owners"], "dst": ["*:*"] },
    { "action": "accept", "src": ["group:guests"], "dst": ["aegis:443"] }
  ]
}
```

To invite a guest: add their email to `group:guests`, create a Jellyfin account for them,
share `https://project-aegis.io`.

---

## Domain: project-aegis.io

- **Registrar:** Cloudflare
- **DNS:** Two A records (@ and *) pointing to 100.97.183.96, DNS-only (gray cloud, not proxied)
- **Why gray cloud:** Cloudflare can't proxy a Tailscale IP — orange cloud silently fails
- **API token:** `aegis-letsencrypt-dns` scoped to Zone:Read + DNS:Edit for project-aegis.io only
  — used by NPM for Let's Encrypt DNS challenge auto-renewal

---

## Services Reference

### Services accessible to owners + guests (Tailscale required)

| URL | Backend | Purpose |
|---|---|---|
| https://project-aegis.io | homer:8080 | Guest landing page |
| https://jellyfin.project-aegis.io | jellyfin:8096 | Media streaming |
| https://homarr.project-aegis.io | homarr:7575 | Owner infrastructure dashboard |

### Owner-only (AdGuard DNS or LAN required)

| URL | Backend | Purpose |
|---|---|---|
| https://finance.home | finance-hub-frontend:443 | Family Finance Hub |
| https://tyche.local | finance-hub-frontend:443 | Finance Hub (mDNS alias) |
| https://portainer.home | 192.168.1.100:9000 | Docker management |
| http://192.168.1.100:3000 | adguardhome:3000 | DNS + ad blocking admin |
| http://192.168.1.100:81 | NPM admin | Reverse proxy management |

### ⚠️ Security constraint

**Never add Finance Hub, Portainer, AdGuard, or Uptime Kuma as proxy hosts under project-aegis.io.**
Guests can reach port 443 on Aegis (by ACL design), so any hostname in NPM is reachable by guests.
Admin/sensitive services must stay on `*.home` only.

---

## SSL Certificates

| Cert | Covers | Location | Expires |
|---|---|---|---|
| mkcert wildcard | `*.home` | `D:\Josh\Dev\certs\homelab.crt` + NPM | Aug 2028 |
| tyche.local | `tyche.local` | `/opt/finance-hub/nginx/certs/` + NPM | Aug 2028 |
| LE wildcard | `*.project-aegis.io`, `project-aegis.io` | NPM (auto-renews) | ~Sep 2026 |

mkcert CA root (install on new devices to trust *.home): `C:\Users\reyna\AppData\Local\mkcert\rootCA.pem`

---

## Finance Hub

- **Project folder:** `D:\Josh\Projects\Family Finance Hub\`
- **Live at:** https://finance.home / https://tyche.local
- **Stack:** FastAPI (Python) backend + React/Vite frontend + SQLite
- **Deployed at:** `/opt/finance-hub/` on Aegis
- **Docker compose:** `docker compose -f /opt/finance-hub/docker-compose.yml <command>`
- **CI/CD:** GitHub Actions self-hosted runner (`github-runner` container — currently crash-looping)
- **Finance Hub CLAUDE.md:** `D:\Josh\Projects\Family Finance Hub\CLAUDE.md` — read this for Finance Hub sessions

### Finance Hub nginx quirk

The frontend nginx redirects port 80 → HTTPS on `$host`. This causes a redirect loop if NPM
forwards to port 80. NPM must forward to **port 443 with Verify SSL disabled**. The frontend's
SSL cert is a mkcert cert for tyche.local — not trusted by NPM's cert store, so verify must be off.

---

## Docker Networks

All networks are external/named (created by `scripts/create-networks.sh`):

| Network | Containers |
|---|---|
| `proxy-net` | nginx-proxy-manager, homer |
| `finance-hub_finance-net` | finance-hub-backend, finance-hub-frontend, NPM |
| `media-net` | jellyfin, NPM |
| `mgmt-net` | uptime-kuma, homarr, NPM |
| `adguard-net` | adguardhome |
| `bridge` | portainer (legacy) |

NPM is on every network by design — it's the only container that crosses network boundaries.
This is intentional. Jellyfin and Finance Hub have no network path to each other.

---

## Known Issues / Gotchas

| Issue | Detail |
|---|---|
| `github-runner` crash-looping | Deferred fix — unrelated to infra phases |
| AdGuard DNS not auto-pushed to home devices | BGW320 DHCP DNS locked by AT&T — Phase 3 fix (managed switch + Aegis DHCP) |
| `--accept-dns=false` is mandatory | Tailscale without this flag breaks AdGuard for all containers |
| NPM owns port 443 | Nothing else can bind to host port 443. Finance Hub frontend uses `expose:` not `ports:` |
| Portainer on bridge network | Not on mgmt-net — NPM routes to it via 192.168.1.100:9000 not container name |
| SSH heredoc with quotes | Fails over SSH — base64-encode file content, pipe to `base64 -d` on Aegis |
| sudo over SSH | Requires interactive TTY — write scripts to /tmp, have Josh run them in his own SSH session |
| Homer image pinned | `b4bz/homer:v24.05.1` — Watchtower excluded. Update manually after checking changelog |

---

## Repo Structure

```
aegis-infra/
├── CONTEXT.md                     ← you are here
├── README.md                      ← architecture overview
├── .env.example                   ← all required vars documented
├── .gitignore
├── docs/
│   ├── progress.md                ← phase-by-phase build log (update after each session)
│   ├── network-map.md             ← service map, ports, URLs (update when services change)
│   ├── build-plan.md              ← full build plan (Phases 1–4)
│   ├── tailscale-acl.hujson       ← canonical ACL policy
│   └── dns-records.md             ← Cloudflare + AdGuard DNS config
└── services/
    ├── nginx-proxy-manager/
    ├── homer/                     ← config.yml + docker-compose.yml
    ├── jellyfin/
    ├── homarr/
    ├── uptime-kuma/
    ├── portainer/
    ├── adguard/
    ├── watchtower/
    └── github-runner/
```

---

## Pending (Before Inviting Guests)

1. MFA on Tailscale account ⚠️ high priority
2. MFA on Cloudflare account ⚠️ high priority
3. Verify BGW320 IP Passthrough is OFF
4. Save Cloudflare API token to password manager
5. Install Tailscale on wife's devices
6. End-to-end cellular test: WiFi off → https://project-aegis.io over Tailscale
