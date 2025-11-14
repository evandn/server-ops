#!/bin/bash

# Enable strict error handling
set -Eeuo pipefail

# Require root privileges
[[ $EUID -eq 0 ]]

# Configure timezone
timedatectl set-timezone UTC

# Prevent DHCP from overwriting DNS settings
install -Dm755 /dev/stdin /etc/dhcp/dhclient-enter-hooks.d/nodns <<EOF
make_resolv_conf() { :; }
EOF

# Update system packages
apt update && apt full-upgrade

# Install packages
apt install curl ufw ssh-import-id qemu-guest-agent

# Enable IP forwarding
install -Dm644 /dev/stdin /etc/sysctl.d/99-tailscale.conf <<EOF && sysctl -p $_
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

# Install and configure Tailscale
curl -fsSL https://tailscale.com/install.sh | sh && tailscale up

# Configure Docker
install -Dm644 /dev/stdin /etc/docker/daemon.json <<EOF
{
  "default-network-opts": {
    "overlay": {
      "com.docker.network.driver.mtu": "$(cat /sys/class/net/tailscale0/mtu)"
    }
  }
}
EOF

# Install Docker
curl -fsSL https://get.docker.com | sh

# Remove unused packages and cache
apt autoremove --purge && apt clean

# Set up new user
adduser --gecos -- runner && usermod -aG sudo,docker $_ && runuser -u $_ -- ssh-import-id-gh evandn

# Disable root password
passwd -dl $USER

# Remove residual files
find $HOME -mindepth 1 ! -name .bashrc ! -name .profile -exec rm -rf {} +

# Configure SSH server
install -Dm600 /dev/stdin /etc/ssh/sshd_config <<EOF && sshd -t && systemctl restart ssh
AllowUsers runner
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
PrintMotd no
EOF

# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow in on tailscale0
ufw allow http
ufw allow https
ufw allow 41641/udp
ufw enable
