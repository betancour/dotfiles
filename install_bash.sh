#!/usr/bin/env bash
# Legacy entry point — delegates to unified installer
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/install.sh" bash "$@"