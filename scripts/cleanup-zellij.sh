#!/bin/bash

# Zellij Session Cleanup Script
# =============================
# This script helps clean up old and exited Zellij sessions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Function to print colored output
print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${RESET}"
}

# Function to show usage
show_usage() {
    echo "Zellij Session Cleanup Utility"
    echo "=============================="
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -l, --list         List all sessions (active and exited)"
    echo "  -c, --clean        Clean up all exited sessions"
    echo "  -a, --clean-all    Clean up ALL sessions (including active ones)"
    echo "  -i, --interactive  Interactive mode - choose which sessions to clean"
    echo "  -o, --old DAYS     Clean up sessions older than DAYS (default: 7)"
    echo
    echo "Examples:"
    echo "  $0 --list                    # List all sessions"
    echo "  $0 --clean                   # Clean up exited sessions"
    echo "  $0 --old 3                   # Clean up sessions older than 3 days"
    echo "  $0 --interactive             # Choose which sessions to clean"
}

# Function to check if zellij is available
check_zellij() {
    if ! command -v zellij >/dev/null 2>&1; then
        print_color "$RED" "Error: Zellij is not installed or not in PATH"
        exit 1
    fi
}

# Function to list all sessions
list_sessions() {
    print_color "$BLUE" "Zellij Sessions:"
    print_color "$BLUE" "==============="
    echo

    local sessions_output
    sessions_output=$(zellij list-sessions 2>/dev/null || echo "")

    if [[ -z "$sessions_output" ]]; then
        print_color "$YELLOW" "No Zellij sessions found."
        return 0
    fi

    local active_count=0
    local exited_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ EXITED ]]; then
            print_color "$RED" "❌ $line"
            ((exited_count++))
        else
            print_color "$GREEN" "✅ $line"
            ((active_count++))
        fi
    done <<< "$sessions_output"

    echo
    print_color "$CYAN" "Summary: $active_count active, $exited_count exited sessions"
}

# Function to get session names that match criteria
get_sessions_to_clean() {
    local clean_exited_only="$1"
    local max_age_days="${2:-0}"

    local sessions_output
    sessions_output=$(zellij list-sessions 2>/dev/null || echo "")

    if [[ -z "$sessions_output" ]]; then
        return 0
    fi

    local current_epoch
    current_epoch=$(date +%s)

    while IFS= read -r line; do
        local session_name
        session_name=$(echo "$line" | awk '{print $1}')

        # Skip empty lines
        [[ -z "$session_name" ]] && continue

        # If cleaning exited only, skip active sessions
        if [[ "$clean_exited_only" == "true" ]] && [[ ! "$line" =~ EXITED ]]; then
            continue
        fi

        # If max age is specified, check age
        if [[ "$max_age_days" -gt 0 ]]; then
            # Extract age information from the line
            # Format: "session-name [Created Xdays Yh Zm Zs ago]"
            local age_part
            age_part=$(echo "$line" | sed -n 's/.*\[Created \(.*\) ago\].*/\1/p')

            if [[ -n "$age_part" ]]; then
                # Convert age to days (rough calculation)
                local days=0
                if [[ "$age_part" =~ ([0-9]+)days? ]]; then
                    days=${BASH_REMATCH[1]}
                fi

                # Skip if not old enough
                if [[ "$days" -lt "$max_age_days" ]]; then
                    continue
                fi
            fi
        fi

        echo "$session_name"
    done <<< "$sessions_output"
}

