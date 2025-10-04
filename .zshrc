# System-wide profile for interactive zsh(1) shells.
# Setup user-specific overrides for this in ~/.zshrc.
# See zshbuiltins(1) and zshoptions(1) for more details.

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Correctly display UTF-8 with combining characters.
if [[ "$(locale LC_CTYPE)" == "UTF-8" ]]; then
    setopt COMBINING_CHARS
fi

# Disable the log builtin, so we don't conflict with /usr/bin/log.
disable log

# Save command history.
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=5000

# History options
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# Other useful options
setopt AUTO_CD
setopt CORRECT
setopt NO_BEEP

# Enable colors in terminal
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes ;;
esac

# Oh My Zsh setup (if installed)
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    source $ZSH/oh-my-zsh.sh
else
    # Manual plugin loading if Oh My Zsh is not installed
    # Load zsh-autosuggestions if available
    if [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi

    # Load zsh-syntax-highlighting if available
    if [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
        source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi
fi

# GIT and VCS setup
autoload -U compinit colors vcs_info
colors
compinit

setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '%b'

# VCS prompt configuration
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%b'

vcs_prompt() {
  vcs_info
  if [[ -n $vcs_info_msg_0_ ]]; then
    # Define customizable symbols and colors
    local clean_icon="✓"          # Symbol for clean repo
    local dirty_icon="●"          # Smaller, cleaner symbol for dirty repo
    local clean_color="%F{#4a8f00}"  # Green for clean
    local dirty_color="%F{#ff5555}"  # Softer red for dirty
    local branch_color="%F{#d4d4d4}" # Neutral gray for branch name
    local bracket_color="%F{#4a8f00}" # Green for brackets

    # Check Git status
    local status_icon
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      status_icon="${dirty_color}${dirty_icon}%f"
    else
      status_icon="${clean_color}${clean_icon}%f"
    fi

    # Output formatted prompt
    echo "${bracket_color}[${branch_color}${vcs_info_msg_0_} ${status_icon}${bracket_color}]%f"
  fi
}

# Define colors for consistency
local user_color="%F{#ff9500}"    # Orange for user
local path_color="%F{#d4d4d4}"    # Gray for path
local arrow_color="%F{#4a8f00}"   # Green for arrow
local reset_color="%f"

# Simplified prompt with a smaller arrow
PROMPT='${user_color}%n${reset_color} ${path_color}[%3~]${reset_color}$(vcs_prompt) ${arrow_color}❯${reset_color} '

# Load system-specific configurations
[ -r "/etc/zshrc_$TERM_PROGRAM" ] && . "/etc/zshrc_$TERM_PROGRAM"

# Set proper umask
umask 022

# Source aliases if available
[[ -f ~/.zaliases ]] && source ~/.zaliases

# Initialize zoxide if available
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Initialize fzf if available
if command -v fzf &> /dev/null; then
    # Set up fzf key bindings and fuzzy completion
    if [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    elif [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
        source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
        source /opt/homebrew/opt/fzf/shell/completion.zsh
    elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh
        source /usr/share/fzf/completion.zsh
    fi
fi

# Auto-completion enhancements
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
