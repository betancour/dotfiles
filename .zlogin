# .zlogin
# =======
# This file is sourced by login shells after .zshrc.
# It should contain commands that should be run after the interactive
# environment is fully set up. This is the last file sourced for login shells.

# Only proceed if this is a login shell
[[ -o login ]] || return

# Performance monitoring
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .zlogin started" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
fi

# System Information Display
# ==========================
# Display system information on login

# Terminal width for formatting
WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
[[ $WIDTH -gt 100 ]] && WIDTH=100
[[ $WIDTH -lt 60 ]] && WIDTH=60

# Colors for output
if [[ -t 1 ]] && [[ "$TERM" != "dumb" ]]; then
    local BLUE=$'\033[34m'
    local GREEN=$'\033[32m'
    local YELLOW=$'\033[33m'
    local CYAN=$'\033[36m'
    local MAGENTA=$'\033[35m'
    local RED=$'\033[31m'
    local BOLD=$'\033[1m'
    local DIM=$'\033[2m'
    local RESET=$'\033[0m'
else
    local BLUE=''
    local GREEN=''
    local YELLOW=''
    local CYAN=''
    local MAGENTA=''
    local RED=''
    local BOLD=''
    local DIM=''
    local RESET=''
fi

# Helper function to center text
center_text() {
    local text="$1"
    local color="${2:-}"

    # Remove ANSI codes for length calculation
    local plain_text=$(echo "$text" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
    local plain_length=${#plain_text}

    if [[ $plain_length -gt $((WIDTH - 4)) ]]; then
        plain_text="${plain_text:0:$((WIDTH - 7))}..."
        plain_length=${#plain_text}
    fi

    local padding=$(( (WIDTH - 2 - plain_length) / 2 ))
    if [[ -n "$color" ]]; then
        printf "|%*s%s%s%s%*s|\n" $padding "" "$color" "$plain_text" "$RESET" $((WIDTH - 2 - padding - plain_length)) ""
    else
        printf "|%*s%s%*s|\n" $padding "" "$plain_text" $((WIDTH - 2 - padding - plain_length)) ""
    fi
}

# Helper function to create separator line
separator_line() {
    local char="${1:-─}"
    printf "+%*s+\n" $((WIDTH - 2)) "" | tr ' ' "$char"
}

# Get system information
get_system_info() {
    local datetime=$(date '+%A, %B %d, %Y – %H:%M:%S')
    local hostname=$(hostname -s 2>/dev/null || hostname)
    local username="$USER"

    # Get IP address
    local ip="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        ip=$(ifconfig en0 2>/dev/null | awk '/inet / {print $2}' | head -n1)
        [[ -z "$ip" ]] && ip=$(ifconfig en1 2>/dev/null | awk '/inet / {print $2}' | head -n1)
        [[ -z "$ip" ]] && ip=$(route get default 2>/dev/null | awk '/interface:/ {print $2}' | head -n1 | xargs ifconfig 2>/dev/null | awk '/inet / {print $2}' | head -n1)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        [[ -z "$ip" ]] && ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
        [[ -z "$ip" ]] && ip=$(ifconfig 2>/dev/null | awk '/inet / && !/127.0.0.1/ {print $2; exit}' | cut -d: -f2)
    fi
    [[ -z "$ip" ]] && ip="unavailable"

    # Get uptime
    local uptime_info="unknown"
    if command -v uptime >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            uptime_info=$(uptime | sed 's/.*up \([^,]*\).*/\1/' | xargs)
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            uptime_info=$(uptime -p 2>/dev/null | sed 's/up //' || uptime | sed 's/.*up \([^,]*\).*/\1/' | xargs)
        fi
    fi

    # Get load average
    local load="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' | cut -d',' -f1 | xargs)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        load=$(cat /proc/loadavg 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    fi

    # Get memory usage (simplified)
    local memory="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v vm_stat >/dev/null 2>&1; then
            local pages_free=$(vm_stat | awk '/Pages free/ {print $3}' | sed 's/\.//')
            local pages_inactive=$(vm_stat | awk '/Pages inactive/ {print $3}' | sed 's/\.//')
            if [[ -n "$pages_free" && -n "$pages_inactive" ]]; then
                local free_mb=$(( (pages_free + pages_inactive) * 4096 / 1024 / 1024 ))
                memory="${free_mb}MB free"
            fi
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -r /proc/meminfo ]]; then
            local mem_available=$(awk '/MemAvailable/ {print int($2/1024)"MB"}' /proc/meminfo 2>/dev/null)
            [[ -n "$mem_available" ]] && memory="$mem_available available"
        fi
    fi

    # Get disk usage for home directory
    local disk_usage="unknown"
    if command -v df >/dev/null 2>&1; then
        disk_usage=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $4 " available (" $5 " used)"}')
    fi

    # Display the information
    echo
    separator_line "═"
    center_text "Welcome back, $username!" "$BOLD$CYAN"
    separator_line "─"
    center_text "$datetime" "$GREEN"
    center_text "Host: $hostname | IP: $ip" "$BLUE"
    center_text "Uptime: $uptime_info | Load: $load" "$YELLOW"
    [[ "$memory" != "unknown" ]] && center_text "Memory: $memory" "$MAGENTA"
    [[ "$disk_usage" != "unknown" ]] && center_text "Disk: $disk_usage" "$CYAN"
    separator_line "═"
    echo
}

