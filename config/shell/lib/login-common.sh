# login-common.sh — shared login shell routines (POSIX-compatible)

# Guard against double-source within a shell. If the marker was inherited from a
# parent environment (exported by an older config), functions won't exist — reload.
if [[ -n "${DOTFILES_LOGIN_COMMON_LOADED:-}" ]]; then
    if typeset -f dotfiles_show_system_info >/dev/null 2>&1 \
        || declare -f dotfiles_show_system_info >/dev/null 2>&1; then
        return 0
    fi
    unset DOTFILES_LOGIN_COMMON_LOADED
fi
DOTFILES_LOGIN_COMMON_LOADED=1

source "${DOTFILES_LIB_DIR}/platform.sh"

# Terminal width for formatting
_dotfiles_login_width() {
    local w="${COLUMNS:-}"
    if [[ -z "$w" ]] && command -v tput >/dev/null 2>&1; then
        w=$(tput cols 2>/dev/null)
    fi
    w=${w:-80}
    (( w > 100 )) && w=100
    (( w < 60 )) && w=60
    echo "$w"
}

_dotfiles_center_text() {
    local text="$1" color="${2:-}" width="$3"
    local plain plain_length padding
    plain=$(printf '%s' "$text" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    plain_length=${#plain}
    if (( plain_length > width - 4 )); then
        plain="${plain:0:$((width - 7))}..."
        plain_length=${#plain}
    fi
    local padding=$(( (width - 2 - plain_length) / 2 ))
    if [[ -n "$color" ]]; then
        printf "|%*s%s%s%s%*s|\n" "$padding" "" "$color" "$plain" "$RESET" "$((width - 2 - padding - plain_length))" ""
    else
        printf "|%*s%s%*s|\n" "$padding" "" "$plain" "$((width - 2 - padding - plain_length))" ""
    fi
}

_dotfiles_separator_line() {
    local char="${1:-─}" width="$2" i
    printf "+"
    for ((i = 0; i < width - 2; i++)); do printf "%s" "$char"; done
    printf "+\n"
}

dotfiles_show_system_info() {
    local WIDTH RESET BOLD CYAN GREEN BLUE YELLOW MAGENTA
    WIDTH=$(_dotfiles_login_width)

    if [[ -t 1 ]] && [[ "${TERM:-}" != dumb ]]; then
        BOLD=$'\033[1m' CYAN=$'\033[36m' GREEN=$'\033[32m'
        BLUE=$'\033[34m' YELLOW=$'\033[33m' MAGENTA=$'\033[35m' RESET=$'\033[0m'
    else
        BOLD='' CYAN='' GREEN='' BLUE='' YELLOW='' MAGENTA='' RESET=''
    fi

    local datetime hostname username ip uptime_info load memory disk_usage
    datetime=$(date '+%A, %B %d, %Y – %H:%M:%S')
    hostname=$(hostname -s 2>/dev/null || hostname)
    username="${USER:-$(whoami)}"
    ip="unavailable"

    if is_macos; then
        ip=$(ifconfig en0 2>/dev/null | awk '/inet / {print $2; exit}')
        [[ -z "$ip" ]] && ip=$(ifconfig en1 2>/dev/null | awk '/inet / {print $2; exit}')
    elif is_linux; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        [[ -z "$ip" ]] && ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    fi
    [[ -z "$ip" ]] && ip="unavailable"

    uptime_info="unknown"
    if command -v uptime >/dev/null 2>&1; then
        if is_macos; then
            uptime_info=$(uptime | sed 's/.*up \([^,]*\).*/\1/' | xargs)
        else
            uptime_info=$(uptime -p 2>/dev/null | sed 's/up //' || uptime | sed 's/.*up \([^,]*\).*/\1/' | xargs)
        fi
    fi

    load="unknown"
    if is_macos; then
        load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' | cut -d',' -f1 | xargs)
    elif is_linux; then
        load=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo unknown)
    fi

    memory="unknown"
    if is_macos && command -v vm_stat >/dev/null 2>&1; then
        local pages_free pages_inactive free_mb
        pages_free=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
        pages_inactive=$(vm_stat | awk '/Pages inactive/ {print $3}' | tr -d '.')
        if [[ -n "$pages_free" && -n "$pages_inactive" ]]; then
            free_mb=$(( (pages_free + pages_inactive) * 4096 / 1024 / 1024 ))
            memory="${free_mb}MB free"
        fi
    elif is_linux && [[ -r /proc/meminfo ]]; then
        memory=$(awk '/MemAvailable/ {print int($2/1024)"MB available"}' /proc/meminfo 2>/dev/null)
    fi

    disk_usage="unknown"
    command -v df >/dev/null 2>&1 && disk_usage=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $4 " available (" $5 " used)"}')

    echo
    _dotfiles_separator_line "=" "$WIDTH"
    _dotfiles_center_text "Welcome back, $username!" "${BOLD}${CYAN}" "$WIDTH"
    _dotfiles_separator_line "-" "$WIDTH"
    _dotfiles_center_text "$datetime" "$GREEN" "$WIDTH"
    _dotfiles_center_text "Host: $hostname | IP: $ip" "$BLUE" "$WIDTH"
    _dotfiles_center_text "Uptime: $uptime_info | Load: $load" "$YELLOW" "$WIDTH"
    [[ "$memory" != unknown ]] && _dotfiles_center_text "Memory: $memory" "$MAGENTA" "$WIDTH"
    [[ "$disk_usage" != unknown ]] && _dotfiles_center_text "Disk: $disk_usage" "$CYAN" "$WIDTH"
    _dotfiles_separator_line "=" "$WIDTH"
    echo
}

dotfiles_show_dev_status() {
    local DIM RESET GREEN CYAN YELLOW output=""
    if [[ -t 1 ]] && [[ "${TERM:-}" != dumb ]]; then
        DIM=$'\033[2m' RESET=$'\033[0m' GREEN=$'\033[32m' CYAN=$'\033[36m' YELLOW=$'\033[33m'
    else
        DIM='' RESET='' GREEN='' CYAN='' YELLOW=''
    fi

    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        local git_branch git_status git_line
        git_branch=$(git branch --show-current 2>/dev/null)
        git_status=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [[ -n "$git_branch" ]]; then
            git_line="  ${GREEN}Git${RESET}: ${CYAN}${git_branch}${RESET} - ${git_status} changes"
            output="${output}${git_line}"$'\n'
        fi
    fi

    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        output="${output}  ${GREEN}Python${RESET}: ${CYAN}$(basename "$VIRTUAL_ENV")${RESET} - venv"$'\n'
    elif [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
        output="${output}  ${GREEN}Python${RESET}: ${CYAN}${CONDA_DEFAULT_ENV}${RESET} - conda"$'\n'
    fi

    if command -v node >/dev/null 2>&1; then
        output="${output}  ${GREEN}Node${RESET}: ${CYAN}$(node --version 2>/dev/null)${RESET}"$'\n'
    fi

    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            local containers docker_line
            containers=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
            docker_line="  ${GREEN}Docker${RESET}: ${CYAN}running${RESET} - ${containers} containers"
            output="${output}${docker_line}"$'\n'
        else
            output="${output}  ${YELLOW}Docker${RESET}: ${DIM}not running${RESET}"$'\n'
        fi
    fi

    if [[ -n "$output" ]]; then
        echo "${DIM}Development Status:${RESET}"
        printf '%s' "$output"
        echo
    fi
}

dotfiles_check_updates() {
    local update_check_file="${XDG_CACHE_HOME:-$HOME/.cache}/shell_update_check"
    local current_day last_check
    current_day=$(date +%Y%m%d)
    last_check=""
    [[ -f "$update_check_file" ]] && last_check=$(cat "$update_check_file" 2>/dev/null)
    [[ "$last_check" == "$current_day" ]] && return 0

    echo "$current_day" > "$update_check_file"

    if is_macos && command -v brew >/dev/null 2>&1; then
        (
            local outdated
            outdated=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
            (( outdated > 0 )) && echo "Notice: $outdated Homebrew packages can be updated. Run: brew upgrade"
        ) &
    elif is_linux && command -v apt >/dev/null 2>&1; then
        (
            if [[ -f /var/lib/apt/periodic/update-success-stamp ]]; then
                local last_update current_time days_since_update
                last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null)
                current_time=$(date +%s)
                days_since_update=$(( (current_time - last_update) / 86400 ))
                (( days_since_update > 7 )) && echo "Notice: Package database is ${days_since_update} days old. Consider: sudo apt update"
            fi
        ) &
    fi
}

dotfiles_setup_ssh_agent() {
    if [[ -z "${SSH_AUTH_SOCK:-}" && -f "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env" ]]; then
        # shellcheck source=/dev/null
        source "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env" 2>/dev/null
        ssh-add -l >/dev/null 2>&1 || unset SSH_AUTH_SOCK SSH_AGENT_PID
    fi
}

dotfiles_show_random_tip() {
    local tip_index DIM RESET
    tip_index=$((RANDOM % 10))
    DIM=$'\033[2m' RESET=$'\033[0m'
    case "$tip_index" in
        0) printf '%s\n' "${DIM}Tip: Use z for smart directory jumping with zoxide${RESET}" ;;
        1) printf '%s\n' "${DIM}Tip: Use fzf with Ctrl+T for fuzzy file finding${RESET}" ;;
        2) printf '%s\n' "${DIM}Tip: Use rg for fast text searching${RESET}" ;;
        3) printf '%s\n' "${DIM}Tip: Use bat for syntax-highlighted file viewing${RESET}" ;;
        4) printf '%s\n' "${DIM}Tip: Use eza -la for enhanced directory listings${RESET}" ;;
        5) printf '%s\n' "${DIM}Tip: Use gcm for quick git commits${RESET}" ;;
        6) printf '%s\n' "${DIM}Tip: Use lzg to launch LazyGit${RESET}" ;;
        7) printf '%s\n' "${DIM}Tip: Press Ctrl+R for interactive history search${RESET}" ;;
        8) printf '%s\n' "${DIM}Tip: Use .. and ... for quick directory navigation${RESET}" ;;
        9) printf '%s\n' "${DIM}Tip: Type help to see available custom commands${RESET}" ;;
    esac
    echo
}