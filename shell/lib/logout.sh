# logout.sh — shared login-shell exit cleanup
# Sourced by .bash_logout / .zlogout.
#
# Order: compute duration → clear secrets → tear down agent →
#        history backup → ephemeral cleanup → farewell (TTY only).

[ -n "${DOTFILES_LOGOUT_LOADED:-}" ] && return 0
DOTFILES_LOGOUT_LOADED=1

. "${DOTFILES_LIB_DIR}/history.sh"
. "${DOTFILES_LIB_DIR}/ssh-agent.sh"
. "${DOTFILES_LIB_DIR}/platform.sh"

# --- Session duration (one date for end stamp + epoch) ---
_session_start=${DOTFILES_LOGIN_TIME:-unknown}
_end_raw=$(date '+%Y-%m-%d %H:%M:%S %s')
_session_end=${_end_raw% *}
_end_epoch=${_end_raw##* }
_session_duration=unknown
unset _end_raw

if [ "$_session_start" != unknown ]; then
    # Portable: GNU date -d, BSD date -j -f.
    _start_epoch=$(date -d "$_session_start" +%s 2>/dev/null \
        || date -j -f '%Y-%m-%d %H:%M:%S' "$_session_start" +%s 2>/dev/null \
        || true)
    if [ -n "${_start_epoch:-}" ] && [ -n "${_end_epoch:-}" ]; then
        _secs=$((_end_epoch - _start_epoch))
        if [ "$_secs" -ge 0 ] 2>/dev/null; then
            _h=$((_secs / 3600))
            _m=$(( (_secs % 3600) / 60 ))
            _s=$((_secs % 60))
            if [ "$_h" -gt 0 ]; then
                _session_duration="${_h}h ${_m}m ${_s}s"
            elif [ "$_m" -gt 0 ]; then
                _session_duration="${_m}m ${_s}s"
            else
                _session_duration="${_s}s"
            fi
            unset _h _m _s
        fi
        unset _secs
    fi
    unset _start_epoch
fi
unset _end_epoch

# --- Security: secrets and agent before any further work ---
dotfiles_clear_secret_env
dotfiles_ssh_agent_teardown

# --- History backup (shell-specific dir under XDG_STATE_HOME) ---
if [ -f "${HISTFILE:-}" ] && [ -s "$HISTFILE" ]; then
    _hist_dir="${XDG_STATE_HOME:-$HOME/.local/state}/${DOTFILES_SHELL:-shell}"
    mkdir -p "$_hist_dir"
    chmod 700 "$_hist_dir" 2>/dev/null || true
    _backup="$_hist_dir/history.bak.$(date +%Y%m%d_%H%M%S)"
    if cp "$HISTFILE" "$_backup" 2>/dev/null; then
        dotfiles_secure_history_backup "$_backup"
    fi
    # Keep last 5 backups (ls -t is fine; logout is cold path).
    ls -t "$_hist_dir"/history.bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
    unset _hist_dir _backup
fi

# --- Ephemeral session files (quiet background) ---
if [ -n "${DOTFILES_SESSION_ID:-}" ]; then
    _sid=$DOTFILES_SESSION_ID
    _user=${USER:-$(id -un 2>/dev/null)}
    if typeset -f dotfiles_bg_quiet >/dev/null 2>&1 \
        || declare -f dotfiles_bg_quiet >/dev/null 2>&1; then
        dotfiles_bg_quiet sh -c \
            "find /tmp -name '*${_sid}*' -user '${_user}' -delete 2>/dev/null"
    else
        ( find /tmp -name "*${_sid}*" -user "$_user" -delete 2>/dev/null ) &
        disown "$!" 2>/dev/null || true
    fi
    unset _sid _user
fi

# --- Farewell (interactive terminals only) ---
if [ -t 1 ] && [ "${TERM:-}" != dumb ]; then
    # Formatting helpers live in login.sh (side-effect free when only sourced).
    if ! typeset -f dotfiles_separator_line >/dev/null 2>&1 \
        && ! declare -f dotfiles_separator_line >/dev/null 2>&1; then
        # shellcheck source=/dev/null
        . "${DOTFILES_LIB_DIR}/login.sh"
    fi

    _WIDTH=$(dotfiles_login_width)
    if typeset -f _dotfiles_term_colors >/dev/null 2>&1 \
        || declare -f _dotfiles_term_colors >/dev/null 2>&1; then
        _dotfiles_term_colors
    else
        BOLD=$(printf '\033[1m')
        GREEN=$(printf '\033[32m')
        CYAN=$GREEN
        YELLOW=$GREEN
        RESET=$(printf '\033[0m')
    fi

    echo
    dotfiles_separator_line '=' "$_WIDTH"
    dotfiles_center_text "Goodbye, ${USER:-user}!" "${BOLD}${GREEN}" "$_WIDTH"
    dotfiles_separator_line '-' "$_WIDTH"
    dotfiles_center_text "Session ended: ${_session_end}" "$GREEN" "$_WIDTH"
    dotfiles_center_text "Session duration: ${_session_duration}" "$GREEN" "$_WIDTH"
    dotfiles_separator_line '=' "$_WIDTH"
    echo

    unset _WIDTH BOLD DIM CYAN GREEN BLUE YELLOW MAGENTA RESET
fi

unset _session_start _session_end _session_duration
