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
```

### Configure firewall rules

For providers with external firewalls, configure the following inbound rules. DNS and NTP rules are required only when using `STATIC_NTP=1` for non-stateful UDP firewalls.

| Name      | Proto | Src IPs                            | Src Port | Dst IPs | Dst Port |
| --------- | ----- | ---------------------------------- | -------- | ------- | -------- |
| DNS       | UDP   | 1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4 | 53       | \*      | \*       |
| NTP       | UDP   | 162.159.200.1, 162.159.200.123     | 123      | \*      | \*       |
| HTTP      | TCP   | \*                                 | \*       | \*      | 80       |
| HTTPS     | TCP   | \*                                 | \*       | \*      | 443      |
| QUIC      | UDP   | \*                                 | \*       | \*      | 443      |
| Tailscale | UDP   | \*                                 | \*       | \*      | 41641    |
