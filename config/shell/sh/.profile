# .profile — POSIX sh login configuration
# Portable subset of the shared dotfiles environment.
# Avoid Bash/Zsh-only features. Safe to source from dash, ash, busybox sh.

# Guard against double-sourcing.
if [ -n "${DOTFILES_SH_PROFILE_LOADED:-}" ]; then
    # shellcheck disable=SC2317 # return fails when file is executed, not sourced
    return 0 2>/dev/null || true
fi
DOTFILES_SH_PROFILE_LOADED=1

# Resolve repository root from this file when symlinked, else ~/.dotfiles.
if [ -n "${DOTFILES_DIR:-}" ] && [ -d "$DOTFILES_DIR" ]; then
    :
elif [ -n "${DOTFILES_ROOT:-}" ] && [ -d "$DOTFILES_ROOT" ]; then
    DOTFILES_DIR=$DOTFILES_ROOT
else
    # $0 is unreliable when sourced; prefer canonical home.
    if [ -d "$HOME/.dotfiles/config/shell/sh" ]; then
        DOTFILES_DIR="$HOME/.dotfiles"
    elif [ -d "$HOME/Development/dotfiles/config/shell/sh" ]; then
        DOTFILES_DIR="$HOME/Development/dotfiles"
    else
        DOTFILES_DIR="$HOME/.dotfiles"
    fi
fi

export DOTFILES_DIR
DOTFILES_SHELL="sh"
export DOTFILES_SHELL

DOTFILES_SH_DIR="${DOTFILES_DIR}/config/shell/sh"
DOTFILES_LIB_DIR="${DOTFILES_DIR}/config/shell/lib"

# XDG base dirs (minimal)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Ensure standard user bin dirs are on PATH (idempotent).
_df_path_prepend() {
    _df_p=$1
    [ -d "$_df_p" ] || { unset _df_p; return 0; }
    case ":$PATH:" in
        *":$_df_p:"*) ;;
        *) PATH="$_df_p${PATH:+:$PATH}" ;;
    esac
    unset _df_p
}

_df_path_prepend "$HOME/.local/bin"
_df_path_prepend "$HOME/bin"

# Homebrew (macOS)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

export PATH

# Editor / pager
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL=nvim
elif command -v vim >/dev/null 2>&1; then
    export EDITOR=vim
    export VISUAL=vim
else
    export EDITOR=vi
    export VISUAL=vi
fi
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"

# Load shared modules that are POSIX-safe when present.
# shellcheck source=/dev/null
[ -r "${DOTFILES_LIB_DIR}/platform.sh" ] && . "${DOTFILES_LIB_DIR}/platform.sh"

# Local POSIX tools module (aliases with fallbacks).
# shellcheck source=/dev/null
[ -r "${DOTFILES_SH_DIR}/modules/tools.sh" ] && . "${DOTFILES_SH_DIR}/modules/tools.sh"

# Machine-local overrides
# shellcheck source=/dev/null
[ -r "$HOME/.profile.local" ] && . "$HOME/.profile.local"

# If the login shell is actually bash/zsh, prefer their richer configs
# when those files exist (do not force; only hint via BASH_ENV/ZDOTDIR elsewhere).
