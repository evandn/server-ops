# server-ops

Shell scripts for bootstrapping and managing servers

## Usage

### Bootstrap a new server

```sh
# Disable command logging for this session
unset HISTFILE

# Bootstrap with default options
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap.sh)"

# Bootstrap without UFW for cloud providers with built-in firewalls
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap-nofw.sh)"

# Optional but recommended
reboot
```
