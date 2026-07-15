# tools.sh — POSIX sh tool aliases and lightweight integrations
# No Bash/Zsh arrays, process substitution, or [[ ]].

# --- aliases (with fallbacks) ---

# Directory navigation (zoxide if available)
if command -v zoxide >/dev/null 2>&1; then
    # zoxide supports a posix init that defines `z` (not a full cd hook).
    eval "$(zoxide init posix 2>/dev/null)" || true
fi

# Listing
if command -v eza >/dev/null 2>&1; then
    alias ls='eza -lh --group-directories-first --color=auto'
    alias ll='eza -l --group-directories-first --color=auto'
    alias la='eza -la --group-directories-first --color=auto'
elif command -v exa >/dev/null 2>&1; then
    alias ls='exa -lh --group-directories-first'
    alias ll='exa -l --group-directories-first'
    alias la='exa -la --group-directories-first'
else
    # Detect GNU vs BSD ls color flag (command ls avoids alias recursion).
    if command ls --color=auto / >/dev/null 2>&1; then
        alias ls='ls -lh --color=auto'
        alias ll='ls -l --color=auto'
        alias la='ls -la --color=auto'
    else
        alias ls='ls -lhG'
        alias ll='ls -lG'
        alias la='ls -laG'
    fi
fi

# bat / batcat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=auto'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
    alias cat='batcat --style=auto'
fi

# fd / fdfind
if ! command -v fd >/dev/null 2>&1; then
    if command -v fdfind >/dev/null 2>&1; then
        alias fd='fdfind'
    fi
fi

# ripgrep
if command -v rg >/dev/null 2>&1; then
    :
elif command -v ripgrep >/dev/null 2>&1; then
    alias rg='ripgrep'
fi

# FZF defaults (no key-bindings in pure sh)
if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    elif command -v fdfind >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    elif command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
    fi
    [ -n "${FZF_DEFAULT_COMMAND:-}" ] && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# direnv (hook when available)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook sh 2>/dev/null)" || true
fi

# Starship does not provide a dedicated posix init; keep a simple PS1.
case "$-" in
    *i*)
        if [ -n "${TERM:-}" ] && [ "$TERM" != "dumb" ]; then
            PS1='${USER:-u}@${HOSTNAME:-h}:$PWD\$ '
        else
            PS1='$ '
        fi
        export PS1
        ;;
esac

# Convenience
alias cls='clear'
alias reload='exec "${SHELL:-/bin/sh}" -l'
alias ..='cd ..'
alias ...='cd ../..'

# Git short aliases
alias g='git'
