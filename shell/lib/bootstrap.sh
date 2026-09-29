# bootstrap.sh — shared bootstrap for Bash and Zsh
# Sourced by every shell entry point. Resolves paths once; keeps startup cheap.

# Resolve this file's directory (shell/lib/) and parents.
# Layout: ~/.dotfiles/shell/{lib,zsh,bash,sh}/  — real repo at ~/.dotfiles
if [ -n "${ZSH_VERSION:-}" ]; then
    # %x = path of the file currently being sourced; :A:h / :h are builtins (no cd/pwd)
    DOTFILES_LIB_DIR="${${(%):-%x}:A:h}"
    DOTFILES_SHELL_DIR="${DOTFILES_LIB_DIR:h}"
    DOTFILES_DIR="${DOTFILES_SHELL_DIR:h}"
elif [ -n "${BASH_VERSION:-}" ]; then
    # Normalize `..` and a relative BASH_SOURCE without forking pwd.
    # macOS /bin/bash is 3.2 and has no realpath.
    _df_normpath() {
        _df_in=$1
        case $_df_in in
            /*) ;;
            *) _df_in=$PWD/$_df_in ;;
        esac
        _df_out=
        _df_ifs=$IFS
        _df_noglob=0
        case $- in
            *f*) ;;
            *) set -f; _df_noglob=1 ;;
        esac
        IFS=/
        # shellcheck disable=SC2086
        set -- $_df_in
        IFS=$_df_ifs
        [ "$_df_noglob" -eq 1 ] && set +f
        for _df_part in "$@"; do
            case $_df_part in
                ''|.) ;;
                ..) _df_out=${_df_out%/*} ;;
                *) _df_out=${_df_out}/${_df_part} ;;
            esac
        done
        _df_norm_result=${_df_out:-/}
        unset _df_in _df_out _df_ifs _df_noglob _df_part
    }
    _df_normpath "${BASH_SOURCE[0]%/*}"
    DOTFILES_LIB_DIR=$_df_norm_result
    _df_normpath "${DOTFILES_LIB_DIR}/.."
    DOTFILES_SHELL_DIR=$_df_norm_result
    _df_normpath "${DOTFILES_SHELL_DIR}/.."
    DOTFILES_DIR=$_df_norm_result
    unset -f _df_normpath
    unset _df_norm_result
else
    DOTFILES_LIB_DIR="${DOTFILES_LIB_DIR:-$HOME/.dotfiles/shell/lib}"
    DOTFILES_SHELL_DIR="$(cd "${DOTFILES_LIB_DIR}/.." && pwd)"
    DOTFILES_DIR="$(cd "${DOTFILES_SHELL_DIR}/.." && pwd)"
fi


if [ -n "${ZSH_VERSION:-}" ]; then
    DOTFILES_SHELL=zsh
elif [ -n "${BASH_VERSION:-}" ]; then
    DOTFILES_SHELL=bash
else
    DOTFILES_SHELL=sh
fi

# Source a module exactly once per shell process (marker is never exported).
dotfiles_source_once() {
    _df_mod=$1
    _df_mark=DOTFILES_SOURCED_${_df_mod}
    # Identifiers only. Turn extended_glob off for this substitution, then
    # restore it before sourcing. `emulate -L` must not wrap the source:
    # option changes inside the module would die with this function.
    _df_ext=0
    if [ -n "${ZSH_VERSION:-}" ]; then
        [[ -o extendedglob ]] && _df_ext=1
        setopt no_extendedglob
    fi
    _df_mark=${_df_mark//[^A-Za-z0-9_]/_}
    if [ "$_df_ext" -eq 1 ]; then
        setopt extendedglob
    fi
    unset _df_ext

    if [ -n "${ZSH_VERSION:-}" ]; then
        # shellcheck disable=SC2296
        if [ -n "${(P)_df_mark}" ]; then
            unset _df_mod _df_mark
            return 0
        fi
    elif [ -n "${!_df_mark:-}" ]; then
        unset _df_mod _df_mark
        return 0
    fi

    if [ ! -f "$_df_mod" ]; then
        unset _df_mod _df_mark
        return 1
    fi

    if [ -n "${ZSH_VERSION:-}" ]; then
        typeset -g "${_df_mark}=1"
    else
        printf -v "$_df_mark" '%s' 1
    fi

    # shellcheck source=/dev/null
    . "$_df_mod"
    unset _df_mod _df_mark
}
