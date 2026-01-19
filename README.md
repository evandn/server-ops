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

# Bootstrap for Netcup servers (external firewall required)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap-netcup.sh)"

# Reboot to apply changes
reboot
```

### Netcup Firewall

Configure the following inbound rules in the SCP firewall panel:

| Name      | Proto | Src IPs                            | Src Port | Dst IPs | Dst Port |
| --------- | ----- | ---------------------------------- | -------- | ------- | -------- |
| DNS       | UDP   | 1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4 | 53       | \*      | \*       |
| NTP       | UDP   | 162.159.200.1, 162.159.200.123     | 123      | \*      | \*       |
| HTTP      | TCP   | \*                                 | \*       | \*      | 80       |
| HTTPS     | TCP   | \*                                 | \*       | \*      | 443      |
| QUIC      | UDP   | \*                                 | \*       | \*      | 443      |
| Tailscale | UDP   | \*                                 | \*       | \*      | 41641    |
