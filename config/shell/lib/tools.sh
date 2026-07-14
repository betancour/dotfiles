# tools.sh — shared tool environment (shell-agnostic parts)
# Shell-specific init (zoxide/fzf/mise shell hooks) lives in bash|zsh modules.

[ -n "${DOTFILES_TOOLS_LOADED:-}" ] && return 0
DOTFILES_TOOLS_LOADED=1

. "${DOTFILES_LIB_DIR}/platform.sh"

# FZF default commands (shared; key-bindings sourced per-shell)
if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    elif command -v fdfind >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    elif command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
    fi
    [ -n "${FZF_DEFAULT_COMMAND:-}" ] && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# lesspipe for binary-friendly less
if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
elif [ -x /opt/homebrew/bin/lesspipe.sh ]; then
    export LESSOPEN='|/opt/homebrew/bin/lesspipe.sh %s'
fi

# NVM lazy stub (shell-agnostic function; real shell completion loaded on first use)
if [ -n "${NVM_DIR:-}" ] && [ -d "$NVM_DIR" ]; then
    nvm() {
        unset -f nvm
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi

# Mise lazy stub — shell name taken from DOTFILES_SHELL
if [ -x "$HOME/.local/bin/mise" ]; then
    mise() {
        unset -f mise
        eval "$("$HOME/.local/bin/mise" activate "${DOTFILES_SHELL:-bash}")"
        mise "$@"
    }
fi
