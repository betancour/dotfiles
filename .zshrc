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

vcs_prompt() {
  vcs_info
  if [[ -n $vcs_info_msg_0_ ]]; then
    local status_icon
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      status_icon="%B%F{#eb6f92}𝙭%f%b"  # Rose Pine Red (Love)
    else
      status_icon="%B%F{#31748f}✓%f%b"  # Rose Pine Green (Pine)
    fi
    echo " [%F{#9ccfd8}${vcs_info_msg_0_} $status_icon]"
  fi
}

PROMPT='%B%F{#ebbcba}$USER%b%f%F{#31748f}$(vcs_prompt)%f %F{#9ccfd8}➜%f '

[ -r "/etc/zshrc_$TERM_PROGRAM" ] && . "/etc/zshrc_$TERM_PROGRAM"

umask 022
