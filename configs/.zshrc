ZSH_THEME="robbyrussell"

plugins=(git)

case $- in
    *i*) ;;
      *) return;;
esac

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

unset color_prompt force_color_prompt

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

<<<<<<< HEAD
=======

>>>>>>> origin/main
export PROMPT_DIRTRIM=4
umask 022
