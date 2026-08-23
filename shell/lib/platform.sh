# platform.sh — OS detection (single evaluation, no forks after first call)

[ -n "${DOTFILES_PLATFORM_LOADED:-}" ] && return 0
DOTFILES_PLATFORM_LOADED=1

# OSTYPE is set by Bash/Zsh; fall back to uname for edge cases.
if [ -z "${OSTYPE:-}" ]; then
    case "$(uname -s 2>/dev/null)" in
        Darwin) OSTYPE=darwin ;;
        Linux)  OSTYPE=linux-gnu ;;
        *)      OSTYPE=unknown ;;
    esac
fi

# Cache results as simple flags (0/1) to avoid repeated pattern matching.
case "$OSTYPE" in
    darwin*|Darwin*) DOTFILES_IS_MACOS=1; DOTFILES_IS_LINUX=0 ;;
    linux*|Linux*)   DOTFILES_IS_MACOS=0; DOTFILES_IS_LINUX=1 ;;
    *)               DOTFILES_IS_MACOS=0; DOTFILES_IS_LINUX=0 ;;
esac

is_macos() { [ "${DOTFILES_IS_MACOS:-0}" -eq 1 ]; }
is_linux() { [ "${DOTFILES_IS_LINUX:-0}" -eq 1 ]; }

# Run a command in the background without shell job-control noise
# (no "[N] pid" start line, no "done" completion line).
# Usage: dotfiles_bg_quiet command [args...]
# For compound commands, wrap in a subshell: dotfiles_bg_quiet sh -c '...'
dotfiles_bg_quiet() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        # zsh: &! backgrounds and disowns immediately (no job table entry)
        # shellcheck disable=SC1035,SC1072,SC1073
        "$@" &!
    elif [ -n "${BASH_VERSION:-}" ]; then
        "$@" &
        disown "$!" 2>/dev/null || true
    else
        "$@" &
    fi
}
