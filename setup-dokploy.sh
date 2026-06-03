#!/bin/bash

# Enable strict error handling
set -Eeuo pipefail

# Require root privileges
[[ $EUID -eq 0 ]]

# Get Tailscale IPv4
ip=$(tailscale ip -4)

# Install Dokploy without exposing ports
curl -fsSL https://dokploy.com/install.sh | sed '/--publish/d; s/^ *-p /&127.0.0.1:/' | ADVERTISE_ADDR=$ip DOCKER_SWARM_INIT_ARGS="--listen-addr $ip" bash

# Get Tailscale FQDN
url=$(tailscale whois $ip | grep -o '[^ ]*\.ts\.net')

# Bind Dokploy dashboard to Tailscale FQDN
sed -i "s/\`.*\`/\`$url\`/; s/web\$/&secure/" /etc/dokploy/traefik/dynamic/dokploy.yml

# Serve Dokploy dashboard over Tailscale
tailscale serve --bg https+insecure://127.0.0.1:443
