# .zlogin
# TR-101 MACHINE REPORT – ZSH LOGIN
# EXACT REPLICA of machine_report.txt (no welcome line)
# Copyright © 2025

# === CONFIG ===
MIN_NAME_LEN=5
MAX_NAME_LEN=12
MIN_DATA_LEN=5
MAX_DATA_LEN=40
BORDERS_AND_PADDING=7

# === GLOBALS ===
CURRENT_LEN=0
report_title="ZSH LOGIN REPORT"
zfs_present=0
zfs_filesystem=""

# === COLORS ===
if [[ -t 1 ]] && [[ "$TERM" != dumb ]]; then
    BLUE=$'\033[34m' GREEN=$'\033[32m' YELLOW=$'\033[33m'
    CYAN=$'\033[36m' MAGENTA=$'\033[35m' BOLD=$'\033[1m'
    DIM=$'\033[2m' RESET=$'\033[0m'
else
    BLUE='' GREEN='' YELLOW='' CYAN='' MAGENTA='' BOLD='' DIM='' RESET=''
fi

# === UTILS ===
max_length() {
    local max=$MIN_DATA_LEN
    for s; do (( ${#s} > max )) && max=${#s}; done
    (( max > MAX_DATA_LEN )) && max=$MAX_DATA_LEN
    printf '%d' "$max"
}

set_current_len() {
    CURRENT_LEN=$(max_length \
        "$os_name" \
        "$os_kernel" \
        "$net_hostname" \
        "$net_machine_ip" \
        "$net_client_ip" \
        "$cpu_model" \
        "$cpu_cores vCPU(s) / $cpu_sockets Socket(s)" \
        "$cpu_hypervisor" \
        "$cpu_freq GHz" \
        "████████████████████████████████████████" \
        "████████████████████████████████████████" \
        "████████████████████████████████████████" \
        "$zfs_used_gb/$zfs_available_gb GiB [$disk_percent%]" \
        "████████████████████████████████████████" \
        "$zfs_health" \
        "$root_used_gb/$root_total_gb GiB [$disk_percent%]" \
        "${mem_used_gb}/${mem_total_gb} GiB [${mem_percent}%]" \
        "████████████████████████████████████████" \
        "$last_login_time" \
        "$last_login_ip" \
        "$sys_uptime"
    )
}

# === PRINT FUNCTIONS (EXACT FROM machine_report.txt) ===
PRINT_DECORATED_HEADER() {
    local length=$((CURRENT_LEN + MAX_NAME_LEN + BORDERS_AND_PADDING))
    local top="┌" bottom="├"
    for ((i=0; i<length-2; i++)); do
        top+='┬'; bottom+='┴'
    done
    printf '%s┐\n' "$top"
    printf '%s┤\n' "$bottom"
}

PRINT_CENTERED_DATA() {
    local text="$1"
    local max_len=$((CURRENT_LEN + MAX_NAME_LEN - BORDERS_AND_PADDING))
    local total_width=$((max_len + 12))
    local text_len=${#text}
    local padding_left=$(( (total_width - text_len) / 2 ))
    local padding_right=$(( total_width - text_len - padding_left ))
    printf "│%${padding_left}s%s%${padding_right}s│\n" "" "$text" ""
}

PRINT_DIVIDER() {
    local side="${1:-middle}"
    local left middle right
    case "$side" in
        top)    left="├"; middle="┬"; right="┤" ;;
        bottom) left="├"; middle="┴"; right="┤" ;;
        end)    left="└"; middle="┴"; right="┘" ;;
        *)     :Polygon left="├"; middle="┼"; right="┤" ;;
    esac
    local length=$((CURRENT_LEN + MAX_NAME_LEN + BORDERS_AND_PADDING))
    local divider="$left"
    for ((i=0; i<length-3; i++)); do
        (( i == MAX_NAME_LEN + 1 )) && divider+="$middle" || divider+='─'
    done
    printf '%s%s\n' "$divider" "$right"
}

