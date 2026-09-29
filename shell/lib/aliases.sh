# aliases.sh — shared aliases with smart fallbacks
# Compatible with both Bash and Zsh. Prefer existence checks over OS forks.

if [ -n "${DOTFILES_ALIASES_LOADED:-}" ]; then
    return 0
fi
DOTFILES_ALIASES_LOADED=1

. "${DOTFILES_LIB_DIR}/platform.sh"

# Directory navigation
if command -v zoxide >/dev/null 2>&1; then
    alias cd='z'
    alias ..='z ..'
    alias ...='z ../..'
    alias ....='z ../../..'
else
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
fi

# File listing
if command -v eza >/dev/null 2>&1; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='eza -lha --group-directories-first --icons=auto'
    alias l='eza -G --group-directories-first --icons=auto'
    alias ll='eza -l --group-directories-first --icons=auto'
    alias la='eza -la --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --long --group-directories-first --icons=auto --git'
    alias lta='eza --tree --level=2 --long --group-directories-first --icons=auto --git -a'
else
    alias ls='ls -lh'
    alias lsa='ls -lha'
    alias l='ls'
    alias ll='ls -l'
    alias la='ls -la'
    if command -v tree >/dev/null 2>&1; then
        alias lt='tree -L 2'
        alias lta='tree -aL 2'
    else
        alias lt='find . -type d -maxdepth 2'
        alias lta='find . -maxdepth 2'
    fi
fi

# Search
if command -v rg >/dev/null 2>&1; then
    alias search='rg --files-with-matches'
elif command -v ripgrep >/dev/null 2>&1; then
    alias rg='ripgrep'
    alias search='ripgrep --files-with-matches'
else
    alias rg='grep -r'
    alias search='grep -r -l'
fi

if command -v fzf >/dev/null 2>&1; then
    if command -v bat >/dev/null 2>&1; then
        alias fzf_preview='fzf --preview "bat --style=numbers --line-range :500 {}"'
    else
        alias fzf_preview='fzf --preview "cat {}"'
    fi
fi

if command -v fd >/dev/null 2>&1; then
    :
elif command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi

# File viewing
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=auto'
    alias preview='bat --style=numbers'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
    alias cat='batcat --style=auto'
    alias preview='batcat --style=numbers'
fi

# General
alias python='python3'
alias cls='clear'
reload() { exec "${SHELL:-zsh}" -l; }
alias x='exit'
alias df='df -h'

# Networking
# Real wget keeps its own flags. The curl stand-in only covers `wget <url>`;
# passing wget options through `curl -O` applies them to the wrong tool.
if ! command -v wget >/dev/null 2>&1; then
    wget() {
        if [ "$#" -eq 1 ]; then
            curl -fL -O -- "$1"
        else
            printf '%s\n' "wget is not installed; only 'wget <url>' is emulated (curl -fL -O)." >&2
            return 127
        fi
    }
fi
alias ping='ping -c 5'

if is_macos; then
    alias ports='lsof -i -P -n'
else
    alias ports='netstat -tuln 2>/dev/null || ss -tuln'
fi

# Editor
if command -v nvim >/dev/null 2>&1; then
    alias vi='nvim'
    alias vim='nvim'
fi

# Development
alias g='git'
command -v docker >/dev/null 2>&1 && alias d='docker'
command -v lazygit >/dev/null 2>&1 && alias lzg='lazygit'
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'

alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Zellij
if command -v zellij >/dev/null 2>&1; then
    alias zls='zellij list-sessions'
    alias za='zellij attach'
    alias znew='zellij --session'
    if [ -f "${DOTFILES_DIR}/scripts/cleanup-zellij.sh" ]; then
        alias zclean="${DOTFILES_DIR}/scripts/cleanup-zellij.sh --clean"
    fi
fi

# Prefer Homebrew OpenSSH on Apple Silicon when present
if is_macos && [ -x /opt/homebrew/bin/ssh ]; then
    for _t in ssh ssh-keygen ssh-copy-id ssh-add ssh-agent scp sftp; do
        [ -x "/opt/homebrew/bin/$_t" ] && alias "$_t=/opt/homebrew/bin/$_t"
    done
    unset _t
fi
