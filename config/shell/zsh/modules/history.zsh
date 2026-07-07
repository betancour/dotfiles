# history.zsh — Zsh history privacy hooks

source "${DOTFILES_LIB_DIR}/history.sh"

# Reject lines matching secret patterns before they enter history.
zshaddhistory() {
    emulate -L zsh
    [[ "$1" =~ '(password|PASSWORD|TOKEN|SECRET|API_KEY|api_key|credential|Bearer |AWS_|OPENAI_|GITHUB_TOKEN|DATABASE_PASSWORD|mysql -p|postgres://|redis://)' ]] && return 1
    return 0
}

dotfiles_secure_history_file "$HISTFILE"