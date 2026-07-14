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

# --- Java ---
if is_macos; then
    if [ -d /opt/homebrew/opt/openjdk ]; then
        export JAVA_HOME=/opt/homebrew/opt/openjdk
    elif [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
        JAVA_HOME=$(/usr/libexec/java_home -v 11+ 2>/dev/null) && export JAVA_HOME
    fi
elif is_linux; then
    for _j in /usr/lib/jvm/default-java /usr/lib/jvm/java-11-openjdk; do
        if [ -d "$_j" ]; then
            export JAVA_HOME="$_j"
            break
        fi
    done
    unset _j
fi

# --- Version managers (init only when installed) ---
if [ -x "$HOME/.pyenv/bin/pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) PATH="$PYENV_ROOT/bin:$PATH" ;; esac
    eval "$(pyenv init -)"
fi

[ -d "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm"

if [ -d "$HOME/.rbenv" ]; then
    case ":$PATH:" in *":$HOME/.rbenv/bin:"*) ;; *) PATH="$HOME/.rbenv/bin:$PATH" ;; esac
    eval "$(rbenv init - --no-rehash)"
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# --- Desktop / session environment export ---
if is_macos; then
    if command -v launchctl >/dev/null 2>&1; then
        launchctl setenv PATH "$PATH" 2>/dev/null || true
        launchctl setenv EDITOR "${EDITOR:-}" 2>/dev/null || true
        launchctl setenv LANG "${LANG:-}" 2>/dev/null || true
    fi
elif is_linux; then
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user import-environment PATH EDITOR LANG 2>/dev/null || true
    fi
fi

# --- Feature flags for interactive modules ---
command -v kubectl >/dev/null 2>&1 && export __KUBECTL_AVAILABLE=1

# Session identity for logout/cleanup (shell-agnostic names)
export DOTFILES_SESSION_ID="$$_$(date +%s)"
export DOTFILES_LOGIN_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
export PATH
