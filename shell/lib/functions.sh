# functions.sh — shared shell functions (Bash/Zsh common dialect)
# Keep this focused: utilities used often, not a kitchen-sink library.

if [ -n "${DOTFILES_FUNCTIONS_LOADED:-}" ]; then
    return 0
fi
DOTFILES_FUNCTIONS_LOADED=1

# Editor shortcut
n() {
    if [ "$#" -eq 0 ]; then
        "${EDITOR:-vi}" .
    else
        "${EDITOR:-vi}" "$@"
    fi
}

mkcd() {
    [ "$#" -eq 0 ] && { echo "Usage: mkcd <directory>"; return 1; }
    mkdir -p "$1" && cd "$1" || return 1
}

up() {
    _levels=${1:-1}
    _path=
    _i=0
    while [ "$_i" -lt "$_levels" ]; do
        _path="../$_path"
        _i=$((_i + 1))
    done
    cd "$_path" || { unset _levels _path _i; return 1; }
    unset _levels _path _i
}

cdf() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf not found" >&2
        return 1
    fi
    _dir=$(find . -type d 2>/dev/null | fzf --height 40%)
    [ -n "$_dir" ] && cd "$_dir"
    unset _dir
}

extract() {
    [ "$#" -eq 0 ] && { echo "Usage: extract <archive>"; return 1; }
    [ -f "$1" ] || { echo "Error: '$1' is not a file" >&2; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz)         tar xJf "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.rar)            unrar x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.7z)             7z x "$1" ;;
        *.xz)             unxz "$1" ;;
        *) echo "Error: cannot extract '$1'" >&2; return 1 ;;
    esac
}

findfile() {
    [ "$#" -eq 0 ] && { echo "Usage: findfile <name>"; return 1; }
    find . -type f -iname "*$1*" 2>/dev/null
}

finddir() {
    [ "$#" -eq 0 ] && { echo "Usage: finddir <name>"; return 1; }
    find . -type d -iname "*$1*" 2>/dev/null
}

fsize() {
    [ "$#" -eq 0 ] && { echo "Usage: fsize <file>"; return 1; }
    [ -f "$1" ] || { echo "Error: '$1' is not a file" >&2; return 1; }
    du -h "$1" 2>/dev/null | cut -f1
}

backup() {
    [ "$#" -eq 0 ] && { echo "Usage: backup <file>"; return 1; }
    [ -f "$1" ] || { echo "Error: '$1' is not a file" >&2; return 1; }
    _bak="${1}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$1" "$_bak" && echo "Backup created: $_bak"
    unset _bak
}

sysinfo() {
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Arch: $(uname -m)"
    echo "Uptime: $(uptime | sed 's/.*up //; s/,.*//')"
    if is_macos 2>/dev/null || [ "$(uname -s)" = Darwin ]; then
        command -v sw_vers >/dev/null 2>&1 && echo "macOS: $(sw_vers -productVersion)"
    elif [ -f /etc/os-release ]; then
        echo "Distro: $(awk -F= '/^PRETTY_NAME=/ {gsub(/"/,""); print $2}' /etc/os-release)"
    fi
}

myip() {
    for _svc in https://ifconfig.me https://icanhazip.com https://ipecho.net/plain; do
        _ip=$(curl -fsS --proto '=https' --tlsv1.2 --max-time 5 "$_svc" 2>/dev/null) || true
        if [ -n "$_ip" ]; then
            echo "External IP: $_ip"
            unset _svc _ip
            return 0
        fi
    done
    echo "Unable to determine external IP" >&2
    unset _svc _ip
    return 1
}

localip() {
    echo "Local IP addresses:"
    if command -v ip >/dev/null 2>&1; then
        ip -4 addr show 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {print "  " $2}' | cut -d/ -f1
    else
        ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print "  " $2}'
    fi
}

gitcp() {
    [ "$#" -eq 0 ] && { echo "Usage: gitcp <message>"; return 1; }
    git add -A && git commit -m "$*" && git push
}

gitbr() {
    [ "$#" -eq 0 ] && { echo "Usage: gitbr <branch>"; return 1; }
    git checkout -b "$1"
}

gitlog() {
    git log --oneline --graph --decorate -n "${1:-10}"
}

dpshow() {
    command -v docker >/dev/null 2>&1 || { echo "Docker not found" >&2; return 1; }
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

dclean() {
    command -v docker >/dev/null 2>&1 || { echo "Docker not found" >&2; return 1; }
    docker system prune -f && docker image prune -f
}

genpass() {
    _len=${1:-16}
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 $((_len * 3 / 4 + 4)) | tr -d '\n' | cut -c1-"$_len"
        echo
    elif [ -r /dev/urandom ]; then
        LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$_len"
        echo
    else
        echo "Unable to generate password" >&2
        unset _len
        return 1
    fi
    unset _len
}

weather() {
    command -v curl >/dev/null 2>&1 || { echo "curl not found" >&2; return 1; }
    curl -fsS --proto '=https' --tlsv1.2 --max-time 10 \
        "https://wttr.in/${1:-}?format=%C+%t+%h+%w" && echo
}

help() {
    cat <<'EOF'
Custom shell functions:
  Directory  mkcd  up  cdf  extract
  Files      findfile  finddir  fsize  backup
  System     sysinfo  myip  localip
  Git        gitcp  gitbr  gitlog
  Docker     dpshow  dclean
  Utilities  genpass  weather

Type 'help' to show this again.
EOF
}
