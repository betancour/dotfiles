# .zlogout
# ========
# This file is sourced when login shells exit.
# It should contain cleanup commands and farewell messages.
# Keep this file fast as it affects shell exit time.

# Only proceed if this is a login shell
[[ -o login ]] || return

# Performance monitoring
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .zlogout started" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
fi

# Session Information
# ===================
local session_start_time="${ZSH_LOGIN_TIME:-unknown}"
local session_end_time="$(date '+%Y-%m-%d %H:%M:%S')"
local session_duration="unknown"

# Calculate session duration if we have start time
if [[ "$session_start_time" != "unknown" ]]; then
    local start_epoch=$(date -d "$session_start_time" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$session_start_time" +%s 2>/dev/null)
    local end_epoch=$(date +%s)

    if [[ -n "$start_epoch" && -n "$end_epoch" ]]; then
        local duration_seconds=$((end_epoch - start_epoch))
        local hours=$((duration_seconds / 3600))
        local minutes=$(((duration_seconds % 3600) / 60))
        local seconds=$((duration_seconds % 60))

        if [[ $hours -gt 0 ]]; then
            session_duration="${hours}h ${minutes}m ${seconds}s"
        elif [[ $minutes -gt 0 ]]; then
            session_duration="${minutes}m ${seconds}s"
        else
            session_duration="${seconds}s"
        fi
    fi
fi

# Cleanup Tasks
# =============
# Perform cleanup tasks before shell exit

cleanup_session() {
    # History management
    # Back up current history file if it exists and is not empty
    if [[ -f "$HISTFILE" && -s "$HISTFILE" ]]; then
        local hist_backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
        [[ ! -d "$hist_backup_dir" ]] && mkdir -p "$hist_backup_dir"

        # Create timestamped backup
        local backup_file="$hist_backup_dir/history.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$HISTFILE" "$backup_file" 2>/dev/null || true

        # Keep only last 5 backups
        ls -t "$hist_backup_dir"/history.bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
    fi

    # Clean up temporary files created during this session
    if [[ -n "$ZSH_SESSION_ID" ]]; then
        find /tmp -name "*$ZSH_SESSION_ID*" -user "$USER" -delete 2>/dev/null || true
    fi

    # Clean up any temporary completion files
    find "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" -name "*.tmp" -user "$USER" -delete 2>/dev/null || true

    # Clean up old socket files
    find /tmp -name "ssh-*" -user "$USER" -type s -not -newer /tmp -delete 2>/dev/null || true

    # Clear any sensitive environment variables
    unset AWS_SECRET_ACCESS_KEY 2>/dev/null || true
    unset GITHUB_TOKEN 2>/dev/null || true
    unset OPENAI_API_KEY 2>/dev/null || true
    unset DATABASE_PASSWORD 2>/dev/null || true

    # Log session information
    local log_file="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/sessions.log"
    [[ ! -d "$(dirname "$log_file")" ]] && mkdir -p "$(dirname "$log_file")"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Session ended: Duration: $session_duration, Commands: ${HISTCMD:-0}" >> "$log_file" 2>/dev/null || true

    # Rotate session log if it gets too large (keep last 100 lines)
    if [[ -f "$log_file" ]] && [[ $(wc -l < "$log_file" 2>/dev/null || echo 0) -gt 100 ]]; then
        tail -100 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file" 2>/dev/null || true
    fi
}

# SSH Agent Management
# ====================
manage_ssh_agent() {
    # If this is the last shell and we started the SSH agent, clean it up
    if [[ -n "$SSH_AGENT_PID" ]] && [[ "$SHLVL" -eq 1 ]]; then
        # Check if this agent process belongs to us
        if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
            # Check if there are other shells using this agent
            local agent_users=$(pgrep -f "ssh-agent" -u "$USER" | wc -l)
            if [[ "$agent_users" -eq 1 ]]; then
                ssh-agent -k >/dev/null 2>&1 || true
                rm -f "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env" 2>/dev/null || true
            fi
        fi
    fi
}

# GPG Agent Management
# ====================
manage_gpg_agent() {
    # Clean up GPG agent if we're the last shell
    if [[ "$SHLVL" -eq 1 ]] && command -v gpgconf >/dev/null 2>&1; then
        # Only kill if no other user processes are running
        local user_processes=$(ps -u "$USER" | wc -l)
        if [[ "$user_processes" -lt 10 ]]; then  # Arbitrary threshold
            gpgconf --kill gpg-agent 2>/dev/null || true
        fi
    fi
}

# Background Process Management
# =============================
cleanup_background_processes() {
    # Kill any background jobs started by this shell
    local jobs_output=$(jobs -p 2>/dev/null)
    if [[ -n "$jobs_output" ]]; then
        echo "$jobs_output" | while read -r pid; do
            [[ -n "$pid" ]] && kill -TERM "$pid" 2>/dev/null || true
        done

        # Give processes time to terminate gracefully
        sleep 0.5

        # Force kill if still running
        echo "$jobs_output" | while read -r pid; do
            [[ -n "$pid" ]] && kill -KILL "$pid" 2>/dev/null || true
        done
    fi
}

# Development Environment Cleanup
# ===============================
cleanup_dev_environment() {
    # Save current directory for next session
    if [[ -n "$PWD" && "$PWD" != "$HOME" ]]; then
        echo "$PWD" > "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/last_dir" 2>/dev/null || true
    fi

    # Clean up any development server processes we might have started
    # (This is conservative - only clean up processes we know we started)
    if [[ -f "${XDG_RUNTIME_DIR:-/tmp}/dev_servers.pid" ]]; then
        while read -r pid; do
            [[ -n "$pid" ]] && kill -TERM "$pid" 2>/dev/null || true
        done < "${XDG_RUNTIME_DIR:-/tmp}/dev_servers.pid"
        rm -f "${XDG_RUNTIME_DIR:-/tmp}/dev_servers.pid"
    fi

    # Clean up any temporary Docker containers created this session
    if command -v docker >/dev/null 2>&1 && [[ -n "$ZSH_SESSION_ID" ]]; then
        docker ps -a --filter "label=zsh_session=$ZSH_SESSION_ID" -q 2>/dev/null | \
            xargs -r docker rm -f 2>/dev/null || true
    fi
}

# Farewell Message
# ================
show_farewell_message() {
    # Only show for interactive terminal sessions
    if [[ -t 1 ]] && [[ -o interactive ]]; then
        # Terminal width for formatting
        local WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
        [[ $WIDTH -gt 100 ]] && WIDTH=100
        [[ $WIDTH -lt 60 ]] && WIDTH=60

        # Colors for output
        if [[ "$TERM" != "dumb" ]]; then
            local BLUE='\033[34m'
            local GREEN='\033[32m'
            local YELLOW='\033[33m'
            local CYAN='\033[36m'
            local BOLD='\033[1m'
            local DIM='\033[2m'
            local RESET='\033[0m'
        else
            local BLUE='' GREEN='' YELLOW='' CYAN='' BOLD='' DIM='' RESET=''
        fi

        # Helper function to center text
        center_text() {
            local text="$1"
            local color="${2:-$RESET}"
            local plain_text=$(echo "$text" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
            local plain_length=${#plain_text}

            if [[ $plain_length -gt $((WIDTH - 4)) ]]; then
                text="${plain_text:0:$((WIDTH - 7))}..."
                plain_length=${#text}
            fi

            local padding=$(( (WIDTH - 2 - plain_length) / 2 ))
            printf "|%*s%b%s%b%*s|\n" $padding "" "$color" "$text" "$RESET" $((WIDTH - 2 - padding - plain_length)) ""
        }

        # Create separator line
        separator_line() {
            local char="${1:-─}"
            printf "+%*s+\n" $((WIDTH - 2)) "" | tr ' ' "$char"
        }

        # Display farewell message
        echo
        separator_line "═"
        center_text "${BOLD}Goodbye, $USER!${RESET}" "$CYAN"
        separator_line "─"
        center_text "Session ended: $session_end_time" "$GREEN"
        center_text "Session duration: $session_duration" "$YELLOW"

        # Show some session stats if available
        if [[ -n "$HISTCMD" && "$HISTCMD" -gt 1 ]]; then
            center_text "Commands executed: $((HISTCMD - 1))" "$BLUE"
        fi

        # Random farewell message
        local farewells=(
            "Until next time! 👋"
            "Stay productive! ⚡"
            "Happy coding! 💻"
            "See you soon! 🚀"
            "Keep being awesome! ⭐"
            "Take care! 🌟"
            "Catch you later! 🎯"
            "Stay curious! 🔍"
            "Keep learning! 📚"
            "Have a great day! ☀️"
        )

        local random_farewell=${farewells[$((RANDOM % ${#farewells[@]} + 1))]}
        center_text "$random_farewell" "$CYAN"

        separator_line "═"
        echo
    fi
}

# Execute cleanup tasks
# =====================
# Run cleanup in background to avoid slowing down shell exit
(
    cleanup_session
    manage_ssh_agent
    manage_gpg_agent
    cleanup_background_processes
    cleanup_dev_environment
) &

# Show farewell message (foreground for immediate display)
show_farewell_message

# Load local logout customizations
# =================================
[[ -r "${ZDOTDIR:-$HOME}/.zlogout.local" ]] && source "${ZDOTDIR:-$HOME}/.zlogout.local"

# Final performance monitoring
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): .zlogout completed" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
fi

# Ensure all background cleanup completes (with timeout)
sleep 0.1
