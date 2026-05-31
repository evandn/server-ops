# server-ops

Shell scripts for bootstrapping and managing servers

## Usage

### Bootstrap a new server

```sh
# Disable command logging for this session
unset HISTFILE

# Bootstrap with UFW for providers without external firewalls
UFW=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap.sh)"

# Bootstrap without UFW for providers with external firewalls
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap.sh)"

# Bootstrap with static NTP for providers with stateless UDP firewalls
STATIC_NTP=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap.sh)"

# Reboot to apply changes
reboot

# Set up Dokploy
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/setup-dokploy.sh)"
```

### Configure firewall rules

For providers with external firewalls, deny all inbound and add only the rules below. Apps are served through an outbound Cloudflare Tunnel, while Dokploy dashboard and SSH run over Tailscale, so no HTTP or HTTPS port is ever exposed. Follow [the Cloudflare Tunnel guide](https://docs.dokploy.com/docs/core/guides/cloudflare-tunnels) to set up the tunnel. DNS and NTP rules apply only with `STATIC_NTP=1` for stateless UDP firewalls.

| Name      | Proto | Src IPs                            | Src Port | Dst IPs | Dst Port |
| --------- | ----- | ---------------------------------- | -------- | ------- | -------- |
| DNS       | UDP   | 1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4 | 53       | \*      | \*       |
| NTP       | UDP   | 162.159.200.1, 162.159.200.123     | 123      | \*      | \*       |
| Tailscale | UDP   | \*                                 | \*       | \*      | 41641    |
