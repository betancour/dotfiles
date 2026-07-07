# profile.zsh — login profile setup (sourced from .zprofile)

[[ -o login && -o interactive ]] || return

source "${DOTFILES_LIB_DIR}/platform.sh"

if is_macos; then
    for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_path" && "$PATH" != *"${brew_path%/bin}"* ]]; then
            eval "$("$brew_path" shellenv)"
            break
        fi
    done
fi

if [[ -z "${SSH_AUTH_SOCK:-}" && -d "$HOME/.ssh" ]]; then
    if ls "$HOME/.ssh"/id_* "$HOME/.ssh"/*_rsa >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add -q "$HOME/.ssh"/id_* "$HOME/.ssh"/*_rsa 2>/dev/null || true
        if [[ -n "${SSH_AGENT_PID:-}" ]]; then
            {
                echo "export SSH_AUTH_SOCK='$SSH_AUTH_SOCK'"
                echo "export SSH_AGENT_PID='$SSH_AGENT_PID'"
            } > "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env"
        fi
    fi
fi

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
        Apple_Terminal) [[ -r /etc/zshrc_Apple_Terminal ]] && source /etc/zshrc_Apple_Terminal ;;
        iTerm.app)      export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES ;;
    esac
elif is_linux; then
    command -v systemctl >/dev/null 2>&1 && systemctl --user import-environment PATH EDITOR LANG 2>/dev/null || true
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v dbus-launch >/dev/null 2>&1; then
        eval "$(dbus-launch --sh-syntax --exit-with-session)" 2>/dev/null || true
    fi
fi

if is_macos && [[ -d /Applications/Docker.app ]]; then
    docker_comp="/Applications/Docker.app/Contents/Resources/etc"
    [[ -r "$docker_comp/docker.zsh-completion" ]] && fpath+=("$docker_comp")
fi

command -v kubectl >/dev/null 2>&1 && export __KUBECTL_AVAILABLE=1

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && {
    log="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
    echo "$(date): .zprofile loaded" >> "$log"
}

[[ -r "${ZDOTDIR:-$HOME}/.zprofile.local" ]] && source "${ZDOTDIR:-$HOME}/.zprofile.local"

export PATH