# aliases.sh — shared aliases with smart fallbacks (POSIX-compatible)

if [[ -n "${DOTFILES_ALIASES_LOADED:-}" ]]; then
    if alias g >/dev/null 2>&1; then
        return 0
    fi
    unset DOTFILES_ALIASES_LOADED
fi
DOTFILES_ALIASES_LOADED=1

source "${DOTFILES_LIB_DIR}/platform.sh"

# Directory navigation with zoxide
if command -v zoxide >/dev/null 2>&1; then
    alias cd='z'
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

# File listing with eza
if command -v eza >/dev/null 2>&1; then
    alias ls='eza -lh --group-directories-first --icons=auto --color=always'
    alias lsa='eza -lha --group-directories-first --icons=auto --color=always'
    alias l='eza -G --color=always --group-directories-first'
    alias ll='eza -l --color=always --group-directories-first'
    alias la='eza -la --color=always --group-directories-first'
    alias lt='eza --tree --level=2 --long --icons=auto --git'
    alias lta='eza --tree --level=2 --long --icons=auto --git -a'
else
    if ls --color=auto / >/dev/null 2>&1; then
        alias ls='ls -lh --color=auto --group-directories-first'
        alias lsa='ls -lha --color=auto --group-directories-first'
        alias l='ls --color=auto --group-directories-first'
        alias ll='ls -l --color=auto --group-directories-first'
        alias la='ls -la --color=auto --group-directories-first'
    else
        alias ls='ls -lhG'
        alias lsa='ls -lhaG'
        alias l='ls -G'
        alias ll='ls -lG'
        alias la='ls -laG'
    fi
    if command -v tree >/dev/null 2>&1; then
        alias lt='tree -L 2'
        alias lta='tree -aL 2'
    else
        alias lt='find . -type d -maxdepth 2 | head -20'
        alias lta='find . -maxdepth 2 | head -20'
    fi
fi

# Search
if command -v rg >/dev/null 2>&1; then
    alias search='rg --files-with-matches'
elif command -v ripgrep >/dev/null 2>&1; then
    alias rg='ripgrep --color=auto'
    alias search='ripgrep --files-with-matches'
else
    alias rg='grep -r --color=auto'
    alias search='grep -r -l'
fi

if command -v fzf >/dev/null 2>&1; then
    if command -v bat >/dev/null 2>&1; then
        alias fzf_preview='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
    else
        alias fzf_preview='fzf --preview "cat {}"'
    fi
    alias fzh='history | fzf'
fi

if command -v fd >/dev/null 2>&1; then
    alias fdcmd='fd'
elif command -v fdfind >/dev/null 2>&1; then
    alias fdcmd='fdfind'
else
    alias fdcmd='find . -name'
fi

# File viewing with bat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=auto'
    alias preview='bat --style=numbers --color=always'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
    alias cat='batcat --style=auto'
    alias preview='batcat --style=numbers --color=always'
fi

# General utilities
alias python='python3'
alias password='openssl rand -base64 32'
alias cls='clear'
alias reload="exec ${SHELL:-$0} -l"
alias x='exit'
alias df='df -h'

if is_macos; then
    alias free='vm_stat | awk '\''/Pages free/ {print "Free: " $3*4096/1024/1024 "MB"}'\'''
fi

# Networking
alias wget='curl -O'
alias ping='ping -c 5'
alias nmap-fast='nmap -T4 -F'
if is_macos; then
    alias ports='lsof -i -P -n'
else
    alias ports='netstat -tuln'
fi

# Editor
if command -v nvim >/dev/null 2>&1; then
    alias vi='nvim'
    alias vim='nvim'
else
    :
fi

# Development tools
alias g='git'
command -v docker >/dev/null 2>&1 && alias d='docker'
command -v rails >/dev/null 2>&1 && alias r='rails'
command -v lazygit >/dev/null 2>&1 && alias lzg='lazygit'
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'

# Git shortcuts
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Zellij session management
if command -v zellij >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
    alias zj='zellij list-sessions | fzf | cut -d" " -f1 | xargs zellij attach'
    alias zjk='zellij kill-session $(zellij list-sessions | fzf | cut -d" " -f1)'
fi
alias zls='zellij list-sessions'
alias za='zellij attach'
alias znew='zellij --session'

if [[ -f "${DOTFILES_DIR}/scripts/cleanup-zellij.sh" ]]; then
    alias zclean="${DOTFILES_DIR}/scripts/cleanup-zellij.sh --clean"
fi

# SSH tools — prefer Homebrew versions on macOS
if is_macos && [[ -d /opt/homebrew/bin ]]; then
    for _ssh_tool in ssh ssh-keygen ssh-copy-id ssh-add ssh-agent scp sftp; do
        [[ -x "/opt/homebrew/bin/${_ssh_tool}" ]] && alias "${_ssh_tool}=/opt/homebrew/bin/${_ssh_tool}"
    done
    unset _ssh_tool
fi