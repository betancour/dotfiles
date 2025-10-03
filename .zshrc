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
HISTSIZE=2000
SAVEHIST=1000

setopt BEEP

case "$TERM" in
  xterm-color|*-256color) color_prompt=yes ;;
esac
# Plugins

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# GIT
autoload -U compinit colors vcs_info
colors
compinit

setopt promptsubst

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
local user_color="%F{#ff9500}"    # Orange for user, kept from original
local path_color="%F{#d4d4d4}"    # Gray for path, matches vcs_prompt branch
local arrow_color="%F{#4a8f00}"   # Green for arrow, matches vcs_prompt brackets
local reset_color="%f"

# Simplified prompt with a smaller arrow
PROMPT='${user_color}%n${reset_color} ${path_color}[%3~]${reset_color}$(vcs_prompt) ${arrow_color}❯${reset_color} '

[ -r "/etc/zshrc_$TERM_PROGRAM" ] && . "/etc/zshrc_$TERM_PROGRAM"

umask 022
source ~/.zaliases
