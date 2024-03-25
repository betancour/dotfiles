export ZSH=$HOME/.oh-my-zsh
export PATH=$HOME/bin:/usr/local/bin:$PATH

ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
case $- in
*i*) ;;
*) return ;;
esac
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
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
source $ZSH/oh-my-zsh.sh
export PROMPT_DIRTRIM=4
export LANG=en_US.UTF-8
umask 022
