#!/bin/bash
# Bring Tailscale up with correct flags.
# --accept-dns=false is REQUIRED — without it, Tailscale overwrites /etc/resolv.conf
# and breaks AdGuard Home DNS resolution for all Docker containers.
set -e

sudo tailscale up \
  --advertise-routes=192.168.1.0/24 \
  --accept-dns=false

echo "Tailscale up. Approve subnet route at login.tailscale.com if not already done."
echo "Tailscale IP: $(tailscale ip)"
