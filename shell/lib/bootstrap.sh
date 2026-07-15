# bootstrap.sh — shared bootstrap for Bash and Zsh
# Sourced by every shell entry point. Resolves paths once; keeps startup cheap.

# Resolve this file's directory (shell/lib/) and parents.
# Layout: ~/.dotfiles/shell/{lib,zsh,bash,sh}/  — real repo at ~/.dotfiles
if [ -n "${ZSH_VERSION:-}" ]; then
    # %x = path of the file currently being sourced
    DOTFILES_LIB_DIR="${${(%):-%x}:A:h}"
elif [ -n "${BASH_VERSION:-}" ]; then
    DOTFILES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    DOTFILES_LIB_DIR="${DOTFILES_LIB_DIR:-$HOME/.dotfiles/shell/lib}"
fi

DOTFILES_SHELL_DIR="$(cd "${DOTFILES_LIB_DIR}/.." && pwd)"
# shell/ is a top-level directory of the repository
DOTFILES_DIR="$(cd "${DOTFILES_SHELL_DIR}/.." && pwd)"


if [ -n "${ZSH_VERSION:-}" ]; then
    DOTFILES_SHELL=zsh
elif [ -n "${BASH_VERSION:-}" ]; then
    DOTFILES_SHELL=bash
else
    DOTFILES_SHELL=sh
fi

# Source a module exactly once per shell process (marker is never exported).
dotfiles_source_once() {
    _df_mod="$1"
    # Build a safe marker name from the path
    _df_mark="DOTFILES_SOURCED_${_df_mod}"
    _df_mark="${_df_mark//\//_}"
    _df_mark="${_df_mark//./_}"
    _df_mark="${_df_mark//-/_}"

    if [ -n "${ZSH_VERSION:-}" ]; then
        # shellcheck disable=SC2296
        if [ -n "${(P)_df_mark}" ]; then
            unset _df_mod _df_mark
            return 0
        fi
    else
        if eval "[ -n \"\${${_df_mark}:-}\" ]"; then
            unset _df_mod _df_mark
            return 0
        fi
    fi

    if [ ! -f "$_df_mod" ]; then
        unset _df_mod _df_mark
        return 1
    fi

    if [ -n "${ZSH_VERSION:-}" ]; then
        typeset -g "${_df_mark}=1"
    else
        eval "${_df_mark}=1"
    fi

    # shellcheck source=/dev/null
    . "$_df_mod"
    unset _df_mod _df_mark
}
