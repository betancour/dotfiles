# privacy.sh — privacy defaults and feature flags

[ -n "${DOTFILES_PRIVACY_LOADED:-}" ] && return 0
DOTFILES_PRIVACY_LOADED=1

# Login banner with hostname/IP/system stats (off by default — keep startup fast).
# Enable with: export DOTFILES_SHOW_LOGIN_INFO=1
: "${DOTFILES_SHOW_LOGIN_INFO:=0}"

# Git/Docker/Node status on login (off by default — avoids docker info fork).
# Enable with: export DOTFILES_SHOW_DEV_STATUS=1
: "${DOTFILES_SHOW_DEV_STATUS:=0}"

# Require confirmation per SSH key use (useful on shared machines).
# Enable with: export DOTFILES_SSH_ADD_CONFIRM=1
: "${DOTFILES_SSH_ADD_CONFIRM:=0}"

# Load the full Oh My Zsh framework (slow: second compinit, upgrade check).
# Default 0: standalone autosuggestions + syntax-highlighting only.
# Enable from ~/.zshenv.local or ~/.zprofile.local (must be set before .zshrc):
#   export DOTFILES_USE_OMZ=1
: "${DOTFILES_USE_OMZ:=0}"

dotfiles_show_login_info() {
    [ "${DOTFILES_SHOW_LOGIN_INFO:-0}" = 1 ]
}

dotfiles_show_dev_status_enabled() {
    [ "${DOTFILES_SHOW_DEV_STATUS:-0}" = 1 ]
}
