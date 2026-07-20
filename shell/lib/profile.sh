# profile.sh — shared login-profile setup (sourced by .bash_profile / .zprofile)
# Shell-specific bits (completion fpath, terminal rc names) stay in thin modules.

[ -n "${DOTFILES_PROFILE_LOADED:-}" ] && return 0
DOTFILES_PROFILE_LOADED=1

. "${DOTFILES_LIB_DIR}/platform.sh"

# --- Package manager / Homebrew ---
if is_macos; then
    for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$_brew" ]; then
            case ":$PATH:" in
                *":${_brew%/bin}/bin:"*) ;;
                *) eval "$("$_brew" shellenv)" ;;
            esac
            break
        fi
    done
    unset _brew
fi

# --- SSH agent (start once per login session) ---
. "${DOTFILES_LIB_DIR}/ssh-agent.sh"
dotfiles_ssh_agent_start

# --- GPG agent ---
if command -v gpgconf >/dev/null 2>&1; then
    if ! pgrep -u "$USER" gpg-agent >/dev/null 2>&1; then
        gpgconf --launch gpg-agent 2>/dev/null || true
    fi
    GPG_TTY=$(tty 2>/dev/null) && export GPG_TTY
fi

# --- Version managers (init only when installed) ---
# JAVA_HOME / BUN_INSTALL / toolchain PATH entries live in environment.sh + path.sh.
if [ -x "${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv" ] || [ -x "$HOME/.pyenv/bin/pyenv" ]; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) PATH="$PYENV_ROOT/bin:$PATH" ;; esac
    eval "$(pyenv init -)"
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
    eval "$(rbenv init - --no-rehash)"
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
if is_macos; then
    if command -v launchctl >/dev/null 2>&1; then
        launchctl setenv PATH "$PATH" 2>/dev/null || true
        launchctl setenv EDITOR "${EDITOR:-}" 2>/dev/null || true
        launchctl setenv LANG "${LANG:-}" 2>/dev/null || true
        [ -n "${JAVA_HOME:-}" ] && launchctl setenv JAVA_HOME "$JAVA_HOME" 2>/dev/null || true
        [ -n "${BUN_INSTALL:-}" ] && launchctl setenv BUN_INSTALL "$BUN_INSTALL" 2>/dev/null || true
        [ -n "${DOTNET_ROOT:-}" ] && launchctl setenv DOTNET_ROOT "$DOTNET_ROOT" 2>/dev/null || true
    fi
elif is_linux; then
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user import-environment PATH EDITOR LANG JAVA_HOME BUN_INSTALL DOTNET_ROOT 2>/dev/null || true
    fi
fi

# --- Feature flags for interactive modules ---
command -v kubectl >/dev/null 2>&1 && export __KUBECTL_AVAILABLE=1

# Session identity for logout/cleanup (shell-agnostic names)
export DOTFILES_SESSION_ID="$$_$(date +%s)"
export DOTFILES_LOGIN_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
export PATH
