#!/bin/bash

# Enable strict error handling
set -Eeuxo pipefail

# Require root privileges
[[ $EUID -eq 0 ]]

# Set system time zone
timedatectl set-timezone UTC

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Update package index and upgrade installed packages
apt update && apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y

# Define required packages
packages=(
  ethtool
  networkd-dispatcher
  systemd-resolved
  qemu-guest-agent
  ${UFW:+ufw}
)

# Install required packages
apt install -y "${packages[@]}"

# Enable network services
systemctl unmask systemd-resolved && systemctl enable --now systemd-networkd $_

# Configure global DNS resolvers
install -Dm644 /dev/stdin /etc/systemd/resolved.conf.d/99-global-dns.conf <<EOF && systemctl restart systemd-resolved
[Resolve]
DNS=
DNS=1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
Domains=
Domains=~.
EOF

# Use systemd-resolved for DNS resolution
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Configure static NTP servers for non-stateful UDP firewalls
[[ -n ${STATIC_NTP-} ]] && install -Dm644 /dev/stdin /etc/systemd/timesyncd.conf.d/99-global-ntp.conf <<EOF && systemctl restart systemd-timesyncd
[Time]
NTP=
NTP=162.159.200.1 162.159.200.123
EOF

# Enable IP forwarding
install -Dm644 /dev/stdin /etc/sysctl.d/99-ip-forwarding.conf <<EOF && sysctl -p $_
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF

# Use UFW as local firewall
if [[ -n ${UFW-} ]]; then
  # Configure UFW rules for Docker
  grep -q 'DOCKER-USER' /etc/ufw/after.rules || cat >>$_ <<EOF

*filter
:DOCKER-USER - [0:0]
:ufw-user-forward - [0:0]

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -s 10.0.0.0/8 -j RETURN
-A DOCKER-USER -s 172.16.0.0/12 -j RETURN
-A DOCKER-USER -s 192.168.0.0/16 -j RETURN

-A DOCKER-USER -d 10.0.0.0/8 -m conntrack --ctstate NEW -j DROP
-A DOCKER-USER -d 172.16.0.0/12 -m conntrack --ctstate NEW -j DROP
-A DOCKER-USER -d 192.168.0.0/16 -m conntrack --ctstate NEW -j DROP

COMMIT
EOF

  # Set UFW default policies
  ufw default deny incoming
  ufw default deny routed
  ufw default allow outgoing

  # Allow essential services
  ufw allow http
  ufw allow https
  ufw allow 443/udp

  # Enable UFW
  ufw reload && ufw --force enable
fi

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

# Configure Docker to start after UFW
[[ -n ${UFW-} ]] && install -Dm644 /dev/stdin /etc/systemd/system/docker.service.d/override.conf <<EOF
[Unit]
After=ufw.service
Wants=ufw.service
EOF

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
