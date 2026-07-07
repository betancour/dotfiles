# ssh-agent.sh — secure SSH agent setup and teardown

[[ -n "${DOTFILES_SSH_AGENT_LOADED:-}" ]] && return 0
DOTFILES_SSH_AGENT_LOADED=1

source "${DOTFILES_LIB_DIR}/platform.sh"

DOTFILES_SSH_AGENT_ENV="${DOTFILES_SSH_AGENT_ENV:-${XDG_STATE_HOME:-$HOME/.local/state}/shell/ssh-agent.env}"
DOTFILES_SSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shell"
DOTFILES_SSH_KEY_NAMES="id_ed25519 id_ecdsa id_rsa"

_dotfiles_ssh_state_init() {
    [[ -d "$DOTFILES_SSH_STATE_DIR" ]] || mkdir -p "$DOTFILES_SSH_STATE_DIR"
    chmod 700 "$DOTFILES_SSH_STATE_DIR" 2>/dev/null || true
}

_dotfiles_ssh_has_keys() {
    [[ -d "$HOME/.ssh" ]] || return 1
    local name
    for name in $DOTFILES_SSH_KEY_NAMES; do
        [[ -f "$HOME/.ssh/$name" ]] && return 0
    done
    return 1
}

_dotfiles_ssh_add_key() {
    local keypath="$1"
    if [[ -n "${DOTFILES_SSH_ADD_CONFIRM:-}" ]]; then
        ssh-add -c -q "$keypath" 2>/dev/null || true
    elif is_macos && ssh-add -h 2>&1 | grep -q 'apple-use-keychain'; then
        ssh-add --apple-use-keychain -q "$keypath" 2>/dev/null || true
    else
        ssh-add -q "$keypath" 2>/dev/null || true
    fi
}

dotfiles_ssh_agent_write_env() {
    _dotfiles_ssh_state_init
    local saved_umask
    saved_umask=$(umask)
    umask 077
    {
        printf "export SSH_AUTH_SOCK='%s'\n" "$SSH_AUTH_SOCK"
        printf "export SSH_AGENT_PID='%s'\n" "$SSH_AGENT_PID"
    } > "$DOTFILES_SSH_AGENT_ENV"
    chmod 600 "$DOTFILES_SSH_AGENT_ENV" 2>/dev/null || true
    umask "$saved_umask"
}

dotfiles_ssh_agent_start() {
    [[ -n "${SSH_AUTH_SOCK:-}" ]] && return 0
    _dotfiles_ssh_has_keys || return 0

    _dotfiles_ssh_state_init
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || return 1

    local name
    for name in $DOTFILES_SSH_KEY_NAMES; do
        [[ -f "$HOME/.ssh/$name" ]] && _dotfiles_ssh_add_key "$HOME/.ssh/$name"
    done

    [[ -n "${SSH_AGENT_PID:-}" ]] && dotfiles_ssh_agent_write_env
}

dotfiles_ssh_agent_restore() {
    [[ -n "${SSH_AUTH_SOCK:-}" ]] && return 0
    [[ -f "$DOTFILES_SSH_AGENT_ENV" ]] || return 0

    # shellcheck source=/dev/null
    source "$DOTFILES_SSH_AGENT_ENV" 2>/dev/null || return 1
    ssh-add -l >/dev/null 2>&1 || {
        unset SSH_AUTH_SOCK SSH_AGENT_PID
        rm -f "$DOTFILES_SSH_AGENT_ENV" 2>/dev/null
        return 1
    }
}

dotfiles_ssh_agent_setup() {
    dotfiles_ssh_agent_restore || dotfiles_ssh_agent_start
}

dotfiles_ssh_agent_teardown() {
    [[ "${SHLVL:-1}" -gt 1 ]] && return 0

    if [[ -n "${SSH_AGENT_PID:-}" ]] && kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        ssh-agent -k >/dev/null 2>&1 || kill "$SSH_AGENT_PID" 2>/dev/null || true
    fi

    unset SSH_AUTH_SOCK SSH_AGENT_PID
    rm -f "$DOTFILES_SSH_AGENT_ENV" 2>/dev/null || true
}