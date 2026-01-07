#!/bin/bash

# Enable strict error handling
set -Eeuxo pipefail

# Require root privileges
[[ $EUID -eq 0 ]]

# Set system time zone
timedatectl set-timezone UTC

# Update package index and upgrade installed packages
apt update && apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y

# Install required packages
apt install -y \
  ethtool \
  networkd-dispatcher \
  systemd-resolved \
  qemu-guest-agent

# Enable network services
systemctl unmask systemd-resolved && systemctl enable --now systemd-networkd $_

# Configure global DNS resolvers
install -Dm644 /dev/stdin /etc/systemd/resolved.conf.d/99-global-dns.conf <<EOF
[Resolve]
DNS=
DNS=1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
Domains=
Domains=~.
EOF

# Apply DNS changes
systemctl restart systemd-resolved

# Use systemd-resolved for DNS resolution
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Enable IP forwarding
install -Dm644 /dev/stdin /etc/sysctl.d/99-ip-forwarding.conf <<EOF && sysctl -p $_
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF

# Optimize UDP forwarding
install -Dm755 /dev/stdin /etc/networkd-dispatcher/routable.d/99-udp-gro-forwarding <<EOF && $_
#!/bin/sh

ethtool -K $(ip route show 0/0 | cut -f5 -d' ') rx-udp-gro-forwarding on rx-gro-list off
EOF

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Configure Docker to use Tailscale MTU
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

# Configure Tailscale to start after Docker
install -Dm644 /dev/stdin /etc/systemd/system/tailscaled.service.d/override.conf <<EOF
[Unit]
After=docker.service
Wants=docker.service
EOF

# Apply service overrides
systemctl daemon-reload

# Start Tailscale
tailscale up --ssh "$@"

# Remove orphaned packages and cache
apt autoremove --purge && apt clean

# Create ops user
adduser --gecos -- ops && usermod -aG sudo,docker $_

# Disable root password
passwd -dl $USER

# Remove residual files
find $HOME -mindepth 1 ! -name .bashrc ! -name .profile -exec rm -rf {} +

# Harden OpenSSH server
install -Dm600 /dev/stdin /etc/ssh/sshd_config <<EOF
AllowUsers ops
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
PrintMotd no
EOF

# Disable OpenSSH server in favor of Tailscale SSH
systemctl disable --now ssh && systemctl mask $_
