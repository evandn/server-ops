#!/bin/bash

# Enable strict error handling
set -Eeuxo pipefail

# Require root privileges
[[ $EUID -eq 0 ]]

# Get Tailscale IPv4
ip=$(tailscale ip -4)

# Install Dokploy without exposing ports
curl -fsSL https://dokploy.com/install.sh | sed '/--publish/d' | ADVERTISE_ADDR=$ip bash

# Get Tailscale FQDN
url=$(tailscale whois $ip | grep -o '[^ ]*ts\.net')

# Configure Traefik with Tailscale FQDN
until test -f /etc/dokploy/traefik/dynamic/dokploy.yml && sed -i "s/\`.*\`/\`$url\`/" $_; do sleep 5; done
