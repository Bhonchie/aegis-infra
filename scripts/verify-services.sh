#!/bin/bash
# Verify all services are reachable from Aegis
set -e

check() {
  local name=$1
  local url=$2
  local code
  code=$(curl -sk -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "FAIL")
  printf "%-35s %s\n" "$name" "$code"
}

echo "=== Internal service health ==="
check "Homer (guest portal)"       "http://homer:8080"
check "Jellyfin"                   "http://localhost:8096"
check "Homarr"                     "http://localhost:7575"
check "Portainer"                  "http://localhost:9000"
check "AdGuard"                    "http://localhost:3000"
check "Uptime Kuma"                "http://localhost:3001"
check "NPM Admin"                  "http://localhost:81"

echo ""
echo "=== Tailscale-gated URLs (run from a Tailscale device) ==="
echo "  https://project-aegis.io"
echo "  https://jellyfin.project-aegis.io"
echo "  https://homarr.project-aegis.io"
