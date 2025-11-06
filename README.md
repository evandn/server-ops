# server-ops

Shell scripts for bootstrapping and managing servers

## Usage

```sh
unset HISTFILE

URL='https://raw.githubusercontent.com/evandn/server-ops/HEAD/bootstrap.sh'

bash -c "$(command -v curl &>/dev/null && curl -fsSL $URL || wget -qO- $URL)"
```