# Function to clean up sessions
clean_sessions() {
    local sessions_to_clean=("$@")

    if [[ ${#sessions_to_clean[@]} -eq 0 ]]; then
        print_color "$YELLOW" "No sessions to clean up."
        return 0
    fi

    print_color "$YELLOW" "Sessions to be cleaned:"
    for session in "${sessions_to_clean[@]}"; do
        echo "  - $session"
    done
    echo

    read -p "Are you sure you want to delete these sessions? (y/N): " -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "Cleanup cancelled."
        return 0
    fi

    local cleaned_count=0
    local failed_count=0

    for session in "${sessions_to_clean[@]}"; do
        print_color "$CYAN" "Cleaning session: $session"
        if zellij delete-session "$session" 2>/dev/null; then
            print_color "$GREEN" "✅ Successfully deleted: $session"
            ((cleaned_count++))
        else
            print_color "$RED" "❌ Failed to delete: $session"
            ((failed_count++))
        fi
    done

    echo
    print_color "$BOLD" "Cleanup Summary:"
    print_color "$GREEN" "Successfully cleaned: $cleaned_count sessions"
    if [[ "$failed_count" -gt 0 ]]; then
        print_color "$RED" "Failed to clean: $failed_count sessions"
    fi
}

# Function for interactive cleanup
interactive_cleanup() {
    print_color "$BLUE" "Interactive Session Cleanup"
    print_color "$BLUE" "=========================="
    echo

    local sessions_output
    sessions_output=$(zellij list-sessions 2>/dev/null || echo "")

    if [[ -z "$sessions_output" ]]; then
        print_color "$YELLOW" "No Zellij sessions found."
        return 0
    fi

    local sessions_array=()
    local selected_sessions=()

    # Build array of sessions
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local session_name
        session_name=$(echo "$line" | awk '{print $1}')
        sessions_array+=("$session_name" "$line")
    done <<< "$sessions_output"

    if [[ ${#sessions_array[@]} -eq 0 ]]; then
        print_color "$YELLOW" "No sessions available for cleanup."
        return 0
    fi

    # Show sessions and let user select
    for ((i=0; i<${#sessions_array[@]}; i+=2)); do
        local idx=$((i/2 + 1))
        local session_name="${sessions_array[i]}"
        local session_info="${sessions_array[i+1]}"

        if [[ "$session_info" =~ EXITED ]]; then
            print_color "$RED" "$idx) ❌ $session_info"
        else
            print_color "$GREEN" "$idx) ✅ $session_info"
        fi
    done

    echo
    echo "Enter session numbers to delete (space-separated), 'all' for all sessions, or 'exited' for exited sessions only:"
    read -r selection

    case "$selection" in
        "all")
            for ((i=0; i<${#sessions_array[@]}; i+=2)); do
                selected_sessions+=("${sessions_array[i]}")
            done
            ;;
        "exited")
            for ((i=0; i<${#sessions_array[@]}; i+=2)); do
                local session_name="${sessions_array[i]}"
                local session_info="${sessions_array[i+1]}"
                if [[ "$session_info" =~ EXITED ]]; then
                    selected_sessions+=("$session_name")
                fi
            done
            ;;
        *)
            # Parse individual numbers
            for num in $selection; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le $((${#sessions_array[@]}/2)) ]]; then
                    local array_index=$(((num-1)*2))
                    selected_sessions+=("${sessions_array[array_index]}")
                else
                    print_color "$YELLOW" "Warning: Invalid selection '$num', skipping."
                fi
            done
            ;;
    esac

    if [[ ${#selected_sessions[@]} -gt 0 ]]; then
        clean_sessions "${selected_sessions[@]}"
    else
        print_color "$YELLOW" "No sessions selected for cleanup."
    fi
}

# Main function
main() {
    local action=""
    local max_age_days=0

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                action="list"
                ;;
            -c|--clean)
                action="clean"
                ;;
            -a|--clean-all)
                action="clean-all"
                ;;
            -i|--interactive)
                action="interactive"
                ;;
            -o|--old)
                if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                    max_age_days="$2"
                    shift
                else
                    print_color "$RED" "Error: --old requires a numeric argument"
                    exit 1
                fi
                ;;
            *)
                print_color "$RED" "Error: Unknown option '$1'"
                show_usage
                exit 1
                ;;
        esac
        shift
    done

    # Check if zellij is available
    check_zellij

    # Execute action
case "$action" in
    "list"|"")
        list_sessions
        ;;
    "clean")
        local sessions_to_clean=()
        while IFS= read -r session; do
            [[ -n "$session" ]] && sessions_to_clean+=("$session")
        done < <(get_sessions_to_clean "true" "$max_age_days")
        clean_sessions "${sessions_to_clean[@]}"
        ;;
    "clean-all")
        local sessions_to_clean=()
        while IFS= read -r session; do
            [[ -n "$session" ]] && sessions_to_clean+=("$session")
        done < <(get_sessions_to_clean "false" "$max_age_days")
        clean_sessions "${sessions_to_clean[@]}"
        ;;
    "interactive")
        interactive_cleanup
        ;;
esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