# Show system information for interactive login shells
if [[ -t 1 ]] && [[ "$SHLVL" -eq 1 ]]; then
    get_system_info
fi

# Development Environment Status
# ==============================
# Show status of development tools and services

show_dev_status() {
    local status_items=()

    # Check Git status
    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        local git_branch=$(git branch --show-current 2>/dev/null)
        local git_status=$(git status --porcelain 2>/dev/null | wc -l | xargs)
        if [[ -n "$git_branch" ]]; then
            status_items+=("${GREEN}Git${RESET}: ${CYAN}$git_branch${RESET} ($git_status changes)")
        fi
    fi

    # Check if we're in a Python virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        status_items+=("${GREEN}Python${RESET}: ${CYAN}$venv_name${RESET} (venv)")
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        status_items+=("${GREEN}Python${RESET}: ${CYAN}$CONDA_DEFAULT_ENV${RESET} (conda)")
    fi

    # Check Node.js version if available
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version 2>/dev/null)
        status_items+=("${GREEN}Node${RESET}: ${CYAN}${node_version}${RESET}")
    fi

    # Check if Docker is running
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            local containers=$(docker ps -q 2>/dev/null | wc -l | xargs)
            status_items+=("${GREEN}Docker${RESET}: ${CYAN}running${RESET} ($containers containers)")
        else
            status_items+=("${YELLOW}Docker${RESET}: ${DIM}not running${RESET}")
        fi
    fi

    # Show development status if there are any items
    if [[ ${#status_items[@]} -gt 0 ]]; then
        echo "${DIM}Development Status:${RESET}"
        for item in "${status_items[@]}"; do
            echo "  $item"
        done
        echo
    fi
}

# Show development status for interactive sessions
if [[ -t 1 ]] && [[ -o interactive ]]; then
    show_dev_status
fi

# Check for system updates (optional)
# ====================================
check_updates() {
    # Only check once per day to avoid slowing down login
    local update_check_file="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_update_check"
    local current_day=$(date +%Y%m%d)
    local last_check=""

    [[ -f "$update_check_file" ]] && last_check=$(cat "$update_check_file" 2>/dev/null)

    if [[ "$last_check" != "$current_day" ]]; then
        echo "$current_day" > "$update_check_file"

        if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
            # Check for Homebrew updates (non-blocking)
            (
                local outdated=$(brew outdated --quiet 2>/dev/null | wc -l | xargs)
                if [[ "$outdated" -gt 0 ]]; then
                    echo "${YELLOW}Notice:${RESET} $outdated Homebrew packages can be updated. Run ${CYAN}brew upgrade${RESET}"
                fi
            ) &
        elif [[ "$OSTYPE" == "linux-gnu"* ]] && command -v apt >/dev/null 2>&1; then
            # Check for apt updates (non-blocking)
            (
                if [[ -f /var/lib/apt/periodic/update-success-stamp ]]; then
                    local last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null)
                    local current_time=$(date +%s)
                    local days_since_update=$(( (current_time - last_update) / 86400 ))

                    if [[ $days_since_update -gt 7 ]]; then
                        echo "${YELLOW}Notice:${RESET} Package database is $days_since_update days old. Consider running ${CYAN}sudo apt update${RESET}"
                    fi
                fi
            ) &
        fi
    fi
}

# Check for updates (only for primary login shells)
if [[ "$SHLVL" -eq 1 ]] && [[ -t 1 ]]; then
    check_updates
fi

# SSH Agent Integration
# =====================
# Ensure SSH agent is properly set up for the session

setup_ssh_agent() {
    # If SSH_AUTH_SOCK is not set, try to find an existing agent
    if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -f "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env" ]]; then
        source "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env" >/dev/null 2>&1

        # Test if the agent is still running
        if ! ssh-add -l >/dev/null 2>&1; then
            unset SSH_AUTH_SOCK SSH_AGENT_PID
        fi
    fi
}

