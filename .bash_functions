# .bash_functions
# ===============
# Custom Bash functions for enhanced shell experience
# This file contains utility functions that extend shell functionality

# Directory Operations
# ====================

# Create and enter directory
mkcd() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: mkcd <directory_name>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Go up N directories (default 1)
up() {
    local levels=${1:-1}
    local path=""
    for ((i=1; i<=levels; i++)); do
        path="../$path"
    done
    cd "$path" || return 1
}

# Find and cd to directory (using fzf if available)
cdf() {
    local dir
    if command -v fzf >/dev/null 2>&1; then
        dir=$(find . -type d 2>/dev/null | fzf --preview 'ls -la {}' --height 40%)
        [[ -n "$dir" ]] && cd "$dir"
    else
        echo "fzf not found. Install fzf for interactive directory selection."
        return 1
    fi
}

# Extract various archive formats
extract() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: extract <archive_file>"
        echo "Supported formats: tar.gz, tar.bz2, tar.xz, zip, rar, 7z, gz, bz2, xz"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi

    case "$1" in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.tar.xz)    tar xJf "$1"     ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       unrar x "$1"     ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *.xz)        unxz "$1"        ;;
        *)           echo "Error: '$1' cannot be extracted via extract()" ;;
    esac
}

# File Operations
# ===============

# Find file by name
findfile() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: findfile <filename>"
        return 1
    fi
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directory by name
finddir() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: finddir <dirname>"
        return 1
    fi
    find . -type d -iname "*$1*" 2>/dev/null
}

# Get file size in human readable format
fsize() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: fsize <file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi

    if command -v du >/dev/null 2>&1; then
        du -h "$1" | cut -f1
    else
        ls -lh "$1" | awk '{print $5}'
    fi
}

# Create backup of file
backup() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: backup <file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi

    local backup_name="${1}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$1" "$backup_name"
    echo "Backup created: $backup_name"
}

# System Information
# ==================

# Show system information
sysinfo() {
    echo "System Information:"
    echo "=================="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"

    if command -v uptime >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F', load' '{print $1}')"
        else
            echo "Uptime: $(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F', load' '{print $1}')"
        fi
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS Version: $(sw_vers -productVersion 2>/dev/null || echo "unknown")"
        if command -v vm_stat >/dev/null 2>&1; then
            local memory_info=$(vm_stat | awk '
                /Pages free/ {free=$3}
                /Pages active/ {active=$3}
                /Pages inactive/ {inactive=$3}
                /Pages speculative/ {speculative=$3}
                /Pages wired/ {wired=$3}
                END {
                    total=(free+active+inactive+speculative+wired)*4096/1024/1024/1024;
                    printf "%.1f GB total", total
                }'
            )
            echo "Memory: $memory_info"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        [[ -f /etc/os-release ]] && echo "Distribution: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
        if [[ -f /proc/meminfo ]]; then
            local total_mem=$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
            echo "Memory: $total_mem"
        fi
    fi
}

