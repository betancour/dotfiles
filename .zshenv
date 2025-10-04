# .zshenv
# ========
# This file is ALWAYS sourced by zsh, for both interactive and non-interactive shells.
# It should contain environment variables that should be available to all processes.
# Keep this file lean and fast, as it affects startup time of all zsh instances.

# Locale Settings
# ===============
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# XDG Base Directory Specification
# =================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$USER}"

# Create XDG directories if they don't exist
[[ ! -d "$XDG_CONFIG_HOME" ]] && mkdir -p "$XDG_CONFIG_HOME"
[[ ! -d "$XDG_DATA_HOME" ]] && mkdir -p "$XDG_DATA_HOME"
[[ ! -d "$XDG_STATE_HOME" ]] && mkdir -p "$XDG_STATE_HOME"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"

# PATH Configuration
# ==================
# Use typeset -U to keep only unique entries and maintain order
typeset -U PATH path

# Initialize path array with system defaults
path=(
    # User binaries
    "$HOME/bin"
    "$HOME/.local/bin"

    # System paths (keep existing)
    $path
)

# macOS specific paths (Homebrew)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Apple Silicon Homebrew
    [[ -d "/opt/homebrew/bin" ]] && path=("/opt/homebrew/bin" $path)
    [[ -d "/opt/homebrew/sbin" ]] && path=("/opt/homebrew/sbin" $path)

    # Intel Homebrew (fallback)
    [[ -d "/usr/local/bin" ]] && path=("/usr/local/bin" $path)
    [[ -d "/usr/local/sbin" ]] && path=("/usr/local/sbin" $path)

    # Homebrew formula paths
    [[ -d "/opt/homebrew/opt/ruby/bin" ]] && path=("/opt/homebrew/opt/ruby/bin" $path)
    [[ -d "/opt/homebrew/opt/python@3.11/bin" ]] && path=("/opt/homebrew/opt/python@3.11/bin" $path)
    [[ -d "/opt/homebrew/opt/openjdk/bin" ]] && path=("/opt/homebrew/opt/openjdk/bin" $path)
    [[ -d "/opt/homebrew/opt/gnu-sed/libexec/gnubin" ]] && path=("/opt/homebrew/opt/gnu-sed/libexec/gnubin" $path)
    [[ -d "/opt/homebrew/opt/grep/libexec/gnubin" ]] && path=("/opt/homebrew/opt/grep/libexec/gnubin" $path)
fi

# Linux specific paths
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    [[ -d "/usr/local/bin" ]] && path=("/usr/local/bin" $path)
    [[ -d "/usr/local/sbin" ]] && path=("/usr/local/sbin" $path)
    [[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
fi

# Development tool paths
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
[[ -d "$HOME/go/bin" ]] && path=("$HOME/go/bin" $path)
[[ -d "$HOME/.npm-global/bin" ]] && path=("$HOME/.npm-global/bin" $path)

# Export the PATH
export PATH

# Editor and Pager
# ================
# Set preferred editor (check for availability)
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="vi"
    export VISUAL="vi"
fi

export PAGER="less"
export MANPAGER="less -X" # Don't clear screen after quitting man

# Less configuration
export LESS="-R -F -X -M -i -J --tabs=4"
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
[[ ! -d "${XDG_STATE_HOME}/less" ]] && mkdir -p "${XDG_STATE_HOME}/less"

# History Configuration
# =====================
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
export HISTSIZE=50000
export SAVEHIST=50000

# Create history directory
[[ ! -d "${XDG_STATE_HOME}/zsh" ]] && mkdir -p "${XDG_STATE_HOME}/zsh"

# Compilation flags
# =================
export ARCHFLAGS="-arch $(uname -m)"

# Tool-specific Environment Variables
# ===================================

# FZF Configuration
export FZF_DEFAULT_OPTS="
    --height=50%
    --layout=reverse
    --border
    --inline-info
    --color=dark
    --color=fg:-1,bg:-1,hl:#5fff87,fg+:-1,bg+:-1,hl+:#ffaf5f
    --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7
    --bind='ctrl-u:page-up,ctrl-d:page-down'
"

# Ripgrep configuration
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"

# Bat (cat replacement) configuration
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}/bat/config"

# GPG configuration
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"

# Docker configuration
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"

# Wget configuration
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"

# Ruby gems
export GEM_HOME="${XDG_DATA_HOME}/gem"
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"

# Node.js
export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node_repl_history"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"

# Python
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"
export PYTHONUSERBASE="${XDG_DATA_HOME}/python"

# Rust
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"

# Go
export GOPATH="${XDG_DATA_HOME}/go"
export GOCACHE="${XDG_CACHE_HOME}/go-build"

# Platform-specific Environment Variables
# ========================================

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Enable colors in terminal
    export CLICOLOR=1
    export LSCOLORS="GxFxCxDxBxegedabagaced"

    # Homebrew
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_BAT=1
    export HOMEBREW_PREFIX="/opt/homebrew"

    # Disable macOS session restore for Terminal
    export SHELL_SESSION_HISTORY=0
fi

# Linux specific
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43"
fi

# Security
# ========
# Don't add duplicate entries to history from concurrent sessions
export HIST_EXPIRE_DUPS_FIRST=1

# Umask - Default file permissions (owner: rw-, group: r--, other: r--)
umask 022

# Load local environment variables if they exist
# ==============================================
[[ -r "${ZDOTDIR:-$HOME}/.zshenv.local" ]] && source "${ZDOTDIR:-$HOME}/.zshenv.local"
