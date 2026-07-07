# login.zsh — post-interactive login setup

[[ -o login ]] || return

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .zlogin started" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
}

dotfiles_source_once "${DOTFILES_LIB_DIR}/login-common.sh"

if [[ -t 1 && "$SHLVL" -eq 1 ]]; then
    dotfiles_show_system_info
fi

if [[ -t 1 && -o interactive ]]; then
    dotfiles_show_dev_status
fi

if [[ "$SHLVL" -eq 1 && -t 1 ]]; then
    dotfiles_check_updates
fi

dotfiles_setup_ssh_agent

# Light background cleanup
(
    [[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] && \
        find "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" -name '*.tmp' -mtime +7 -delete 2>/dev/null
    [[ -d "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" ]] && \
        ls -t "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"/history.bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
) &

[[ -r "${ZDOTDIR:-$HOME}/.zlogin.local" ]] && source "${ZDOTDIR:-$HOME}/.zlogin.local"

export ZSH_SESSION_ID="$$_$(date +%s)"
export ZSH_LOGIN_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

if [[ -t 1 && "$SHLVL" -eq 1 && $((RANDOM % 10)) -eq 0 ]]; then
    dotfiles_show_random_tip
fi

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .zlogin completed" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
}