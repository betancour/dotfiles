# dotfiles.sh — shared bootstrap for shell configuration modules
# Sourced by both Zsh and Bash entry points.

# Resolve config/shell directory from this file's location.
if [[ -n "${ZSH_VERSION:-}" ]]; then
    DOTFILES_SHELL_DIR="${0:A:h:h}"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    DOTFILES_SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
    DOTFILES_SHELL_DIR="${DOTFILES_SHELL_DIR:-$HOME/dotfiles/config/shell}"
fi

DOTFILES_LIB_DIR="${DOTFILES_SHELL_DIR}/lib"
DOTFILES_DIR="$(cd "${DOTFILES_SHELL_DIR}/../.." && pwd)"

# Source a module exactly once. Uses a marker variable per module basename.
dotfiles_source_once() {
    local module="$1"
    local marker="DOTFILES_SOURCED_${module//\//_}"
    marker="${marker//./_}"
    marker="${marker//-/_}"

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        [[ -n "${(P)marker}" ]] && return 0
    else
        [[ -n "${!marker:-}" ]] && return 0
    fi

    if [[ ! -f "$module" ]]; then
        return 1
    fi

    # Shell-local marker only — never export (functions don't inherit across shells).
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        typeset -g "${marker}=1"
    else
        # shellcheck disable=SC2163
        declare -g "${marker}=1"
    fi
    source "$module"
}