# Show disk usage for current directory
dusk() {
    if command -v du >/dev/null 2>&1; then
        du -sh ./* 2>/dev/null | sort -hr
    else
        echo "du command not found"
        return 1
    fi
}

# Show process tree
pstree() {
    if command -v pstree >/dev/null 2>&1; then
        command pstree "$@"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        ps -e -o pid,ppid,command | awk 'NR>1 {print $1, $2, substr($0, index($0,$3))}'
    else
        ps auxf
    fi
}

# Network Operations
# ==================

# Get external IP address
myip() {
    local ip=""
    for service in "ifconfig.me" "icanhazip.com" "ipecho.net/plain" "ifconfig.co"; do
        ip=$(curl -s --max-time 5 "$service" 2>/dev/null)
        if [[ -n "$ip" ]]; then
            echo "External IP: $ip"
            return 0
        fi
    done
    echo "Unable to determine external IP"
    return 1
}

# Get local IP addresses
localip() {
    echo "Local IP addresses:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}'
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v ip >/dev/null 2>&1; then
            ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}' | cut -d'/' -f1
        else
            ifconfig 2>/dev/null | awk '/inet / && !/127.0.0.1/ {print "  " $2}' | cut -d: -f2
        fi
    fi
}

# Ping with count and time
pingtest() {
    local host=${1:-google.com}
    local count=${2:-4}
    echo "Pinging $host ($count times)..."
    ping -c "$count" "$host"
}

# Development Utilities
# =====================

# Git helpers
gitclean() {
    echo "Cleaning git repository..."
    git clean -fd
    git reset --hard HEAD
    git pull
    echo "Repository cleaned and updated"
}

# Quick git commit and push
gitcp() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: gitcp <commit_message>"
        return 1
    fi

    git add -A
    git commit -m "$*"
    git push
}

# Create new git branch and switch to it
gitbr() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: gitbr <branch_name>"
        return 1
    fi

    git checkout -b "$1"
}

# Show git log in a nice format
gitlog() {
    local count=${1:-10}
    git log --oneline --graph --decorate -n "$count"
}

# Docker helpers
dps() {
    if command -v docker >/dev/null 2>&1; then
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Docker not found"
        return 1
    fi
}

# Docker cleanup
dclean() {
    if command -v docker >/dev/null 2>&1; then
        echo "Cleaning up Docker..."
        docker system prune -f
        docker image prune -f
        echo "Docker cleanup completed"
    else
        echo "Docker not found"
        return 1
    fi
}

# Text Processing
# ===============

# Count lines, words, and characters in files
count() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: count <file1> [file2] ..."
        return 1
    fi

    for file in "$@"; do
        if [[ -f "$file" ]]; then
            echo "File: $file"
            wc -lwc "$file"
            echo
        else
            echo "Error: '$file' is not a valid file"
        fi
    done
}

# Search and replace in files
replace() {
    if [[ $# -lt 3 ]]; then
        echo "Usage: replace <search_pattern> <replace_pattern> <file1> [file2] ..."
        return 1
    fi

    local search="$1"
    local replace="$2"
    shift 2

    for file in "$@"; do
        if [[ -f "$file" ]]; then
            if command -v sed >/dev/null 2>&1; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i .bak "s/$search/$replace/g" "$file"
                else
                    sed -i.bak "s/$search/$replace/g" "$file"
                fi
                echo "Replaced in: $file (backup: ${file}.bak)"
            else
                echo "sed not found"
                return 1
            fi
        else
            echo "Error: '$file' is not a valid file"
        fi
    done
}

# Utility Functions
# =================

# Weather information
weather() {
    local location=${1:-""}
    if command -v curl >/dev/null 2>&1; then
        curl -s "wttr.in/${location}?format=%C+%t+%h+%w"
        echo
    else
        echo "curl not found"
        return 1
    fi
}

# Generate random password
genpass() {
    local length=${1:-16}
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 $((length * 3 / 4)) | cut -c1-"$length"
    elif [[ -f /dev/urandom ]]; then
        LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c "$length"
        echo
    else
        echo "Unable to generate password"
        return 1
    fi
}

# URL encode string
urlencode() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: urlencode <string>"
        return 1
    fi

    local string="$*"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import urllib.parse; print(urllib.parse.quote('$string'))"
    elif command -v python >/dev/null 2>&1; then
        python -c "import urllib; print urllib.quote('$string')"
    else
        # Fallback manual encoding
        local encoded=""
        local char
        for ((i=0; i<${#string}; i++)); do
            char="${string:$i:1}"
            case "$char" in
                [a-zA-Z0-9.~_-]) encoded+="$char" ;;
                *) printf -v hex '%02X' "'$char"
                   encoded+="%$hex" ;;
            esac
        done
        echo "$encoded"
    fi
}

# URL decode string
urldecode() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: urldecode <string>"
        return 1
    fi

    local url_encoded="$*"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import urllib.parse; print(urllib.parse.unquote('$url_encoded'))"
    elif command -v python >/dev/null 2>&1; then
        python -c "import urllib; print urllib.unquote('$url_encoded')"
    else
        printf '%b' "${url_encoded//%/\\x}"
    fi
}

# Performance and Monitoring
# ===========================

# Show top processes by CPU usage
topcpu() {
    local count=${1:-10}
    if [[ "$OSTYPE" == "darwin"* ]]; then
        top -l 1 -o cpu | head -n $((count + 12))
    else
        ps aux --sort=-%cpu | head -n $((count + 1))
    fi
}

# Show top processes by memory usage
topmem() {
    local count=${1:-10}
    if [[ "$OSTYPE" == "darwin"* ]]; then
        top -l 1 -o rsize | head -n $((count + 12))
    else
        ps aux --sort=-%mem | head -n $((count + 1))
    fi
}

# Monitor command execution time
timeit() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: timeit <command>"
        return 1
    fi

    local start_time
    if command -v date >/dev/null 2>&1; then
        if date +%s.%N >/dev/null 2>&1; then
            start_time=$(date +%s.%N)
        else
            start_time=$(date +%s)
        fi
    fi

    "$@"
    local exit_code=$?

    if [[ -n "$start_time" ]]; then
        local end_time
        if date +%s.%N >/dev/null 2>&1; then
            end_time=$(date +%s.%N)
            local duration
            if command -v bc >/dev/null 2>&1; then
                duration=$(echo "$end_time - $start_time" | bc)
            else
                duration=$((end_time - start_time))
            fi
        else
            end_time=$(date +%s)
            duration=$((end_time - start_time))
        fi
        echo "Command executed in: ${duration}s (exit code: $exit_code)"
    else
        echo "Command completed (exit code: $exit_code)"
    fi

    return $exit_code
}

# Project Management
# ==================

# Quick project setup
mkproject() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: mkproject <project_name>"
        return 1
    fi

    local project_name="$1"
    local project_dir="$HOME/projects/$project_name"

    echo "Creating project: $project_name"
    mkdir -p "$project_dir"
    cd "$project_dir"

    # Initialize git repository
    git init
    echo "# $project_name" > README.md
    echo ".DS_Store" > .gitignore
    echo "node_modules/" >> .gitignore
    echo "*.log" >> .gitignore

    echo "Project '$project_name' created in $project_dir"
}

# Help Functions
# ==============

# Show available custom functions
help() {
    echo "Custom Bash Functions:"
    echo "====================="
    echo
    echo "Directory Operations:"
    echo "  mkcd <dir>         - Create and enter directory"
    echo "  up [n]             - Go up N directories (default: 1)"
    echo "  cdf                - Find and cd to directory (requires fzf)"
    echo "  extract <archive>  - Extract various archive formats"
    echo
    echo "File Operations:"
    echo "  findfile <name>    - Find file by name"
    echo "  finddir <name>     - Find directory by name"
    echo "  fsize <file>       - Get file size in human readable format"
    echo "  backup <file>      - Create timestamped backup of file"
    echo
    echo "System Information:"
    echo "  sysinfo            - Show system information"
    echo "  dusk               - Show disk usage for current directory"
    echo "  pstree             - Show process tree"
    echo
    echo "Network Operations:"
    echo "  myip               - Get external IP address"
    echo "  localip            - Get local IP addresses"
    echo "  pingtest [host]    - Ping test with default count"
    echo
    echo "Development Utilities:"
    echo "  gitclean           - Clean and update git repository"
    echo "  gitcp <msg>        - Quick git commit and push"
    echo "  gitbr <name>       - Create and switch to new branch"
    echo "  gitlog [count]     - Show git log in nice format"
    echo "  dps                - Show Docker containers"
    echo "  dclean             - Docker cleanup"
    echo
    echo "Text Processing:"
    echo "  count <files>      - Count lines, words, and characters"
    echo "  replace <s> <r> <files> - Search and replace in files"
    echo
    echo "Utilities:"
    echo "  weather [location] - Get weather information"
    echo "  genpass [length]   - Generate random password"
    echo "  urlencode <string> - URL encode string"
    echo "  urldecode <string> - URL decode string"
    echo
    echo "Performance:"
    echo "  topcpu [count]     - Show top processes by CPU"
    echo "  topmem [count]     - Show top processes by memory"
    echo "  timeit <command>   - Time command execution"
    echo
    echo "Project Management:"
    echo "  mkproject <name>   - Create new project with git init"
    echo
    echo "Use 'help' to show this message again."
}

# Auto-complete function names for bash completion
if command -v complete >/dev/null 2>&1; then
    # Add completion for functions that take file arguments
    complete -f backup fsize extract count replace
    # Add completion for functions that take directory arguments
    complete -d mkcd cdf finddir
fi

# Load local custom functions if they exist
[[ -f "$HOME/.bash_functions.local" ]] && source "$HOME/.bash_functions.local"
