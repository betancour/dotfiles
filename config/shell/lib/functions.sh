# functions.sh — shared shell functions (POSIX/bash-compatible)

if [[ -n "${DOTFILES_FUNCTIONS_LOADED:-}" ]]; then
    if typeset -f help >/dev/null 2>&1 || declare -f help >/dev/null 2>&1; then
        return 0
    fi
    unset DOTFILES_FUNCTIONS_LOADED
fi
DOTFILES_FUNCTIONS_LOADED=1

# Editor shortcut
if command -v nvim >/dev/null 2>&1; then
    n() { if [[ $# -eq 0 ]]; then nvim .; else nvim "$@"; fi; }
else
    n() { if [[ $# -eq 0 ]]; then vim .; else vim "$@"; fi; }
fi

mkcd() {
    [[ $# -eq 0 ]] && { echo "Usage: mkcd <directory_name>"; return 1; }
    mkdir -p "$1" && cd "$1"
}

up() {
    local levels=${1:-1} path="" i
    for ((i = 1; i <= levels; i++)); do path="../$path"; done
    cd "$path" || return 1
}

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

extract() {
    [[ $# -eq 0 ]] && { echo "Usage: extract <archive_file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz)         tar xJf "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.rar)            unrar x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.Z)              uncompress "$1" ;;
        *.7z)             7z x "$1" ;;
        *.xz)             unxz "$1" ;;
        *)                echo "Error: '$1' cannot be extracted via extract()" ;;
    esac
}

findfile() {
    [[ $# -eq 0 ]] && { echo "Usage: findfile <filename>"; return 1; }
    find . -type f -iname "*$1*" 2>/dev/null
}

finddir() {
    [[ $# -eq 0 ]] && { echo "Usage: finddir <dirname>"; return 1; }
    find . -type d -iname "*$1*" 2>/dev/null
}

fsize() {
    [[ $# -eq 0 ]] && { echo "Usage: fsize <file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
    if command -v du >/dev/null 2>&1; then
        du -h "$1" | cut -f1
    else
        ls -lh "$1" | awk '{print $5}'
    fi
}

backup() {
    [[ $# -eq 0 ]] && { echo "Usage: backup <file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
    local backup_name="${1}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$1" "$backup_name"
    echo "Backup created: $backup_name"
}

sysinfo() {
    echo "System Information:"
    echo "=================="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F', load' '{print $1}')"
    if [[ "${OSTYPE:-}" == darwin* ]]; then
        echo "macOS Version: $(sw_vers -productVersion)"
    elif [[ -f /etc/os-release ]]; then
        echo "Distribution: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    fi
}

dusk() {
    command -v du >/dev/null 2>&1 && du -sh * 2>/dev/null | sort -hr || { echo "du command not found"; return 1; }
}

pstree() {
    if command -v pstree >/dev/null 2>&1; then
        command pstree "$@"
    elif [[ "${OSTYPE:-}" == darwin* ]]; then
        ps -e -o pid,ppid,command | awk 'NR>1 {print $1, $2, substr($0, index($0,$3))}'
    else
        ps auxf
    fi
}

myip() {
    local ip service
    for service in ifconfig.me icanhazip.com ipecho.net/plain ifconfig.co; do
        ip=$(curl -s --max-time 5 "$service" 2>/dev/null)
        [[ -n "$ip" ]] && { echo "External IP: $ip"; return 0; }
    done
    echo "Unable to determine external IP"
    return 1
}

localip() {
    echo "Local IP addresses:"
    if [[ "${OSTYPE:-}" == darwin* ]]; then
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}'
    else
        ip addr show 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}' | cut -d'/' -f1
    fi
}

pingtest() {
    local host=${1:-google.com} count=${2:-4}
    echo "Pinging $host ($count times)..."
    ping -c "$count" "$host"
}

gitclean() {
    echo "Cleaning git repository..."
    git clean -fd && git reset --hard HEAD && git pull
    echo "Repository cleaned and updated"
}

gitcp() {
    [[ $# -eq 0 ]] && { echo "Usage: gitcp <commit_message>"; return 1; }
    git add -A && git commit -m "$*" && git push
}

gitbr() {
    [[ $# -eq 0 ]] && { echo "Usage: gitbr <branch_name>"; return 1; }
    git checkout -b "$1"
}

gitlog() {
    local count=${1:-10}
    git log --oneline --graph --decorate -n "$count"
}

dpshow() {
    command -v docker >/dev/null 2>&1 \
        && docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" \
        || { echo "Docker not found"; return 1; }
}

dclean() {
    if command -v docker >/dev/null 2>&1; then
        echo "Cleaning up Docker..."
        docker system prune -f && docker image prune -f
        echo "Docker cleanup completed"
    else
        echo "Docker not found"
        return 1
    fi
}

count() {
    [[ $# -eq 0 ]] && { echo "Usage: count <file1> [file2] ..."; return 1; }
    local file
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            echo "File: $file"
            wc -l -w -c "$file"
            echo
        else
            echo "Error: '$file' is not a valid file"
        fi
    done
}

replace() {
    [[ $# -lt 3 ]] && { echo "Usage: replace <search> <replace> <file...>"; return 1; }
    local search="$1" repl="$2"
    shift 2
    local file
    for file in "$@"; do
        [[ ! -f "$file" ]] && { echo "Error: '$file' is not a valid file"; continue; }
        if [[ "${OSTYPE:-}" == darwin* ]]; then
            sed -i '' "s/$search/$repl/g" "$file"
        else
            sed -i.bak "s/$search/$repl/g" "$file"
        fi
        echo "Replaced in: $file"
    done
}

weather() {
    local location=${1:-""}
    command -v curl >/dev/null 2>&1 \
        && curl -s "wttr.in/${location}?format=%C+%t+%h+%w" && echo \
        || { echo "curl not found"; return 1; }
}

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

urlencode() {
    [[ $# -eq 0 ]] && { echo "Usage: urlencode <string>"; return 1; }
    local string="$*" encoded="" char i hex
    for ((i = 0; i < ${#string}; i++)); do
        char="${string:$i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-]) encoded+="$char" ;;
            *) printf -v hex '%02X' "'$char"; encoded+="%$hex" ;;
        esac
    done
    echo "$encoded"
}

urldecode() {
    [[ $# -eq 0 ]] && { echo "Usage: urldecode <string>"; return 1; }
    printf '%b' "${*//%/\\x}"
}

topcpu() {
    local count=${1:-10}
    if [[ "${OSTYPE:-}" == darwin* ]]; then
        top -l 1 -o cpu | head -n $((count + 12))
    else
        ps aux --sort=-%cpu | head -n $((count + 1))
    fi
}

topmem() {
    local count=${1:-10}
    if [[ "${OSTYPE:-}" == darwin* ]]; then
        top -l 1 -o rsize | head -n $((count + 12))
    else
        ps aux --sort=-%mem | head -n $((count + 1))
    fi
}

timeit() {
    [[ $# -eq 0 ]] && { echo "Usage: timeit <command>"; return 1; }
    local start_time end_time duration exit_code
    start_time=$(date +%s.%N)
    "$@"
    exit_code=$?
    end_time=$(date +%s.%N)
    if command -v bc >/dev/null 2>&1; then
        duration=$(echo "$end_time - $start_time" | bc 2>/dev/null)
    else
        duration=$((${end_time%.*} - ${start_time%.*}))
    fi
    echo "Command executed in: ${duration}s (exit code: $exit_code)"
    return $exit_code
}

reload_functions() {
    unset DOTFILES_FUNCTIONS_LOADED
    source "${DOTFILES_LIB_DIR}/functions.sh"
    echo "Custom functions reloaded"
}

help() {
    cat <<'EOF'
Custom Shell Functions:
=======================

Directory:  mkcd, up, cdf, extract
Files:      findfile, finddir, fsize, backup
System:     sysinfo, dusk, pstree
Network:    myip, localip, pingtest
Git:        gitclean, gitcp, gitbr, gitlog
Docker:     dpshow, dclean
Text:       count, replace
Utilities:  weather, genpass, urlencode, urldecode
Performance: topcpu, topmem, timeit

Use 'help' to show this message again.
EOF
}