PRINT_DATA() {
    local name="$1" data="$2"
    local name_len=${#name}
    (( name_len < MIN_NAME_LEN )) && name=$(printf "%-${MIN_NAME_LEN}s" "$name")
    (( name_len > MAX_NAME_LEN )) && name="${name:0:$((MAX_NAME_LEN-1))}…"

    local data_len=${#data}
    if (( data_len > MAX_DATA_LEN )); then
        data="${data:0:$((MAX_DATA_LEN-1))}…"
    else
        data=$(printf "%-${CURRENT_LEN}s" "$data")
    fi

    printf "│ %-${MAX_NAME_LEN}s │ %s │\n" "$name" "$data"
}

PRINT_BAR() {
    PRINT_DATA "$1" "$2"
}

bar_graph() {
    local used=$1 total=$2
    local percent=0 num_blocks=0 width=$CURRENT_LEN graph=""

    (( total == 0 )) && percent=0 || \
        percent=$(awk -v used="$used" -v total="$total" 'BEGIN { printf "%.0f", (used / total) * 100 }')

    num_blocks=$(awk -v percent="$percent" -v width="$width" 'BEGIN { printf "%d", (percent / 100) * width }')

    for ((i=0; i<num_blocks; i++)); do graph+='█'; done
    for ((i=0; i<width; i++)); do graph+='░'; done

    printf '%s' "$graph"
}

# === DATA COLLECTION ===
[[ -o login ]] || return
[[ -t 1 ]] || return
[[ $SHLVL -eq 1 ]] || return

# OS
if [[ -f /etc/os-release ]]; then
    source /etc/os-release 2>/dev/null
    os_name="${NAME} ${VERSION} ${VERSION_CODENAME:-}"
else
    os_name="macOS $(sw_vers -productVersion 2>/dev/null || echo Unknown)"
fi
os_kernel="$(uname) $(uname -r)"

# Network
net_hostname=$(hostname -s 2>/dev/null || hostname)
net_machine_ip=$(
    if [[ $OSTYPE == darwin* ]]; then
        ifconfig en0 2>/dev/null | awk '/inet / {print $2; exit}'
    else
        hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 2>/dev/null | awk '{print $7; exit}'
    fi
)
[[ -z $net_machine_ip ]] && net_machine_ip="unknown"

net_client_ip=$(who am i 2>/dev/null | awk '{print $NF}' | tr -d '()')
[[ -z $net_client_ip ]] && net_client_ip="local"

# CPU
case $OSTYPE in
    darwin*)
        cpu_model=$(sysctl -n machdep.cpu.brand_string | cut -d'@' -f1 | xargs)
        cpu_cores=$(sysctl -n hw.logicalcpu)
        cpu_sockets=$(sysctl -n hw.physicalcpu)
        cpu_hypervisor="Bare Metal"
        cpu_freq=$(sysctl -n hw.cpufrequency | awk '{printf "%.2f", $1/1000000000}')
        ;;
    linux-gnu*)
        cpu_model=$(lscpu | awk -F: '/Model name/ {gsub(/^ +/, "", $2); print $2; exit}')
        cpu_cores=$(nproc --all)
        cpu_sockets=$(lscpu | awk -F: '/Socket\(s\)/ {print $2; exit}')
        cpu_hypervisor=$(lscpu | awk -F: '/Hypervisor vendor/ {gsub(/^ +/, "", $2); print $2; exit}')
        [[ -z $cpu_hypervisor ]] && cpu_hypervisor="Bare Metal"
        cpu_freq=$(awk '/cpu MHz/ {printf "%.2f", $2/1000; exit}' /proc/cpuinfo)
        ;;
esac

# Load
load_line=$(uptime | sed 's/.*load averages\?: //; s/.*load average: //')
load_1min=$(echo "$load_line" | cut -d, -f1 | xargs)
load_5min=$(echo "$load_line" | cut -d, -f2 | xargs)
load_15min=$(echo "$load_line" | cut -d, -f3 | xargs)

