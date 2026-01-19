# server-ops

Shell scripts for bootstrapping and managing servers

## Usage

### Bootstrap a new server

```sh
# Disable command logging for this session
unset HISTFILE

# Set non-interactive mode for package installations (optional)
export DEBIAN_FRONTEND=noninteractive

# Bootstrap with default options
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap.sh)"

# Bootstrap without UFW for cloud providers with built-in firewalls
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap-nofw.sh)"

# Bootstrap with fixed NTP IPs for non-stateful UDP firewalls
USE_FIXED_NTP=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap-nofw.sh)"

# Reboot to apply changes
reboot
```

### Configure firewall rules

For providers with external firewalls, configure the following inbound rules. DNS and NTP rules are required only when using `USE_FIXED_NTP=1` for non-stateful UDP firewalls.

| Name      | Proto | Src IPs                            | Src Port | Dst IPs | Dst Port |
| --------- | ----- | ---------------------------------- | -------- | ------- | -------- |
| DNS       | UDP   | 1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4 | 53       | \*      | \*       |
| NTP       | UDP   | 162.159.200.1, 162.159.200.123     | 123      | \*      | \*       |
| HTTP      | TCP   | \*                                 | \*       | \*      | 80       |
| HTTPS     | TCP   | \*                                 | \*       | \*      | 443      |
| QUIC      | UDP   | \*                                 | \*       | \*      | 443      |
| Tailscale | UDP   | \*                                 | \*       | \*      | 41641    |
