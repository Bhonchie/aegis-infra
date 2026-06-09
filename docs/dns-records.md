# DNS Records

## Cloudflare — project-aegis.io

| Name | Type | Value | Proxy |
|---|---|---|---|
| `@` | A | `100.97.183.96` | DNS only (gray cloud) |
| `*` | A | `100.97.183.96` | DNS only (gray cloud) |

Both records point to Aegis's Tailscale IP. The domain resolves publicly but the IP is
only reachable from the Tailscale tailnet — this is the VPN gate.

## AdGuard Home — Internal DNS Rewrites

| Pattern | Target | Purpose |
|---|---|---|
| `*.home` | `192.168.1.100` | All .home subdomains → Aegis LAN IP |
| `tyche.local` | `192.168.1.100` | Finance Hub local alias |

## NPM Proxy Hosts

### project-aegis.io (Tailscale-gated, Let's Encrypt cert)

| Domain | Backend | Access |
|---|---|---|
| `project-aegis.io` | `homer:8080` | Owners + guests |
| `jellyfin.project-aegis.io` | `jellyfin:8096` | Owners + guests |
| `homarr.project-aegis.io` | `homarr:7575` | Owners (app auth) |

### *.home (LAN + Tailscale owners, mkcert cert ID=2)

| Domain | Backend |
|---|---|
| `finance.home`, `tyche.home`, `tyche.local` | `finance-hub-frontend:443` |
| `jellyfin.home` | `jellyfin:8096` |
| `portainer.home` | `portainer:9000` |
| `uptime.home` | `uptime-kuma:3001` |
| `homarr.home` | `homarr:7575` |
| `adguard.home` | `adguardhome:3000` |