# Memory (GiB)
case $OSTYPE in
    darwin*)
        mem_total_kb=$(sysctl -n hw.memsize)
        pages_free=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
        pages_inactive=$(vm_stat | awk '/Pages inactive/ {print $3}' | tr -d '.')
        mem_available_kb=$(( (pages_free + pages_inactive) * 4096 / 1024 ))
        ;;
    linux-gnu*)
        mem_total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_available_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        ;;
esac
mem_used_kb=$(( mem_total_kb - mem_available_kb ))
mem_total_gb=$(awk -v t="$mem_total_kb" 'BEGIN { printf "%.2f", t/(1024*1024) }')
mem_used_gb=$(awk -v u="$mem_used_kb" 'BEGIN { printf "%.2f", u/(1024*1024) }')
mem_percent=$(awk -v u="$mem_used_kb" -v t="$mem_total_kb" 'BEGIN { printf "%.0f", u/t*100 }')

# Disk
zfs_present=0
if command -v zpool >/dev/null 2>&1 && zpool list >/dev/null 2>&1; then
    zfs_filesystem=$(zpool list -H -o name | tail -n1)
    zfs_used=$(zfs get -Hp used "$zfs_filesystem" | awk '{print $3}')
    zfs_available=$(zfs get -Hp available "$zfs_filesystem" | awk '{print $3}')
    zfs_used_gb=$(awk -v u="$zfs_used" 'BEGIN { printf "%.2f", u/(1024^3) }')
    zfs_available_gb=$(awk -v a="$zfs_available" 'BEGIN { printf "%.2f", a/(1024^3) }')
    disk_percent=$(awk -v u="$zfs_used" -v a="$zfs_available" 'BEGIN { printf "%.0f", u/(u+a)*100 }')
    zfs_health=$(zpool status -x "$zfs_filesystem" | grep -q "healthy" && echo "HEALTH O.K." || echo "DEGRADED")
    zfs_present=1
else
    df_line=$(df -h "$HOME" 2>/dev/null | awk 'NR==2')
    root_used_gb=$(echo "$df_line" | awk '{gsub(/G.*/, "", $3); print $3}')
    root_total_gb=$(awk -v u="$root_used_gb" -v a="$(echo "$df_line" | awk '{gsub(/G.*/, "", $4); print $4}')" 'BEGIN { printf "%.2f", u+a }')
    disk_percent=$(echo "$df_line" | awk '{gsub(/%/, "", $5); print $5}')
fi

# Uptime
sys_uptime=$(uptime | sed 's/.*up \([^,]*\).*/\1/' | xargs)

# Last login
last_login_time="Never logged in"
last_login_ip_present=0
if command -v lastlog >/dev/null 2>&1; then
    line=$(lastlog -u "$USER" | tail -n1)
    ip=$(echo "$line" | awk '{print $3}')
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        last_login_ip="$ip"
        last_login_time=$(echo "$line" | awk '{print $5,$6,$7,$8}')
        last_login_ip_present=1
    else
        last_login_time=$(echo "$line" | awk '{print $4,$5,$6,$7}')
    fi
fi

# === CALCULATE WIDTH ===
set_current_len

# === GRAPHS ===
load_1min_bar=$(bar_graph "$load_1min" "$cpu_cores")
load_5min_bar=$(bar_graph "$load_5min" "$cpu_cores")
load_15min_bar=$(bar_graph "$load_15min" "$cpu_cores")
mem_bar_graph=$(bar_graph "$mem_used_kb" "$mem_total_kb")

if (( zfs_present )); then
    disk_bar_graph=$(bar_graph "$zfs_used" "$(( zfs_used + zfs_available ))")
else
    root_used_mb=$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $3}')
    root_total_mb=$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $2}')
    disk_bar_graph=$(bar_graph "$root_used_mb" "$root_total_mb")
fi