setup_ssh_agent

# Cleanup and Maintenance
# =======================
# Perform light cleanup tasks on login

perform_cleanup() {
    # Clean up old temporary files (older than 7 days)
    if [[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]]; then
        find "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" -name "*.tmp" -mtime +7 -delete 2>/dev/null || true
    fi

    # Clean up old history backups (keep last 5)
    if [[ -d "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" ]]; then
        ls -t "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"/history.bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
    fi

    # Compact zsh completion dump if it's large
    local compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"
    if [[ -f "$compdump" ]] && [[ $(wc -l < "$compdump" 2>/dev/null || echo 0) -gt 1000 ]]; then
        # Rebuild completion dump in background
        (
            sleep 1
            autoload -U compinit
            compinit -d "$compdump"
        ) &
    fi
}

# Perform cleanup tasks in background
perform_cleanup &

# Load local login customizations
# ===============================
[[ -r "${ZDOTDIR:-$HOME}/.zlogin.local" ]] && source "${ZDOTDIR:-$HOME}/.zlogin.local"

# Final performance monitoring
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .zlogin completed" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
fi

# Set up session-specific variables
# ==================================
export ZSH_SESSION_ID="$$_$(date +%s)"
export ZSH_LOGIN_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

# Print helpful tips occasionally
# ================================
if [[ -t 1 ]] && [[ "$SHLVL" -eq 1 ]] && [[ $((RANDOM % 10)) -eq 0 ]]; then
    local tips=(
        "💡 Tip: Use 'z <directory>' for smart directory jumping with zoxide"
        "💡 Tip: Use 'fzf' (Ctrl+T) for fuzzy file finding"
        "💡 Tip: Use 'rg <pattern>' for fast text searching"
        "💡 Tip: Use 'bat <file>' for syntax-highlighted file viewing"
        "💡 Tip: Use 'eza -la' for enhanced directory listings"
        "💡 Tip: Use 'gcm \"message\"' for quick git commits"
        "💡 Tip: Use 'lzg' to launch LazyGit for visual git management"
        "💡 Tip: Press Ctrl+R for interactive history search"
        "💡 Tip: Use '..' and '...' for quick directory navigation"
        "💡 Tip: Type 'help' to see available custom commands"
    )

    local random_tip=${tips[$((RANDOM % ${#tips[@]} + 1))]}
    echo "${DIM}${random_tip}${RESET}"
    echo
fi

# Wait for background tasks to complete (with timeout)
wait 2>/dev/null || true
