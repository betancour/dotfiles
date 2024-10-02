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
      status_icon="%B%F{#C40000}𝙭%f%b"
    else
      status_icon="%B%F{#00C400}✓%f%b"
    fi
    echo " [%F{#4E4EDC}${vcs_info_msg_0_} $status_icon]"
  fi
}

PROMPT='%B%F{#4E4E4E}$USER%b%f$(vcs_prompt) ➜ '

[ -r "/etc/zshrc_$TERM_PROGRAM" ] && . "/etc/zshrc_$TERM_PROGRAM"

umask 022
