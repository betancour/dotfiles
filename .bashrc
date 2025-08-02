# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
shopt -s histappend              # Append to history file, don't overwrite
export HISTCONTROL=ignoreboth    # Ignore duplicates and commands starting with space
export HISTSIZE=1000             # Number of commands to remember in memory
export HISTFILESIZE=2000         # Number of commands to save in history file
export HISTTIMEFORMAT="%d/%m/%y %T "  # Timestamp format for history

# Shell options
shopt -s checkwinsize            # Update window size after each command
shopt -s globstar                # Enable ** for recursive globbing
export PROMPT_DIRTRIM=4          # Trim long paths in prompt to 4 directories
umask 022                        # Default file permissions

# Debian chroot setup
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Lesspipe setup for better less command functionality
if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
fi

# Color prompt setup
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Custom prompt configuration
__bash_prompt() {
    local exit_code=$?
    local userpart="\[\033[0;32m\]\u"
    [ -n "${GITHUB_USER}" ] && userpart="\[\033[0;32m\]@${GITHUB_USER}"
    
    local status_indicator="\[\033[0m\]>"
    [ $exit_code -ne 0 ] && status_indicator="\[\033[1;31m\]>"
    
    local gitbranch=""
    if command -v git >/dev/null 2>&1 && [ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --always 2>/dev/null)
        if [ -n "$branch" ]; then
            gitbranch="\[\033[0;36m\](\[\033[1;31m\]$branch"
            if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                gitbranch="$gitbranch \[\033[1;33m\]x"
            fi
            gitbranch="$gitbranch\[\033[0;36m\])"
        fi
    fi
    
    local lightblue='\[\033[1;34m\]'
    local removecolor='\[\033[0m\]'
    
    PS1="${debian_chroot:+($debian_chroot)}${userpart} ${lightblue}\w ${gitbranch}${status_indicator} ${removecolor}"
}
__bash_prompt
unset -f __bash_prompt

# Terminal title setup
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

# Source bash aliases if they exist
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Common environment variables
export EDITOR=vim
export VISUAL=vim
export LS_COLORS='di=1;34:ln=1;36:pi=40;33:so=1;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=1;32'

# Add user bin directory to PATH if it exists
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi