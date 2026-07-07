# privacy.sh — privacy defaults and helpers

[[ -n "${DOTFILES_PRIVACY_LOADED:-}" ]] && return 0
DOTFILES_PRIVACY_LOADED=1

# Login banner with hostname/IP/system stats (off by default).
# Set DOTFILES_SHOW_LOGIN_INFO=1 to enable.
: "${DOTFILES_SHOW_LOGIN_INFO:=0}"

# Git/Docker/Node status on login (off by default).
# Set DOTFILES_SHOW_DEV_STATUS=1 to enable.
: "${DOTFILES_SHOW_DEV_STATUS:=0}"

# Require confirmation per SSH key use (useful on shared machines).
# Set DOTFILES_SSH_ADD_CONFIRM=1 to enable ssh-add -c.
: "${DOTFILES_SSH_ADD_CONFIRM:=0}"

dotfiles_show_login_info() {
    [[ "${DOTFILES_SHOW_LOGIN_INFO:-0}" == 1 ]]
}

dotfiles_show_dev_status_enabled() {
    [[ "${DOTFILES_SHOW_DEV_STATUS:-0}" == 1 ]]
}