# server-ops

Shell scripts for bootstrapping and managing servers

## Usage

### Bootstrap a new server

```sh
# Disable command history for this session
unset HISTFILE

# Bootstrap with default options
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap_server.sh)"

# Bootstrap with custom options
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap_server.sh)" -- --advertise-exit-node
bash -c "$(curl -fsSL https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap_server.sh)" -- --advertise-tags=tag:server
```
