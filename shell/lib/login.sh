# login.sh — shared post-interactive login setup
# Provides formatting helpers (also used by logout) and dotfiles_login().

[ -n "${DOTFILES_LOGIN_LIB_LOADED:-}" ] && return 0
DOTFILES_LOGIN_LIB_LOADED=1

. "${DOTFILES_LIB_DIR}/platform.sh"
. "${DOTFILES_LIB_DIR}/privacy.sh"
. "${DOTFILES_LIB_DIR}/ssh-agent.sh"

# --- Formatting helpers ---

dotfiles_login_width() {
    _w="${COLUMNS:-}"
    if [ -z "$_w" ] && command -v tput >/dev/null 2>&1; then
        _w=$(tput cols 2>/dev/null)
    fi
    _w=${_w:-80}
    [ "$_w" -gt 100 ] && _w=100
    [ "$_w" -lt 60 ] && _w=60
    printf '%s' "$_w"
    unset _w
}

dotfiles_center_text() {
    _text="$1"
    _color="${2:-}"
    _width="$3"
    _plain=$(printf '%s' "$_text" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' 2>/dev/null || printf '%s' "$_text")
    _plen=${#_plain}
    if [ "$_plen" -gt $((_width - 4)) ]; then
        _plain=$(printf '%s' "$_plain" | cut -c1-$((_width - 7)))...
        _plen=${#_plain}
    fi
    _pad=$(( (_width - 2 - _plen) / 2 ))
    _rpad=$(( _width - 2 - _pad - _plen ))
    if [ -n "$_color" ]; then
        printf "|%*s%s%s%s%*s|\n" "$_pad" "" "$_color" "$_plain" "${RESET:-}" "$_rpad" ""
    else
        printf "|%*s%s%*s|\n" "$_pad" "" "$_plain" "$_rpad" ""
    fi
    unset _text _color _width _plain _plen _pad _rpad
}

dotfiles_separator_line() {
    _char="${1:-=}"
    _width="$2"
    printf "+"
    _i=0
    while [ "$_i" -lt $((_width - 2)) ]; do
        printf '%s' "$_char"
        _i=$((_i + 1))
    done
    printf "+\n"
    unset _char _width _i
}

# --- Optional displays (off by default — see privacy.sh) ---

dotfiles_show_system_info() {
    _WIDTH=$(dotfiles_login_width)

    if [ -t 1 ] && [ "${TERM:-}" != dumb ]; then
        BOLD=$(printf '\033[1m')
        CYAN=$(printf '\033[36m')
        GREEN=$(printf '\033[32m')
        BLUE=$(printf '\033[34m')
        YELLOW=$(printf '\033[33m')
        MAGENTA=$(printf '\033[35m')
        RESET=$(printf '\033[0m')
    else
        BOLD= CYAN= GREEN= BLUE= YELLOW= MAGENTA= RESET=
    fi

    _datetime=$(date '+%A, %B %d, %Y – %H:%M:%S')
    _hostname=$(hostname -s 2>/dev/null || hostname)
    _username="${USER:-$(whoami)}"
    _ip=unavailable

    if is_macos; then
        _ip=$(ifconfig en0 2>/dev/null | awk '/inet / {print $2; exit}')
        [ -z "$_ip" ] && _ip=$(ifconfig en1 2>/dev/null | awk '/inet / {print $2; exit}')
    elif is_linux; then
        _ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        [ -z "$_ip" ] && _ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    fi
    [ -z "$_ip" ] && _ip=unavailable

    _uptime=unknown
    if command -v uptime >/dev/null 2>&1; then
        if is_macos; then
            _uptime=$(uptime | sed 's/.*up \([^,]*\).*/\1/' | xargs)
        else
            _uptime=$(uptime -p 2>/dev/null | sed 's/up //' || uptime | sed 's/.*up \([^,]*\).*/\1/' | xargs)
        fi
    fi

    _load=unknown
    if is_macos; then
        _load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' | cut -d',' -f1 | xargs)
    elif is_linux && [ -r /proc/loadavg ]; then
        _load=$(awk '{print $1}' /proc/loadavg)
    fi

    _memory=unknown
    if is_macos && command -v vm_stat >/dev/null 2>&1; then
        _pages_free=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
        _pages_inactive=$(vm_stat | awk '/Pages inactive/ {print $3}' | tr -d '.')
        if [ -n "$_pages_free" ] && [ -n "$_pages_inactive" ]; then
            _memory="$(( (_pages_free + _pages_inactive) * 4096 / 1024 / 1024 ))MB free"
        fi
    elif is_linux && [ -r /proc/meminfo ]; then
        _memory=$(awk '/MemAvailable/ {print int($2/1024)"MB available"}' /proc/meminfo)
    fi

    _disk=unknown
    command -v df >/dev/null 2>&1 && \
        _disk=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $4 " available (" $5 " used)"}')

    echo
    dotfiles_separator_line "=" "$_WIDTH"
    dotfiles_center_text "Welcome back, $_username!" "${BOLD}${CYAN}" "$_WIDTH"
    dotfiles_separator_line "-" "$_WIDTH"
    dotfiles_center_text "$_datetime" "$GREEN" "$_WIDTH"
    dotfiles_center_text "Host: $_hostname | IP: $_ip" "$BLUE" "$_WIDTH"
    dotfiles_center_text "Uptime: $_uptime | Load: $_load" "$YELLOW" "$_WIDTH"
    [ "$_memory" != unknown ] && dotfiles_center_text "Memory: $_memory" "$MAGENTA" "$_WIDTH"
    [ "$_disk" != unknown ] && dotfiles_center_text "Disk: $_disk" "$CYAN" "$_WIDTH"
    dotfiles_separator_line "=" "$_WIDTH"
    echo

    unset _WIDTH _datetime _hostname _username _ip _uptime _load _memory _disk
    unset _pages_free _pages_inactive BOLD CYAN GREEN BLUE YELLOW MAGENTA RESET
}

dotfiles_show_dev_status() {
    if [ -t 1 ] && [ "${TERM:-}" != dumb ]; then
        DIM=$(printf '\033[2m')
        RESET=$(printf '\033[0m')
        GREEN=$(printf '\033[32m')
        CYAN=$(printf '\033[36m')
    else
        DIM= RESET= GREEN= CYAN=
    fi

    _out=
    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        _branch=$(git branch --show-current 2>/dev/null)
        _changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [ -n "$_branch" ]; then
            _out="${_out}  ${GREEN}Git${RESET}: ${CYAN}${_branch}${RESET} - ${_changes} changes
"
        fi
    fi

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        _out="${_out}  ${GREEN}Python${RESET}: ${CYAN}$(basename "$VIRTUAL_ENV")${RESET}
"
    fi

    if command -v node >/dev/null 2>&1; then
        _out="${_out}  ${GREEN}Node${RESET}: ${CYAN}$(node --version 2>/dev/null)${RESET}
"
    fi

    if [ -n "$_out" ]; then
        printf '%s\n' "${DIM}Development Status:${RESET}"
        printf '%s' "$_out"
        echo
    fi
    unset _out _branch _changes DIM RESET GREEN CYAN
}

dotfiles_check_updates() {
    _check_file="${XDG_CACHE_HOME:-$HOME/.cache}/shell_update_check"
    _today=$(date +%Y%m%d)
    _last=
    [ -f "$_check_file" ] && _last=$(cat "$_check_file" 2>/dev/null)
    [ "$_last" = "$_today" ] && unset _check_file _today _last && return 0
    echo "$_today" > "$_check_file"

    if is_macos && command -v brew >/dev/null 2>&1; then
        (
            _n=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
            [ "${_n:-0}" -gt 0 ] && echo "Notice: $_n Homebrew packages can be updated. Run: brew upgrade"
        ) &
    fi
    unset _check_file _today _last
}

dotfiles_show_random_tip() {
    _idx=$(( ($(date +%S) + $$) % 8 ))
    if [ -t 1 ] && [ "${TERM:-}" != dumb ]; then
        DIM=$(printf '\033[2m')
        RESET=$(printf '\033[0m')
    else
        DIM= RESET=
    fi
    case "$_idx" in
        0) printf '%s\n' "${DIM}Tip: Use z for smart directory jumping (zoxide)${RESET}" ;;
        1) printf '%s\n' "${DIM}Tip: Use fzf / Ctrl+T for fuzzy file finding${RESET}" ;;
        2) printf '%s\n' "${DIM}Tip: Use rg for fast text searching${RESET}" ;;
        3) printf '%s\n' "${DIM}Tip: Use bat for syntax-highlighted file viewing${RESET}" ;;
        4) printf '%s\n' "${DIM}Tip: Use gcm for quick git commits${RESET}" ;;
        5) printf '%s\n' "${DIM}Tip: Press Ctrl+R for interactive history search${RESET}" ;;
        6) printf '%s\n' "${DIM}Tip: Use .. and ... for quick directory navigation${RESET}" ;;
        7) printf '%s\n' "${DIM}Tip: Type help to see available custom commands${RESET}" ;;
    esac
    echo
    unset _idx DIM RESET
}

# --- Main entry (called by shell login modules) ---

dotfiles_login() {
    if [ -t 1 ] && [ "${SHLVL:-1}" -eq 1 ] && dotfiles_show_login_info; then
        dotfiles_show_system_info
    fi

    if [ -t 1 ] && dotfiles_show_dev_status_enabled; then
        dotfiles_show_dev_status
    fi

    if [ "${SHLVL:-1}" -eq 1 ] && [ -t 1 ]; then
        dotfiles_check_updates
    fi

    dotfiles_ssh_agent_setup

    if [ -t 1 ] && [ "${SHLVL:-1}" -eq 1 ]; then
        _r=$(( ($(date +%S) + $$) % 10 ))
        [ "$_r" -eq 0 ] && dotfiles_show_random_tip
        unset _r
    fi
}
