# logout.bash — login shell exit cleanup

case "$-" in *l*) ;; *) return ;; esac

[[ -n "${BASH_PROFILE_STARTUP:-}" ]] && {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .bash_logout started" >> "${XDG_STATE_HOME:-$HOME/.local/state}/bash/startup.log"
}

session_start_time="${BASH_LOGIN_TIME:-unknown}"
session_end_time="$(date '+%Y-%m-%d %H:%M:%S')"
session_duration="unknown"

if [[ "$session_start_time" != unknown ]]; then
    source "${DOTFILES_LIB_DIR}/platform.sh"
    if is_macos; then
        start_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$session_start_time" +%s 2>/dev/null)
    else
        start_epoch=$(date -d "$session_start_time" +%s 2>/dev/null)
    fi
    end_epoch=$(date +%s)
    if [[ -n "$start_epoch" && -n "$end_epoch" ]]; then
        duration_seconds=$((end_epoch - start_epoch))
        hours=$((duration_seconds / 3600))
        minutes=$(((duration_seconds % 3600) / 60))
        seconds=$((duration_seconds % 60))
        if (( hours > 0 )); then
            session_duration="${hours}h ${minutes}m ${seconds}s"
        elif (( minutes > 0 )); then
            session_duration="${minutes}m ${seconds}s"
        else
            session_duration="${seconds}s"
        fi
    fi
fi

(
    [[ -f "$HISTFILE" && -s "$HISTFILE" ]] && {
        local hist_backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/bash"
        mkdir -p "$hist_backup_dir"
        cp "$HISTFILE" "$hist_backup_dir/history.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null
        ls -t "$hist_backup_dir"/history.bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
    }
    [[ -n "${BASH_SESSION_ID:-}" ]] && find /tmp -name "*${BASH_SESSION_ID}*" -user "$USER" -delete 2>/dev/null
    unset AWS_SECRET_ACCESS_KEY GITHUB_TOKEN OPENAI_API_KEY DATABASE_PASSWORD 2>/dev/null
) &

if [[ -t 1 ]]; then
    source "${DOTFILES_LIB_DIR}/login-common.sh"
    WIDTH=$(_dotfiles_login_width)
    if [[ "${TERM:-}" != dumb ]]; then
        BOLD=$'\033[1m' CYAN=$'\033[36m' GREEN=$'\033[32m' YELLOW=$'\033[33m' BLUE=$'\033[34m' RESET=$'\033[0m'
    else
        BOLD='' CYAN='' GREEN='' YELLOW='' BLUE='' RESET=''
    fi
    echo
    _dotfiles_separator_line "=" "$WIDTH"
    _dotfiles_center_text "Goodbye, $USER!" "${BOLD}${CYAN}" "$WIDTH"
    _dotfiles_separator_line "-" "$WIDTH"
    _dotfiles_center_text "Session ended: $session_end_time" "$GREEN" "$WIDTH"
    _dotfiles_center_text "Session duration: $session_duration" "$YELLOW" "$WIDTH"
    _dotfiles_separator_line "=" "$WIDTH"
    echo
fi

[[ -r "$HOME/.bash_logout.local" ]] && source "$HOME/.bash_logout.local"