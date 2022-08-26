# Handy search for content
alias gg='grep -ril --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.git --exclude-dir=.idea'

# Autocompletion if it's available

[[ $PS1 && -f /usr/share/bash-completion/bash-completion ]] && \
  . /usr/share/bash-completion/bash_completion

# Handy Aliases
alias basheng='LANG=en_US.UTF-8 bash'
unalias -a
alias vim='vim'
alias free='free -h'
alias df='df -h'
alias top='htop'
alias sl="sl -e"
alias x="exit"
alias ls="ls --color=auto"
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cls='colorls --dark'
# Create an "Alert" for long running commands. Use like so: 'sleep 10; alert'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal ||
  echo error)" "$(history\tail -n1|sed -e
  '\''s/^\s*[0-9]\+\s*//;s[;&|]\s*alerts$//'\'')"'

# VI to VIM
which vim &>/dev/null && alias vi=vim

# Add cuda paths
export PATH=${PATH}:/usr/local/cuda/bin;
