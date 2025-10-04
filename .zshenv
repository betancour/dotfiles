# Environment variables for ZSH
# This file is sourced by all zsh sessions

# Locale settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Enable colors in terminal
export CLICOLOR=1

# OS-specific color settings
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux color settings
    export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS color settings
    export LSCOLORS="GxFxCxDxBxegedabagaced"
fi

# PATH configuration - build PATH incrementally to avoid duplicates
typeset -U PATH  # Keep unique entries only

# Add common directories to PATH if they exist
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "/usr/local/bin" ]] && PATH="/usr/local/bin:$PATH"

# macOS Homebrew paths
[[ -d "/opt/homebrew/bin" ]] && PATH="/opt/homebrew/bin:$PATH"
[[ -d "/opt/homebrew/sbin" ]] && PATH="/opt/homebrew/sbin:$PATH"
[[ -d "/opt/homebrew/opt/ruby/bin" ]] && PATH="/opt/homebrew/opt/ruby/bin:$PATH"
[[ -d "/opt/homebrew/opt/openjdk/bin" ]] && PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

export PATH

# Other environment variables
export ZSH_COMPDUMP="$HOME/.cache/zcompdump"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"

# Create cache directory if it doesn't exist
[[ ! -d "$HOME/.cache" ]] && mkdir -p "$HOME/.cache"

# History configuration
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=5000

# FZF configuration
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git 2>/dev/null || find . -type f -not -path '*/\.git/*' 2>/dev/null"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Less configuration for better paging
export LESS="-R -F -X"
export LESSHISTFILE="-"
