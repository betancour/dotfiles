# .bash_aliases
# =============
# Comprehensive Bash aliases with smart fallbacks for modern CLI tools
# This file provides enhanced functionality while maintaining compatibility
# across different systems and tool availability.

# Directory navigation with zoxide (smarter cd) - with fallbacks
if command -v zoxide >/dev/null 2>&1; then
    alias z='zoxide'
    alias ..='z ..'
    alias ...='z ../..'
    alias ....='z ../../..'
    alias .....='z ../../../..'
else
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
fi

# File listing with eza (replaces ls) - with fallbacks
if command -v eza >/dev/null 2>&1; then
    alias ls='eza -lh --group-directories-first --icons=auto --color=always'
    alias lsa='eza -lha --group-directories-first --icons=auto --color=always'
    alias l='eza -G --color=always --group-directories-first'
    alias ll='eza -l --color=always --group-directories-first'
    alias la='eza -la --color=always --group-directories-first'
    alias lt='eza --tree --level=2 --long --icons=auto --git'
    alias lta='eza --tree --level=2 --long --icons=auto --git -a'
else
    # Fallback to standard ls with colors
    if ls --color=auto / >/dev/null 2>&1; then
        # GNU ls (Linux)
        alias ls='ls -lh --color=auto --group-directories-first'
        alias lsa='ls -lha --color=auto --group-directories-first'
        alias l='ls --color=auto --group-directories-first'
        alias ll='ls -l --color=auto --group-directories-first'
        alias la='ls -la --color=auto --group-directories-first'
    else
        # BSD ls (macOS)
        alias ls='ls -lhG'
        alias lsa='ls -lhaG'
        alias l='ls -G'
        alias ll='ls -lG'
        alias la='ls -laG'
    fi
    # Tree fallback
    if command -v tree >/dev/null 2>&1; then
        alias lt='tree -L 2'
        alias lta='tree -aL 2'
    else
        alias lt='find . -type d -maxdepth 2 | head -20'
        alias lta='find . -maxdepth 2 | head -20'
    fi
fi

# File searching and preview - with fallbacks
if command -v rg >/dev/null 2>&1; then
    alias search='rg --files-with-matches'
elif command -v ripgrep >/dev/null 2>&1; then
    alias rg='ripgrep --color=auto'
    alias search='ripgrep --files-with-matches'
else
    alias rg='grep -r --color=auto'
    alias search='grep -r -l'
fi

# FZF aliases with preview
if command -v fzf >/dev/null 2>&1; then
    if command -v bat >/dev/null 2>&1; then
        alias fzf_preview='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
        alias fzh='history | fzf'
    elif command -v batcat >/dev/null 2>&1; then
        alias fzf_preview='fzf --preview "batcat --style=numbers --color=always --line-range :500 {}"'
        alias fzh='history | fzf'
    else
        alias fzf_preview='fzf --preview "cat {}"'
        alias fzh='history | fzf'
    fi
fi

# Handle fd vs fdfind naming - use fdcmd to avoid conflict with functions
if command -v fd >/dev/null 2>&1; then
    alias fdcmd='fd'
elif command -v fdfind >/dev/null 2>&1; then
    alias fdcmd='fdfind'
else
    alias fdcmd='find . -name'
fi

# File viewing with bat (enhanced cat) - with fallbacks
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=auto'
    alias preview='bat --style=numbers --color=always'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
    alias cat='batcat --style=auto'
    alias preview='batcat --style=numbers --color=always'
else
    alias preview='cat'
fi

# General shell utilities
alias python='python3'
alias password="openssl rand -base64 32"
alias cls='clear'
alias reload="exec $SHELL -l"
alias x="exit"

# Memory and disk usage
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific
    alias free="vm_stat | awk '/Pages free/ {print \"Free: \" \$3*4096/1024/1024 \"MB\"}'"
    alias df='df -h'
    alias top='top -o cpu'
else
    # Linux specific
    alias free='free -h'
    alias df='df -h'
    alias top='top'
fi

# Networking tools
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias wget="curl -O"  # Use curl instead of wget on macOS
fi
alias ping="ping -c 5"  # Ping with 5 packets only
alias ports="netstat -tuln"  # Show open ports

# Network scanning
if command -v nmap >/dev/null 2>&1; then
    alias nmap-fast="nmap -T4 -F"  # Quick network scan
fi

