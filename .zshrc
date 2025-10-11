# .zshrc
# ======
# This file is sourced for interactive shells after .zshenv and .zprofile.
# It should contain interactive shell configuration like aliases, functions,
# key bindings, completion, and prompt setup.

# Performance monitoring (optional)
[[ -n "$ZSH_PROFILE_STARTUP" ]] && zmodload zsh/zprof

# Skip if not interactive
[[ $- != *i* ]] && return

# ZSH Options
# ===========
# History options
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record duplicate entries
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entries
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries to history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording
setopt HIST_VERIFY               # Show command with history expansion to user before running
setopt SHARE_HISTORY             # Share history between all sessions
setopt APPEND_HISTORY            # Append history to the history file (no overwriting)
setopt INC_APPEND_HISTORY        # Write to history file immediately, not when shell exits
setopt EXTENDED_HISTORY          # Write timestamps to history file

# Directory options
setopt AUTO_CD                   # Auto cd to directory without typing cd
setopt AUTO_PUSHD               # Push the old directory onto the stack on cd
setopt PUSHD_IGNORE_DUPS        # Don't push multiple copies of the same directory
setopt PUSHD_MINUS              # Make cd -n equivalent to cd +n
setopt CDABLE_VARS              # Change directory to a path stored in a variable

# Completion options
setopt AUTO_MENU                # Show completion menu on second tab
setopt ALWAYS_TO_END            # Move cursor to the end of word after completion
setopt COMPLETE_IN_WORD         # Allow completion from within a word/phrase
setopt GLOB_COMPLETE            # Generate matches for glob patterns
setopt HASH_LIST_ALL            # Hash entire path first for better performance
setopt LIST_AMBIGUOUS           # Show completions on ambiguous matches
setopt MENU_COMPLETE            # Insert first match immediately

# Globbing options
setopt EXTENDED_GLOB            # Use extended globbing syntax
setopt GLOB_DOTS                # Don't require leading dot in filename to be matched explicitly
setopt NUMERIC_GLOB_SORT        # Sort globs numerically when possible
setopt NOMATCH                  # Print error if pattern matches nothing

# Other useful options
setopt INTERACTIVE_COMMENTS     # Allow comments in interactive mode
setopt LONG_LIST_JOBS          # List jobs in the long format by default
setopt NOTIFY                  # Report status of background jobs immediately
setopt NO_BG_NICE              # Don't run all background jobs at a lower priority
setopt NO_HUP                  # Don't kill jobs on shell exit
setopt NO_CHECK_JOBS           # Don't report on jobs when shell exit

# Auto-start Zellij
# =================
# Automatically start Zellij when opening a new terminal session

auto_start_zellij() {
    # Only run for interactive login shells, not already in Zellij
    # Exclude Zed and other editors that spawn shell processes
    if [[ -o interactive ]] && [[ -o login ]] && [[ -z "$ZELLIJ" ]] && [[ "$SHLVL" -eq 1 ]]; then
        # Skip if running from Zed or other editors
        if [[ -n "$ZED" ]] || [[ -n "$VSCODE_PID" ]] || [[ -n "$TERM_PROGRAM" && "$TERM_PROGRAM" =~ "(vscode|zed)" ]]; then
            return
        fi
        # Skip if parent process is an editor or IDE
        local parent_cmd=$(ps -p $PPID -o comm= 2>/dev/null)
        if [[ "$parent_cmd" =~ "(zed|code|nvim|vim)" ]]; then
            return
        fi
        # Skip if TERM suggests we're in an editor's integrated terminal
        if [[ "$TERM" =~ "(dumb|unknown)" ]] || [[ -z "$TERM" ]]; then
            return
        fi

        if command -v zellij >/dev/null 2>&1; then
            exec zellij
        fi
    fi
}

