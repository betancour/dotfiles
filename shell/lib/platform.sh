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

# Homebrew environment without `brew shellenv` (that fork is ~25ms and
# prepends bin/sbin even when they are already on PATH).
# PATH itself is assembled in path.sh so ordering stays in one place.
dotfiles_brew_env() {
    _brew=
    for _brew in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew \
        "${HOME}/.linuxbrew/bin/brew" \
        /home/linuxbrew/.linuxbrew/bin/brew
    do
        [ -x "$_brew" ] || continue
        _prefix=${_brew%/*}
        _prefix=${_prefix%/*}
        export HOMEBREW_PREFIX="$_prefix"
        export HOMEBREW_CELLAR="${_prefix}/Cellar"
        export HOMEBREW_REPOSITORY="$_prefix"
        case ":${INFOPATH:-}:" in
            *":${_prefix}/share/info:"*) ;;
            *)
                INFOPATH="${_prefix}/share/info${INFOPATH:+:$INFOPATH}"
                export INFOPATH
                ;;
        esac
        # Current brew shellenv does not add a man path. If MANPATH is already
        # set, keep a leading colon so man(1) still searches the system pages.
        if [ -n "${MANPATH-}" ]; then
            MANPATH=${MANPATH%"${MANPATH##*[!:]}"}
            MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"
            export MANPATH
        fi
        unset _brew _prefix
        return 0
    done
    unset _brew _prefix
    return 1
}

# Wall clock + epoch without date(1) on Bash 5+ and Zsh.
# Sets _df_now_clock (YYYY-MM-DD HH:MM:SS) and _df_now_epoch.
dotfiles_now() {
    _df_now_clock=
    _df_now_epoch=
    if [ -n "${ZSH_VERSION:-}" ]; then
        zmodload zsh/datetime 2>/dev/null || true
        if [ -n "${EPOCHSECONDS:-}" ]; then
            _df_now_epoch=$EPOCHSECONDS
            # Prompt expansion is quoted so Bash can parse this file.
            eval '_df_now_clock=${(%):-%D{%Y-%m-%d %H:%M:%S}}'
            [ -n "$_df_now_clock" ] && return 0
        fi
    elif [ -n "${BASH_VERSION:-}" ]; then
        if printf -v _df_now_clock '%(%Y-%m-%d %H:%M:%S)T' -1 2>/dev/null; then
            _df_now_epoch=${EPOCHSECONDS:-}
            [ -n "$_df_now_epoch" ] && return 0
        fi
    fi
    _df_raw=$(date '+%Y-%m-%d %H:%M:%S %s') || return 1
    _df_now_clock=${_df_raw% *}
    _df_now_epoch=${_df_raw##* }
    unset _df_raw
}

# Pinentry needs a tty. gpg starts its agent on first use; do not fork gpgconf here.
dotfiles_gpg_tty() {
    [ -t 0 ] || [ -t 1 ] || return 0
    if [ -n "${ZSH_VERSION:-}" ] && [ -n "${TTY:-}" ]; then
        export GPG_TTY=$TTY
    else
        export GPG_TTY=${GPG_TTY:-/dev/tty}
    fi
}

# Run a command in the background without shell job-control noise
# (no "[N] pid" start line, no "done" completion line).
# Usage: dotfiles_bg_quiet command [args...]
# For compound commands, wrap in a subshell: dotfiles_bg_quiet sh -c '...'
# The job lives in a subshell. `&!` is Zsh-only and a parse error in Bash 3.2
# and dash, and this file is sourced by all three.
dotfiles_bg_quiet() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        ( setopt NO_MONITOR NO_NOTIFY; "$@" & )
    else
        ( "$@" & )
    fi
}
