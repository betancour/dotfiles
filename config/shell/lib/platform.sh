# platform.sh — OS detection helpers (POSIX-compatible)

is_macos() { [[ "${OSTYPE:-}" == darwin* ]]; }
is_linux() { [[ "${OSTYPE:-}" == linux-gnu* ]]; }