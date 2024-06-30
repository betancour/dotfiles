export ZSH="$HOME/.oh-my-zsh"

export PATH="$HOME/bin:/usr/local/bin:$PATH"

ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

case "$TERM" in
  xterm-color|*-256color) color_prompt=yes ;;
esac

source "$ZSH/oh-my-zsh.sh"

export PROMPT_DIRTRIM=4

export LANG=en_US.UTF-8

umask 022

if [ -f "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
fi

if [[ ! $TERM =~ screen ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi

