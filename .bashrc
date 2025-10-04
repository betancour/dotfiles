# .bashrc
# =======
# This file is sourced for interactive non-login shells.
# It should contain interactive shell configuration like aliases, functions,
# key bindings, completion, and prompt setup.

# Performance monitoring (optional)
[[ -n "$BASH_PROFILE_STARTUP" ]] && BASH_START_TIME=$(date +%s.%N)

# Skip if not interactive
case $- in
    *i*) ;;
    *) return ;;
esac

# Source environment variables
# ============================
[[ -f "$HOME/.bash_env" ]] && source "$HOME/.bash_env"

# Shell Options
# =============
# History options
shopt -s histappend              # Append to history file, don't overwrite
shopt -s histverify              # Verify history expansions
shopt -s histreedit              # Allow re-editing of failed history substitutions

# Directory options
shopt -s autocd                  # Auto cd to directory without typing cd (bash 4.0+)
shopt -s cdspell                 # Correct minor spelling errors in cd commands
shopt -s dirspell                # Correct minor spelling errors in directory names
shopt -s cdable_vars             # Change directory to a path stored in a variable

# Completion options
shopt -s no_empty_cmd_completion # Don't complete on empty line
shopt -s progcomp                # Enable programmable completion

# Globbing options
shopt -s extglob                 # Enable extended globbing
shopt -s globstar                # Enable ** for recursive globbing (bash 4.0+)
shopt -s nullglob                # Patterns that match nothing expand to nothing
shopt -s dotglob                 # Include dotfiles in pathname expansion

# Other useful options
shopt -s checkwinsize            # Update LINES and COLUMNS after each command
shopt -s cmdhist                 # Save multi-line commands in history as single line
shopt -s lithist                 # Save multi-line commands with embedded newlines
shopt -s checkjobs               # Print status of jobs before exiting

# History Configuration
# =====================
export HISTCONTROL="ignoreboth:erasedups"    # Ignore duplicates and commands starting with space
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help:history:clear"
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "
export PROMPT_DIRTRIM=3                      # Trim long paths in prompt to 3 directories

# Color Support Detection
# =======================
# Check for color support
case "$TERM" in
    xterm-color|*-256color|*-color) color_prompt=yes ;;
esac

