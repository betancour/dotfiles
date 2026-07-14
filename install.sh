#!/bin/sh
# Convenience entry point — delegates to scripts/install.sh
exec "$(CDPATH= cd -- "$(dirname "$0")" && pwd)/scripts/install.sh" "$@"
