#!/bin/bash

# Enable strict error handling
set -Eeuxo pipefail

# Require root privileges
[[ $EUID -eq 0 ]]

# Get Tailscale IPv4
ip=$(tailscale ip -4)

# Install and set up Dokploy behind Tailscale
curl -fsSL https://dokploy.com/install.sh | sed \
  -e '/--publish/d' \
  -e '/docker.sock:ro/a\        -v /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro \\' |
  ADVERTISE_ADDR=$ip bash

# Get Tailscale FQDN
url=$(tailscale whois $ip | grep -o '[^ ]*\.ts\.net')

# Bind Dokploy dashboard to Tailscale FQDN
sed -i "s/\`.*\`/\`$url\`/" /etc/dokploy/traefik/dynamic/dokploy.yml

# Add Tailscale certificate resolver to Traefik
sed -i '/certificatesResolvers:/a\  tailscale:\n    tailscale: {}' /etc/dokploy/traefik/traefik.yml