# Force color prompt if available
if [[ -z "$color_prompt" ]]; then
    if [[ -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null 2>&1; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Enable colors for ls and other commands
if [[ "$color_prompt" == "yes" ]]; then
    # Enable colors in terminal
    export CLICOLOR=1

    # Set up LS_COLORS if not already set
    if [[ -z "$LS_COLORS" ]] && command -v dircolors >/dev/null 2>&1; then
        if [[ -r ~/.dircolors ]]; then
            eval "$(dircolors -b ~/.dircolors)"
        else
            eval "$(dircolors -b)"
        fi
    fi
fi

# Prompt Configuration
# ====================
# Git prompt function
__git_prompt() {
    local git_branch=""
    local git_status=""

    # Check if we're in a git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        # Get branch name
        git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

        if [[ -n "$git_branch" ]]; then
            # Check git status
            local git_dirty=""
            local git_staged=""
            local git_untracked=""

            # Check for changes
            if ! git diff --quiet 2>/dev/null; then
                git_dirty="*"
            fi

            # Check for staged changes
            if ! git diff --quiet --cached 2>/dev/null; then
                git_staged="+"
            fi

            # Check for untracked files
            if [[ -n $(git ls-files --other --exclude-standard 2>/dev/null) ]]; then
                git_untracked="?"
            fi

            git_status="${git_dirty}${git_staged}${git_untracked}"

            if [[ "$color_prompt" == "yes" ]]; then
                if [[ -n "$git_status" ]]; then
                    echo -e " \033[0;36m[\033[1;31m${git_branch}\033[0;33m${git_status}\033[0;36m]\033[0m"
                else
                    echo -e " \033[0;36m[\033[1;32m${git_branch}\033[0;36m]\033[0m"
                fi
            else
                echo " [${git_branch}${git_status}]"
            fi
        fi
    fi
}

# Command execution time function
__command_timer() {
    if [[ -n "$BASH_COMMAND_START_TIME" ]]; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $BASH_COMMAND_START_TIME" | bc 2>/dev/null || echo "0")
        unset BASH_COMMAND_START_TIME

        # Only show if command took more than 2 seconds
        if (( $(echo "$duration > 2.0" | bc -l 2>/dev/null || echo 0) )); then
            printf " \033[2m(%.2fs)\033[0m" "$duration"
        fi
    fi
}

# Pre-command hook to capture start time
__bash_preexec() {
    BASH_COMMAND_START_TIME=$(date +%s.%N)
}
trap '__bash_preexec' DEBUG

# Set up prompt
if [[ "$color_prompt" == "yes" ]]; then
    # Colorful prompt with Git integration
    PS1='\[\033[1;32m\]\u@\h\[\033[0m\] \[\033[1;34m\][\w]\[\033[0m\]$(__git_prompt) \[\033[1;33m\][\D{%H:%M:%S}]\[\033[0m\]\n\[\033[1;36m\]❯\[\033[0m\] '

    # Right prompt simulation (using PROMPT_COMMAND)
    PROMPT_COMMAND='__exit_status=$?; if [[ $__exit_status != 0 ]]; then printf "\033[1;31m[%s]\033[0m" "$__exit_status"; fi; __command_timer; printf "\n"'
else
    # Simple prompt without colors
    PS1='\u@\h [\w]$(__git_prompt) [\D{%H:%M:%S}]\n❯ '
    PROMPT_COMMAND='__exit_status=$?; if [[ $__exit_status != 0 ]]; then printf "[%s]" "$__exit_status"; fi; __command_timer; printf "\n"'
fi

# Terminal title
case "$TERM" in
    xterm*|rxvt*|screen*|tmux*)
        PS1="\[\e]0;\u@\h: \w\a\]$PS1"
        ;;
esac

# Debian chroot support
if [[ -z "${debian_chroot:-}" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
    PS1="(${debian_chroot})$PS1"
fi

# Bash Completion
# ===============
# Enable bash completion
if ! shopt -oq posix; then
    # Try different completion sources
    for completion_source in \
        "/opt/homebrew/etc/profile.d/bash_completion.sh" \
        "/usr/share/bash-completion/bash_completion" \
        "/etc/bash_completion" \
        "/usr/local/etc/bash_completion"; do
        [[ -f "$completion_source" ]] && source "$completion_source" && break
    done
fi

# Tool-specific completions
if command -v kubectl >/dev/null 2>&1 && [[ -n "$_KUBECTL_AVAILABLE" ]]; then
    source <(kubectl completion bash)
fi

if command -v docker >/dev/null 2>&1 && [[ -n "$_DOCKER_AVAILABLE" ]]; then
    # Docker completion is usually included in the package or completion files above
    :
fi

# Key Bindings
# ============
# Better history search
bind '"\e[A": history-search-backward'  # Up arrow
bind '"\e[B": history-search-forward'   # Down arrow
bind '"\eOA": history-search-backward'  # Up arrow (alternative)
bind '"\eOB": history-search-forward'   # Down arrow (alternative)

# Useful shortcuts
bind '"\C-l": clear-screen'              # Ctrl+L to clear screen
bind '"\C-w": backward-kill-word'        # Ctrl+W to delete word backwards
bind '"\C-u": backward-kill-line'        # Ctrl+U to delete line backwards

# Tool Initialization
# ===================

# FZF initialization
if command -v fzf >/dev/null 2>&1; then
    # Set FZF default command if fd or rg is available
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    elif command -v fdfind >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    elif command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Load FZF key bindings if available
    for fzf_script in \
        "/opt/homebrew/opt/fzf/shell/key-bindings.bash" \
        "/usr/share/fzf/key-bindings.bash" \
        "$HOME/.fzf.bash"; do
        [[ -f "$fzf_script" ]] && source "$fzf_script" && break
    done
fi

# Zoxide initialization (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# NVM lazy loading (for better shell startup performance)
if [[ -d "$NVM_DIR" ]]; then
    # Lazy load NVM to improve shell startup time
    nvm() {
        unset -f nvm
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
        nvm "$@"
    }

    # Auto-use node version if .nvmrc exists
    __check_nvmrc() {
        if [[ -f ".nvmrc" ]] && command -v nvm >/dev/null 2>&1; then
            nvm use 2>/dev/null || true
        fi
    }

    # Hook into directory changes
    __old_cd() {
        builtin cd "$@" && __check_nvmrc
    }
    alias cd=__old_cd
fi

# Lesspipe for better less functionality
if [[ -x /usr/bin/lesspipe ]]; then
    eval "$(SHELL=/bin/sh lesspipe)"
elif [[ -x /opt/homebrew/bin/lesspipe.sh ]]; then
    export LESSOPEN="|/opt/homebrew/bin/lesspipe.sh %s"
fi

# Load aliases and functions
# ==========================
[[ -f "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"
[[ -f "$HOME/.bash_functions" ]] && source "$HOME/.bash_functions"

# Load local customizations
# =========================
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"

# Load system-specific configurations
[[ -r "/etc/bashrc" ]] && source "/etc/bashrc"

# Performance profiling end
if [[ -n "$BASH_PROFILE_STARTUP" ]] && [[ -n "$BASH_START_TIME" ]]; then
    BASH_END_TIME=$(date +%s.%N)
    BASH_LOAD_TIME=$(echo "$BASH_END_TIME - $BASH_START_TIME" | bc 2>/dev/null || echo "unknown")
    echo "Bashrc loaded in: ${BASH_LOAD_TIME}s" >&2
    unset BASH_START_TIME BASH_END_TIME BASH_LOAD_TIME
fi

# Final setup
# ===========
# Welcome message for new shells (not login shells)
if [[ "$SHLVL" -eq 1 ]] && [[ ! -o login ]] && [[ -t 1 ]]; then
    echo "Welcome back! Type 'help' for available commands."
fi
