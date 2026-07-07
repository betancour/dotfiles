# login.bash — post-interactive login setup (parity with .zlogin)

case "$-" in *l*) ;; *) return ;; esac

[[ -n "${BASH_PROFILE_STARTUP:-}" ]] && {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .bash_login started" >> "${XDG_STATE_HOME:-$HOME/.local/state}/bash/startup.log"
}

dotfiles_source_once "${DOTFILES_LIB_DIR}/login-common.sh"

if [[ -t 1 && "$SHLVL" -eq 1 ]]; then
    dotfiles_show_system_info
fi

if [[ -t 1 ]]; then
    dotfiles_show_dev_status
fi

if [[ "$SHLVL" -eq 1 && -t 1 ]]; then
    dotfiles_check_updates
fi

dotfiles_setup_ssh_agent

[[ -r "$HOME/.bash_login.local" ]] && source "$HOME/.bash_login.local"

if [[ -t 1 && "$SHLVL" -eq 1 && $((RANDOM % 10)) -eq 0 ]]; then
    dotfiles_show_random_tip
fi

[[ -n "${BASH_PROFILE_STARTUP:-}" ]] && {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .bash_login completed" >> "${XDG_STATE_HOME:-$HOME/.local/state}/bash/startup.log"
}