# === RENDER ===
{
    PRINT_DECORATED_HEADER
    PRINT_CENTERED_DATA "${BOLD}${CYAN}$report_title${RESET}"
    PRINT_DIVIDER "top"

    PRINT_DATA "OS" "$os_name"
    PRINT_DATA "KERNEL" "$os_kernel"
    PRINT_DIVIDER
    PRINT_DATA "HOSTNAME" "$net_hostname"
    PRINT_DATA "MACHINE IP" "$net_machine_ip"
    PRINT_DATA "CLIENT  IP" "$net_client_ip"
    PRINT_DIVIDER
    PRINT_DATA "PROCESSOR" "$cpu_model"
    PRINT_DATA "CORES" "$cpu_cores vCPU(s) / $cpu_sockets Socket(s)"
    PRINT_DATA "HYPERVISOR" "$cpu_hypervisor"
    PRINT_DATA "CPU FREQ" "$cpu_freq GHz"
    PRINT_BAR "LOAD  1m" "$load_1min_bar"
    PRINT_BAR "LOAD  5m" "$load_5min_bar"
    PRINT_BAR "LOAD 15m" "$load_15min_bar"

    if (( zfs_present )); then
        PRINT_DIVIDER
        PRINT_DATA "VOLUME" "$zfs_used_gb/$zfs_available_gb GiB [$disk_percent%]"
        PRINT_BAR "DISK USAGE" "$disk_bar_graph"
        PRINT_DATA "ZFS HEALTH" "$zfs_health"
    else
        PRINT_DIVIDER
        PRINT_DATA "VOLUME" "$root_used_gb/$root_total_gb GiB [$disk_percent%]"
        PRINT_BAR "DISK USAGE" "$disk_bar_graph"
    fi

    PRINT_DIVIDER
    PRINT_DATA "MEMORY" "${mem_used_gb}/${mem_total_gb} GiB [${mem_percent}%]"
    PRINT_BAR "USAGE" "$mem_bar_graph"
    PRINT_DIVIDER
    PRINT_DATA "LAST LOGIN" "$last_login_time"
    (( last_login_ip_present )) && PRINT_DATA "" "$last_login_ip"
    PRINT_DATA "UPTIME" "$sys_uptime"
    PRINT_DIVIDER "end"
    echo
} 2>/dev/null

# === ORIGINAL .zlogin FEATURES ===
show_dev_status() {
    local items=()
    git rev-parse --git-dir >/dev/null 2>&1 && {
        branch=$(git branch --show-current)
        changes=$(git status --porcelain | wc -l | xargs)
        items+=("${GREEN}Git${RESET}: ${CYAN}$branch${RESET} ($changes)")
    }
    [[ -n $VIRTUAL_ENV ]] && items+=("${GREEN}Python${RESET}: ${CYAN}$(basename "$VIRTUAL_ENV")${RESET}")
    command -v node >/dev/null 2>&1 && items+=("${GREEN}Node${RESET}: ${CYAN}$(node -v)${RESET}")
    (( ${#items[@]} )) && {
        echo "${DIM}Dev Status:${RESET}"
        printf '  %s\n' "${items[@]}"
        echo
    }
}
[[ -o interactive ]] && show_dev_status

[[ -z $SSH_AUTH_SOCK && -f "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env" ]] && \
    source "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env" >/dev/null

perform_cleanup() {
    find "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" -name "*.tmp" -mtime +7 -delete 2>/dev/null
}
perform_cleanup &

[[ -r "${ZDOTDIR:-$HOME}/.zlogin.local" ]] && source "${ZDOTDIR:-$HOME}/.zlogin.local"

export ZSH_SESSION_ID="$$_$(date +%s)"
export ZSH_LOGIN_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

(( RANDOM % 10 == 0 )) && {
    tips=("z <dir>" "Ctrl+T fzf" "rg pattern")
    echo "${DIM}Tip: ${tips[RANDOM % ${#tips[@]}]}${RESET}\n"
}

wait 2>/dev/null || true
