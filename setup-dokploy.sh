#!/bin/bash

# Enable strict error handling
set -Eeuxo pipefail

# Require root privileges
[[ $EUID -eq 0 ]]

# Get Tailscale IPv4
ip=$(tailscale ip -4)

# Install Dokploy without exposing ports
curl -fsSL https://dokploy.com/install.sh | sed '/--publish\|-p 443/d; s/80:80/127.0.0.1:&/' | ADVERTISE_ADDR=$ip DOCKER_SWARM_INIT_ARGS="--listen-addr $ip" bash

# Serve Dokploy dashboard over Tailscale
tailscale serve --bg 80