# Editor (prefer nvim if installed)
if command -v nvim >/dev/null 2>&1; then
    alias vi='nvim'
    alias vim='nvim'
    n() { if [[ $# -eq 0 ]]; then nvim .; else nvim "$@"; fi; }
else
    n() { if [[ $# -eq 0 ]]; then vim .; else vim "$@"; fi; }
fi

# Development tools
alias g='git'
command -v docker >/dev/null 2>&1 && alias d='docker'
command -v rails >/dev/null 2>&1 && alias r='rails'
command -v lazygit >/dev/null 2>&1 && alias lzg='lazygit'
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'

# Git aliases
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias gst='git status'
alias gco='git checkout'
alias gb='git branch'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias ga='git add'
alias gaa='git add -A'

# Docker aliases (if Docker is available)
if command -v docker >/dev/null 2>&1; then
    alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
    alias dimg='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"'
    alias dex='docker exec -it'
    alias dlog='docker logs -f'
    alias dstop='docker stop $(docker ps -q)'
    alias drm='docker rm $(docker ps -aq)'
    alias drmi='docker rmi $(docker images -q)'
    alias dclean='docker system prune -af'
fi

# Kubernetes aliases (if kubectl is available)
if command -v kubectl >/dev/null 2>&1; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kdp='kubectl describe pod'
    alias kds='kubectl describe service'
    alias kdd='kubectl describe deployment'
    alias kaf='kubectl apply -f'
    alias kdf='kubectl delete -f'
fi

# Zellij session management (if both zellij and fzf are available)
if command -v zellij >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
    alias zj='zellij list-sessions | fzf | cut -d" " -f1 | xargs zellij attach'
    alias zjk='zellij kill-session $(zellij list-sessions | fzf | cut -d" " -f1)'
fi

# System monitoring
alias psg='ps aux | grep -v grep | grep'
alias h='history'
alias hg='history | grep'

# Archive extraction (if not using the extract function)
alias untar='tar -xvf'
alias untgz='tar -xzf'
alias unbz2='tar -xjf'

# Quick directory operations
alias mkdir='mkdir -p'
alias md='mkdir -p'
alias rd='rmdir'

# Safe file operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Process management
alias pstree='pstree -p' 2>/dev/null || alias pstree='ps auxf'
alias jobs='jobs -l'

# Text processing
if command -v grep >/dev/null 2>&1; then
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Directory listing shortcuts
alias dir='ls -la'
alias vdir='ls -la'

# Quick navigation
alias home='cd ~'
alias root='cd /'
alias dtop='cd ~/Desktop'
alias docs='cd ~/Documents'
alias down='cd ~/Downloads'

# System information
alias sysinfo='uname -a'
alias myip='curl -s ifconfig.me'
alias localip='hostname -I 2>/dev/null || ifconfig | grep "inet " | grep -v 127.0.0.1'

# Package management shortcuts
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS Homebrew
    if command -v brew >/dev/null 2>&1; then
        alias bup='brew update && brew upgrade'
        alias bsearch='brew search'
        alias binfo='brew info'
        alias blist='brew list'
        alias binstall='brew install'
        alias buninstall='brew uninstall'
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux package managers
    if command -v apt >/dev/null 2>&1; then
        alias apt-update='sudo apt update && sudo apt upgrade'
        alias apt-search='apt search'
        alias apt-install='sudo apt install'
        alias apt-remove='sudo apt remove'
        alias apt-list='apt list --installed'
    elif command -v yum >/dev/null 2>&1; then
        alias yum-update='sudo yum update'
        alias yum-search='yum search'
        alias yum-install='sudo yum install'
        alias yum-remove='sudo yum remove'
        alias yum-list='yum list installed'
    elif command -v pacman >/dev/null 2>&1; then
        alias pac-update='sudo pacman -Syu'
        alias pac-search='pacman -Ss'
        alias pac-install='sudo pacman -S'
        alias pac-remove='sudo pacman -R'
        alias pac-list='pacman -Q'
    fi
fi

# Web development shortcuts
if command -v python3 >/dev/null 2>&1; then
    alias serve='python3 -m http.server 8000'
elif command -v python >/dev/null 2>&1; then
    alias serve='python -m SimpleHTTPServer 8000'
fi

# JSON formatting
if command -v jq >/dev/null 2>&1; then
    alias json='jq .'
elif command -v python3 >/dev/null 2>&1; then
    alias json='python3 -m json.tool'
fi

# URL encoding/decoding
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'

# Base64 encoding/decoding
alias b64encode='base64'
alias b64decode='base64 -d'

# Weather (if curl is available)
if command -v curl >/dev/null 2>&1; then
    weather() { curl -s "wttr.in/${1:-}?format=%C+%t+%h+%w"; echo; }
fi

# Quick file finding
alias ff='find . -type f -name'
alias fd='find . -type d -name'

# Colorize output (if available)
if command -v grc >/dev/null 2>&1; then
    alias diff='grc diff'
    alias netstat='grc netstat'
    alias ping='grc ping'
    alias tail='grc tail'
    alias ps='grc ps'
fi

# EZA Environment Variable (if eza is available)
if command -v eza >/dev/null 2>&1; then
    export EZA_COLORS="di=38;5;110:hd=38;5;117;1:ex=38;5;73;1:fi=90:ln=38;5;117;4:or=38;5;167;4:*.txt=38;5;139:*.md=38;5;139;3:*.zip=38;5;117:*.jpg=38;5;117:*.png=38;5;117:uu=90:gu=90:da=90:sn=90:gm=38;5;107:gd=38;5;167:xx=90:lp=38;5;117;4:cc=90"
fi

# Load local aliases if they exist
[[ -f "$HOME/.bash_aliases.local" ]] && source "$HOME/.bash_aliases.local"

# Completion for aliases (if bash-completion is available)
if command -v complete >/dev/null 2>&1; then
    # Git aliases completion
    __git_complete gco _git_checkout
    __git_complete gb _git_branch
    __git_complete gd _git_diff
    __git_complete gp _git_push
    __git_complete gl _git_pull
    __git_complete ga _git_add
fi 2>/dev/null

# Performance tip: Use 'command' to bypass aliases when needed
# Example: \ls or command ls to use original ls command
