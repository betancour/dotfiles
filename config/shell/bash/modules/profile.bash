# profile.bash — login profile setup

case "$-" in *l*) ;; *) return ;; esac

source "${DOTFILES_LIB_DIR}/platform.sh"

if is_macos; then
    for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_path" && "$PATH" != *"${brew_path%/bin}"* ]]; then
            eval "$("$brew_path" shellenv)"
            break
        fi
    done
fi

source "${DOTFILES_LIB_DIR}/ssh-agent.sh"
dotfiles_ssh_agent_start

if command -v gpgconf >/dev/null 2>&1; then
    pgrep -u "$USER" gpg-agent >/dev/null || gpgconf --launch gpg-agent 2>/dev/null || true
    export GPG_TTY="$(tty)"
fi

if is_macos; then
    [[ -d /opt/homebrew/opt/openjdk ]] && export JAVA_HOME="/opt/homebrew/opt/openjdk"
    [[ -z "${JAVA_HOME:-}" ]] && JAVA_HOME="$(/usr/libexec/java_home -v 11+ 2>/dev/null)" && export JAVA_HOME
elif is_linux; then
    for j in /usr/lib/jvm/default-java /usr/lib/jvm/java-11-openjdk; do
        [[ -d "$j" ]] && export JAVA_HOME="$j" && break
    done
fi

if [[ -x "$HOME/.pyenv/bin/pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

[[ -d "$HOME/.nvm" ]] && export NVM_DIR="$HOME/.nvm"

if [[ -d "$HOME/.rbenv" ]]; then
    PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init - --no-rehash)"
fi

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

if command -v go >/dev/null 2>&1; then
    export GOROOT="$(go env GOROOT)"
fi

if is_macos; then
    command -v launchctl >/dev/null 2>&1 && {
        launchctl setenv PATH "$PATH" 2>/dev/null || true
        launchctl setenv EDITOR "$EDITOR" 2>/dev/null || true
        launchctl setenv LANG "$LANG" 2>/dev/null || true
    }
    case "${TERM_PROGRAM:-}" in
        Apple_Terminal) [[ -r "/etc/bashrc_${TERM_PROGRAM}" ]] && source "/etc/bashrc_${TERM_PROGRAM}" ;;
        iTerm.app)      export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES ;;
    esac
elif is_linux; then
    command -v systemctl >/dev/null 2>&1 && systemctl --user import-environment PATH EDITOR LANG 2>/dev/null || true
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v dbus-launch >/dev/null 2>&1; then
        eval "$(dbus-launch --sh-syntax --exit-with-session)" 2>/dev/null || true
    fi
fi

if is_macos && [[ -d /Applications/Docker.app ]]; then
    export _DOCKER_AVAILABLE=1
fi

command -v kubectl >/dev/null 2>&1 && export __KUBECTL_AVAILABLE=1

[[ -n "${BASH_PROFILE_STARTUP:-}" ]] && {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .bash_profile started" >> "${XDG_STATE_HOME:-$HOME/.local/state}/bash/startup.log"
}

[[ -r "$HOME/.bash_profile.local" ]] && source "$HOME/.bash_profile.local"

export PATH
export BASH_SESSION_ID="$$_$(date +%s)"
export BASH_LOGIN_TIME="$(date '+%Y-%m-%d %H:%M:%S')"