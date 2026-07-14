# logout.sh — shared login-shell exit cleanup
# Sourced by .bash_logout / .zlogout.

[ -n "${DOTFILES_LOGOUT_LOADED:-}" ] && return 0
DOTFILES_LOGOUT_LOADED=1

. "${DOTFILES_LIB_DIR}/history.sh"
. "${DOTFILES_LIB_DIR}/ssh-agent.sh"
. "${DOTFILES_LIB_DIR}/platform.sh"

_session_start="${DOTFILES_LOGIN_TIME:-unknown}"
_session_end=$(date '+%Y-%m-%d %H:%M:%S')
_session_duration=unknown

if [ "$_session_start" != unknown ]; then
    # Portable date parsing: GNU date -d, BSD date -j
    _start_epoch=$(date -d "$_session_start" +%s 2>/dev/null \
        || date -j -f "%Y-%m-%d %H:%M:%S" "$_session_start" +%s 2>/dev/null \
        || true)
    _end_epoch=$(date +%s)
    if [ -n "${_start_epoch:-}" ] && [ -n "${_end_epoch:-}" ]; then
        _secs=$((_end_epoch - _start_epoch))
        _h=$((_secs / 3600))
        _m=$(((_secs % 3600) / 60))
        _s=$((_secs % 60))
        if [ "$_h" -gt 0 ]; then
            _session_duration="${_h}h ${_m}m ${_s}s"
        elif [ "$_m" -gt 0 ]; then
            _session_duration="${_m}m ${_s}s"
        else
            _session_duration="${_s}s"
        fi
    fi
    unset _start_epoch _end_epoch _secs _h _m _s
fi

# Clear secrets and tear down SSH agent before exit.
dotfiles_clear_secret_env
dotfiles_ssh_agent_teardown

# History backup (shell-specific directory under XDG_STATE_HOME)
if [ -f "${HISTFILE:-}" ] && [ -s "$HISTFILE" ]; then
    _hist_dir="${XDG_STATE_HOME:-$HOME/.local/state}/${DOTFILES_SHELL:-shell}"
    mkdir -p "$_hist_dir"
    chmod 700 "$_hist_dir" 2>/dev/null || true
    _backup="$_hist_dir/history.bak.$(date +%Y%m%d_%H%M%S)"
    if cp "$HISTFILE" "$_backup" 2>/dev/null; then
        dotfiles_secure_history_backup "$_backup"
    fi
    # Keep last 5 backups
    ls -t "$_hist_dir"/history.bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
    unset _hist_dir _backup
fi

# Background cleanup of ephemeral session files
(
    [ -n "${DOTFILES_SESSION_ID:-}" ] && \
        find /tmp -name "*${DOTFILES_SESSION_ID}*" -user "${USER:-$(id -un)}" -delete 2>/dev/null
) &

# Farewell (interactive terminals only)
if [ -t 1 ]; then
    # Ensure format helpers exist (login.sh is side-effect free when only sourced)
    if ! typeset -f dotfiles_separator_line >/dev/null 2>&1 \
        && ! declare -f dotfiles_separator_line >/dev/null 2>&1; then
        # shellcheck source=/dev/null
        . "${DOTFILES_LIB_DIR}/login.sh"
    fi

    _WIDTH=$(dotfiles_login_width)
    if [ "${TERM:-}" != dumb ]; then
        BOLD=$(printf '\033[1m')
        CYAN=$(printf '\033[36m')
        GREEN=$(printf '\033[32m')
        YELLOW=$(printf '\033[33m')
        RESET=$(printf '\033[0m')
    else
        BOLD= CYAN= GREEN= YELLOW= RESET=
    fi

    echo
    dotfiles_separator_line "=" "$_WIDTH"
    dotfiles_center_text "Goodbye, ${USER:-user}!" "${BOLD}${CYAN}" "$_WIDTH"
    dotfiles_separator_line "-" "$_WIDTH"
    dotfiles_center_text "Session ended: $_session_end" "$GREEN" "$_WIDTH"
    dotfiles_center_text "Session duration: $_session_duration" "$YELLOW" "$_WIDTH"
    dotfiles_separator_line "=" "$_WIDTH"
    echo

    unset _WIDTH BOLD CYAN GREEN YELLOW RESET
fi

unset _session_start _session_end _session_duration