# Auto-start Zellij if conditions are met
auto_start_zellij
setopt CORRECT                  # Try to correct spelling of commands
setopt CORRECT_ALL              # Try to correct spelling of all arguments
setopt NO_BEEP                  # Don't beep on errors
setopt NOTIFY                   # Report job status immediately
setopt PROMPT_SUBST             # Allow parameter expansion in prompts
setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shells
setopt LONG_LIST_JOBS           # List jobs in long format
setopt AUTO_RESUME              # Resume background jobs with single word commands
setopt NO_BG_NICE               # Don't nice background commands
setopt NO_HUP                   # Don't send HUP to background jobs when shell exits
setopt CHECK_JOBS               # Warn about background jobs before exiting

# Locale and encoding
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# Enable colors in terminal
case "$TERM" in
    xterm-color|*-256color|*-color) color_prompt=yes ;;
esac

# Initialize completion system
# ============================
autoload -U compinit
# Check if we need to rebuild completion dump
if [[ -n "$ZSH_COMPDUMP"(#qN.mh+24) ]]; then
    compinit -d "$ZSH_COMPDUMP"
else
    compinit -C -d "$ZSH_COMPDUMP"
fi

# Load additional completions
autoload -U bashcompinit && bashcompinit

# Completion configuration
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"

# Create completion cache directory
[[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] && mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Oh My Zsh Integration
# =====================
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"

    # Oh My Zsh settings
    CASE_SENSITIVE="false"
    HYPHEN_INSENSITIVE="true"
    DISABLE_AUTO_UPDATE="true"
    DISABLE_UPDATE_PROMPT="true"
    ENABLE_CORRECTION="true"
    COMPLETION_WAITING_DOTS="true"
    DISABLE_UNTRACKED_FILES_DIRTY="true"

    # Plugins
    plugins=(
        git
        zsh-autosuggestions
        zsh-syntax-highlighting
        docker
        kubectl
        brew
        macos
    )

    # Load Oh My Zsh
    source "$ZSH/oh-my-zsh.sh"
else
    # Manual plugin loading if Oh My Zsh is not installed

    # Load zsh-autosuggestions
    for plugin_path in \
        "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
        "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
        "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
        [[ -f "$plugin_path" ]] && source "$plugin_path" && break
    done

    # Load zsh-syntax-highlighting (must be last)
    for plugin_path in \
        "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
        "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
        "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
        [[ -f "$plugin_path" ]] && source "$plugin_path" && break
    done
fi

# Git and VCS Integration
# =======================
autoload -Uz vcs_info
setopt PROMPT_SUBST

# VCS info configuration
zstyle ':vcs_info:*' enable git svn hg
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git*' formats '%b%u%c'
zstyle ':vcs_info:git*' actionformats '%b|%a%u%c'

# Custom VCS prompt function
vcs_prompt() {
    vcs_info
    if [[ -n "$vcs_info_msg_0_" ]]; then
        # Git status symbols
        local clean_icon="✓"
        local dirty_icon="●"
        local staged_icon="+"
        local untracked_icon="?"

        # Colors
        local clean_color="%F{green}"
        local dirty_color="%F{red}"
        local staged_color="%F{yellow}"
        local branch_color="%F{cyan}"
        local bracket_color="%F{blue}"
        local reset="%f"

        # Get git status
        local git_status=""
        if git rev-parse --git-dir >/dev/null 2>&1; then
            local status_output=$(git status --porcelain 2>/dev/null)

            if [[ -n "$status_output" ]]; then
                # Check for different types of changes
                if echo "$status_output" | grep -q "^M\|^A\|^D\|^R\|^C"; then
                    git_status="${staged_color}${staged_icon}${reset}"
                fi
                if echo "$status_output" | grep -q "^ M\| D\|??"; then
                    git_status="${git_status}${dirty_color}${dirty_icon}${reset}"
                fi
                if echo "$status_output" | grep -q "^??"; then
                    git_status="${git_status}${dirty_color}${untracked_icon}${reset}"
                fi
            else
                git_status="${clean_color}${clean_icon}${reset}"
            fi
        fi

        echo "${bracket_color}[${branch_color}${vcs_info_msg_0_}${reset} ${git_status}${bracket_color}]${reset}"
    fi
}

# Prompt Configuration
# ===================
# Define colors
local user_color="%F{magenta}"
local host_color="%F{cyan}"
local path_color="%F{blue}"
local arrow_color="%F{green}"
local error_color="%F{red}"
local reset="%f"

# Two-line prompt with error status, user@host, path, git, and time
PROMPT='
${user_color}%n${reset}@${host_color}%m${reset} ${path_color}[%3~]${reset}$(vcs_prompt) ${path_color}[%D{%H:%M:%S}]${reset}
%(?.${arrow_color}.${error_color})❯${reset} '

# Right prompt with last command execution time
RPROMPT='%(?..${error_color}[%?]${reset})'

# Key Bindings
# ============
# Use emacs key bindings
bindkey -e

# Better history search
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "^P" up-line-or-beginning-search
bindkey "^N" down-line-or-beginning-search

# Better word movement
bindkey "^[[1;5C" forward-word      # Ctrl+Right
bindkey "^[[1;5D" backward-word     # Ctrl+Left
bindkey "^[[3~" delete-char         # Delete key
bindkey "^H" backward-delete-word   # Ctrl+Backspace

# Useful shortcuts
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward
bindkey "^Q" push-line-or-edit

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

    # Load FZF key bindings and completion
    for fzf_script in \
        "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" \
        "/usr/share/fzf/key-bindings.zsh" \
        "$HOME/.fzf.zsh"; do
        [[ -f "$fzf_script" ]] && source "$fzf_script" && break
    done

    for fzf_completion in \
        "/opt/homebrew/opt/fzf/shell/completion.zsh" \
        "/usr/share/fzf/completion.zsh"; do
        [[ -f "$fzf_completion" ]] && source "$fzf_completion" && break
    done
fi

# Zoxide initialization (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt (alternative to custom prompt)
# if command -v starship >/dev/null 2>&1; then
#     eval "$(starship init zsh)"
# fi

# NVM lazy loading (for better shell startup performance)
if [[ -d "$NVM_DIR" ]]; then
    # Lazy load NVM to improve shell startup time
    nvm() {
        unset -f nvm
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
        nvm "$@"
    }

    # Auto-load node if .nvmrc exists
    autoload -U add-zsh-hook
    load-nvmrc() {
        local node_version="$(nvm version)"
        local nvmrc_path="$(nvm_find_nvmrc)"

        if [[ -n "$nvmrc_path" ]]; then
            local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

            if [[ "$nvmrc_node_version" = "N/A" ]]; then
                nvm install
            elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
                nvm use
            fi
        elif [[ "$node_version" != "$(nvm version default)" ]]; then
            nvm use default
        fi
    }
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc
fi

# Kubectl completion
if [[ -n "$_KUBECTL_AVAILABLE" ]] && command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# Docker completion
if command -v docker >/dev/null 2>&1; then
    # Docker completion is usually handled by Oh My Zsh plugin or system package
    # Add manual completion here if needed
    :
fi

# Load aliases
# ============
[[ -f "${ZDOTDIR:-$HOME}/.zaliases" ]] && source "${ZDOTDIR:-$HOME}/.zaliases"

# Load functions
# ==============
[[ -f "${ZDOTDIR:-$HOME}/.zfunctions" ]] && source "${ZDOTDIR:-$HOME}/.zfunctions"

# Load local customizations
# =========================
[[ -f "${ZDOTDIR:-$HOME}/.zshrc.local" ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"

# Load system-specific configurations
[[ -r "/etc/zshrc_$TERM_PROGRAM" ]] && source "/etc/zshrc_$TERM_PROGRAM"

# Performance profiling end
[[ -n "$ZSH_PROFILE_STARTUP" ]] && zprof

# Final setup
# ===========
# Ensure proper terminal settings
stty -ixon  # Disable XON/XOFF flow control

# Welcome message for new shells (not login shells)
if [[ ! -o login ]] && [[ -t 1 ]]; then
    echo "Welcome back! Type 'help' for available commands."
fi
