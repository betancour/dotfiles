# keybindings.zsh — Zsh key bindings (emacs mode)

bindkey -e

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^P'  up-line-or-beginning-search
bindkey '^N'  down-line-or-beginning-search

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~'   delete-char
bindkey '^H'      backward-delete-word

bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^Q' push-line-or-edit
