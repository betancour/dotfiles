# logout.zsh — login shell exit cleanup

[[ -o login ]] || return

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .zlogout started" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
}

source "${DOTFILES_LIB_DIR}/history.sh"
source "${DOTFILES_LIB_DIR}/ssh-agent.sh"

local session_start_time="${ZSH_LOGIN_TIME:-unknown}"
local session_end_time="$(date '+%Y-%m-%d %H:%M:%S')"
local session_duration="unknown"

if [[ "$session_start_time" != unknown ]]; then
    local start_epoch end_epoch
    start_epoch=$(date -d "$session_start_time" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$session_start_time" +%s 2>/dev/null)
    end_epoch=$(date +%s)
    if [[ -n "$start_epoch" && -n "$end_epoch" ]]; then
        local duration_seconds=$((end_epoch - start_epoch))
        local hours=$((duration_seconds / 3600))
        local minutes=$(((duration_seconds % 3600) / 60))
        local seconds=$((duration_seconds % 60))
        if (( hours > 0 )); then
            session_duration="${hours}h ${minutes}m ${seconds}s"
        elif (( minutes > 0 )); then
            session_duration="${minutes}m ${seconds}s"
        else
            session_duration="${seconds}s"
        fi
    fi
fi

# Clear secrets and tear down SSH agent in the foreground before exit.
dotfiles_clear_secret_env
dotfiles_ssh_agent_teardown

if [[ -f "$HISTFILE" && -s "$HISTFILE" ]]; then
    local hist_backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
    local backup_file
    mkdir -p "$hist_backup_dir"
    chmod 700 "$hist_backup_dir" 2>/dev/null || true
    backup_file="$hist_backup_dir/history.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$HISTFILE" "$backup_file" 2>/dev/null && dotfiles_secure_history_backup "$backup_file"
    ls -t "$hist_backup_dir"/history.bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
fi

# Background cleanup of ephemeral session files.
(
    [[ -n "${ZSH_SESSION_ID:-}" ]] && find /tmp -name "*${ZSH_SESSION_ID}*" -user "$USER" -delete 2>/dev/null
    [[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] && \
        find "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" -name '*.tmp' -mtime +7 -delete 2>/dev/null
) &

if [[ -t 1 && -o interactive ]]; then
    local WIDTH RESET BOLD CYAN GREEN YELLOW BLUE
    WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
    (( WIDTH > 100 )) && WIDTH=100
    (( WIDTH < 60 )) && WIDTH=60
    if [[ "${TERM:-}" != dumb ]]; then
        BOLD=$'\033[1m' CYAN=$'\033[36m' GREEN=$'\033[32m' YELLOW=$'\033[33m' BLUE=$'\033[34m' RESET=$'\033[0m'
    else
        BOLD='' CYAN='' GREEN='' YELLOW='' BLUE='' RESET=''
    fi
    source "${DOTFILES_LIB_DIR}/login-common.sh"
    echo
    _dotfiles_separator_line "=" "$WIDTH"
    _dotfiles_center_text "Goodbye, $USER!" "${BOLD}${CYAN}" "$WIDTH"
    _dotfiles_separator_line "-" "$WIDTH"
    _dotfiles_center_text "Session ended: $session_end_time" "$GREEN" "$WIDTH"
    _dotfiles_center_text "Session duration: $session_duration" "$YELLOW" "$WIDTH"
    [[ -n "${HISTCMD:-}" && "$HISTCMD" -gt 1 ]] && \
        _dotfiles_center_text "Commands executed: $((HISTCMD - 1))" "$BLUE" "$WIDTH"
    _dotfiles_separator_line "=" "$WIDTH"
    echo
fi

[[ -r "${ZDOTDIR:-$HOME}/.zlogout.local" ]] && source "${ZDOTDIR:-$HOME}/.zlogout.local"