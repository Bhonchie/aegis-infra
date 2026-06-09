#!/bin/bash
# Create all Docker networks if they don't exist
set -e

networks=(proxy-net media-net mgmt-net adguard-net)

for net in "${networks[@]}"; do
  if docker network inspect "$net" &>/dev/null; then
    echo "  $net already exists"
  else
    docker network create "$net"
    echo "  $net created"
  fi
done

echo "All networks ready."
