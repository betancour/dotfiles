#!/bin/sh
# scripts/install.sh — compatibility entry point
# Delegates to the repository-root installer.
exec "$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)/install.sh" "$@"
