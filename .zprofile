# .zprofile
# =========
# This file is sourced by login shells after .zshenv but before .zshrc.
# It should contain commands that should be run once when logging in.
# This is similar to .bash_profile in bash.

# Only proceed if this is an interactive login shell
[[ -o login && -o interactive ]] || return

# Source Homebrew environment if available (macOS)
# =================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Apple Silicon Homebrew
    if [[ -x "/opt/homebrew/bin/brew" && ! "$PATH" == */opt/homebrew/bin* ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    # Intel Homebrew (fallback)
    elif [[ -x "/usr/local/bin/brew" && ! "$PATH" == */usr/local/bin* ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# SSH Agent Setup
# ===============
# Start SSH agent if not already running and we have SSH keys
if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -d "$HOME/.ssh" ]]; then
    # Check if we have any SSH keys
    if ls "$HOME/.ssh"/id_* >/dev/null 2>&1 || ls "$HOME/.ssh"/*_rsa >/dev/null 2>&1; then
        # Start ssh-agent and set environment variables
        eval "$(ssh-agent -s)" >/dev/null 2>&1

        # Add SSH keys to agent
        ssh-add -q "$HOME/.ssh"/id_* "$HOME/.ssh"/*_rsa 2>/dev/null || true

        # Export the agent info for other shells
        if [[ -n "$SSH_AGENT_PID" ]]; then
            echo "export SSH_AUTH_SOCK='$SSH_AUTH_SOCK'" > "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env"
            echo "export SSH_AGENT_PID='$SSH_AGENT_PID'" >> "${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.env"
        fi
    fi
fi

# GPG Agent Setup
# ===============
if command -v gpgconf >/dev/null 2>&1; then
    # Start GPG agent if not already running
    if ! pgrep -x -u "${USER}" gpg-agent >/dev/null 2>&1; then
        gpgconf --launch gpg-agent 2>/dev/null || true
    fi

    # Set GPG_TTY for proper terminal interaction
    export GPG_TTY="$(tty)"
fi

# Java Environment Setup
# ======================
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS Java setup
    if [[ -d "/opt/homebrew/opt/openjdk" ]]; then
        export JAVA_HOME="/opt/homebrew/opt/openjdk"
    elif [[ -d "/Library/Java/JavaVirtualMachines" ]]; then
        # Use the latest installed JDK
        JAVA_HOME="$(/usr/libexec/java_home -v 11+ 2>/dev/null)" && export JAVA_HOME
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux Java setup
    if [[ -d "/usr/lib/jvm/default-java" ]]; then
        export JAVA_HOME="/usr/lib/jvm/default-java"
    elif [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
    fi
fi

# Python Environment Setup
# =========================
# Virtual environment management
if [[ -f "$HOME/.pyenv/bin/pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Node.js Environment Setup
# ==========================
# Node Version Manager (if installed)
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    # Don't load nvm here (too slow), just set the directory
    # It will be loaded on-demand in .zshrc
fi

# Ruby Environment Setup
# ======================
# rbenv (Ruby version manager)
if [[ -d "$HOME/.rbenv" ]]; then
    PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init - --no-rehash)"
fi

# Rust Environment Setup
# ======================
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# Go Environment Setup
# ====================
if command -v go >/dev/null 2>&1; then
    export GOROOT="$(go env GOROOT)"
    # GOPATH is already set in .zshenv
fi

# macOS Specific Login Setup
# ===========================
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Set up proper dock and finder behavior for terminal sessions
    # This ensures GUI applications launched from terminal inherit proper environment

    # Update launchd environment
    if command -v launchctl >/dev/null 2>&1; then
        launchctl setenv PATH "$PATH" 2>/dev/null || true
        launchctl setenv EDITOR "$EDITOR" 2>/dev/null || true
        launchctl setenv LANG "$LANG" 2>/dev/null || true
    fi

    # Set up proper terminal integration
    if [[ -n "$TERM_PROGRAM" ]]; then
        case "$TERM_PROGRAM" in
            "Apple_Terminal")
                # Terminal.app specific setup
                [[ -r "/etc/zshrc_$TERM_PROGRAM" ]] && source "/etc/zshrc_$TERM_PROGRAM"
                ;;
            "iTerm.app")
                # iTerm2 specific setup
                export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
                ;;
        esac
    fi
fi

# Linux Specific Login Setup
# ===========================
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Setup systemd user environment
    if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
        systemctl --user import-environment PATH EDITOR LANG 2>/dev/null || true
    fi

    # Setup dbus session
    if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]] && command -v dbus-launch >/dev/null 2>&1; then
        eval "$(dbus-launch --sh-syntax --exit-with-session)" 2>/dev/null || true
    fi
fi

# Development Environment Initialization
# =======================================
# Initialize development tools that need to run once per login

# Docker completion (if installed)
if [[ -d "/Applications/Docker.app" ]] && [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS Docker Desktop
    [[ -r "/Applications/Docker.app/Contents/Resources/etc/docker.zsh-completion" ]] && \
        fpath+="/Applications/Docker.app/Contents/Resources/etc"
fi

# Kubectl completion setup (will be loaded in .zshrc)
if command -v kubectl >/dev/null 2>&1; then
    # Just mark that kubectl is available; completion will be set up in .zshrc
    export _KUBECTL_AVAILABLE=1
fi

# Performance Monitoring
# ======================
# Set up any performance monitoring or profiling tools for login shells

# Log login time for performance monitoring (optional)
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
    echo "$(date): .zprofile completed" >> "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/startup.log"
fi

# Load local profile customizations
# ==================================
[[ -r "${ZDOTDIR:-$HOME}/.zprofile.local" ]] && source "${ZDOTDIR:-$HOME}/.zprofile.local"

# Final PATH export after all modifications
export PATH
