# history.zsh — Zsh history privacy hook

source "${DOTFILES_LIB_DIR}/history.sh"

# Reject lines matching secret patterns before they enter history.
zshaddhistory() {
    emulate -L zsh
    [[ "$1" =~ "$DOTFILES_HIST_SECRET_PATTERN" ]] && return 1
    return 0
}

dotfiles_secure_history_file "$HISTFILE"
