# profile.sh — shared login-profile setup (sourced by .bash_profile / .zprofile)
# Shell-specific bits (completion fpath, terminal rc names) stay in thin modules.

[ -n "${DOTFILES_PROFILE_LOADED:-}" ] && return 0
DOTFILES_PROFILE_LOADED=1

. "${DOTFILES_LIB_DIR}/platform.sh"

# --- Package manager / Homebrew (no brew(1) fork) ---
dotfiles_brew_env || true

# macOS path_helper runs after .zshenv and rearranges PATH. Rebuild so
# managed directories stay in front and are not duplicated. Cheap: no forks.
unset DOTFILES_PATH_LOADED
# shellcheck source=path.sh
. "${DOTFILES_LIB_DIR}/path.sh"

# --- SSH agent (reuse a live agent; start one only if needed) ---
. "${DOTFILES_LIB_DIR}/ssh-agent.sh"
dotfiles_ssh_agent_setup

# gpg launches its own agent. Only the tty has to be ready for pinentry.
dotfiles_gpg_tty

# --- Version managers (shims already on PATH from path.sh; init is lazy) ---
# JAVA_HOME / BUN_INSTALL / toolchain PATH entries live in environment.sh + path.sh.
if [ -x "${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv" ] || [ -x "$HOME/.pyenv/bin/pyenv" ]; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) PATH="$PYENV_ROOT/bin:$PATH" ;; esac
    pyenv() {
        unset -f pyenv
        eval "$(command pyenv init -)"
        pyenv "$@"
    }
fi

# NVM: directory only here; lazy function lives in tools.sh
if [ -z "${NVM_DIR:-}" ] || [ ! -d "${NVM_DIR}" ]; then
    if [ -d "$HOME/.nvm" ]; then
        export NVM_DIR="$HOME/.nvm"
    elif [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/nvm" ]; then
        export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    fi
fi

# fnm (fast Node manager) — env inject when installed
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell "${DOTFILES_SHELL:-bash}" 2>/dev/null)" || true
elif [ -x "${FNM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/fnm}/fnm" ]; then
    case ":$PATH:" in
        *":${FNM_DIR:-${XDG_DATA_HOME}/fnm}:"*) ;;
        *) PATH="${FNM_DIR:-${XDG_DATA_HOME}/fnm}:$PATH" ;;
    esac
    eval "$(fnm env --shell "${DOTFILES_SHELL:-bash}" 2>/dev/null)" || true
fi

if [ -d "$HOME/.rbenv" ]; then
    case ":$PATH:" in *":$HOME/.rbenv/bin:"*) ;; *) PATH="$HOME/.rbenv/bin:$PATH" ;; esac
    rbenv() {
        unset -f rbenv
        eval "$(command rbenv init - --no-rehash)"
        rbenv "$@"
    }
fi

# Rustup/cargo env (prefer XDG CARGO_HOME, fall back to ~/.cargo)
if [ -f "${CARGO_HOME:-}/env" ]; then
    # shellcheck source=/dev/null
    . "${CARGO_HOME}/env"
elif [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
fi

# SDKMAN (lazy: only set dir; source candidate on demand via tools if needed)
if [ -z "${SDKMAN_DIR:-}" ] && [ -d "$HOME/.sdkman" ]; then
    export SDKMAN_DIR="$HOME/.sdkman"
fi

# --- Desktop / session environment export ---
# GUI apps inherit PATH/EDITOR/LANG. Each launchctl setenv is a fork, so
# skip the trio when this exact triple was already published.
if is_macos; then
    if command -v launchctl >/dev/null 2>&1; then
        _df_launch_dir="${XDG_STATE_HOME:-$HOME/.local/state}/shell"
        _df_launch_stamp="${_df_launch_dir}/launchctl.stamp"
        _df_sig="PATH=${PATH}
EDITOR=${EDITOR-}
LANG=${LANG-}"
        _df_cur=
        [ -r "$_df_launch_stamp" ] && _df_cur=$(< "$_df_launch_stamp")
        if [ "$_df_cur" != "$_df_sig" ]; then
            [ -d "$_df_launch_dir" ] || mkdir -p "$_df_launch_dir"
            launchctl setenv PATH "$PATH" 2>/dev/null || true
            launchctl setenv EDITOR "${EDITOR:-}" 2>/dev/null || true
            launchctl setenv LANG "${LANG:-}" 2>/dev/null || true
            _df_umask=$(umask)
            umask 077
            printf '%s' "$_df_sig" > "$_df_launch_stamp" 2>/dev/null || true
            umask "$_df_umask"
            unset _df_umask
        fi
        unset _df_launch_dir _df_launch_stamp _df_sig _df_cur
    fi
elif is_linux; then
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user import-environment PATH EDITOR LANG 2>/dev/null || true
    fi
fi

# Session identity for logout/cleanup. login.sh's ensure is a no-op once set.
if dotfiles_now; then
    export DOTFILES_LOGIN_TIME=$_df_now_clock
    export DOTFILES_LOGIN_EPOCH=$_df_now_epoch
    export DOTFILES_SESSION_ID=$$_$_df_now_epoch
fi
unset _df_now_clock _df_now_epoch
export PATH
