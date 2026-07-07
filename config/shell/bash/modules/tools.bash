# tools.bash — lazy-loaded and conditional tool initialization

source "${DOTFILES_LIB_DIR}/platform.sh"

if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    elif command -v fdfind >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    elif command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

    for fzf_script in \
        /opt/homebrew/opt/fzf/shell/key-bindings.bash \
        /usr/share/fzf/key-bindings.bash \
        "$HOME/.fzf.bash"; do
        [[ -f "$fzf_script" ]] && source "$fzf_script" && break
    done
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

if [[ -n "${NVM_DIR:-}" && -d "$NVM_DIR" ]]; then
    nvm() {
        unset -f nvm
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
        nvm "$@"
    }

    __check_nvmrc() {
        [[ -f .nvmrc ]] && command -v nvm >/dev/null 2>&1 && nvm use 2>/dev/null
    }
    __zoxide_cd="$(declare -f cd 2>/dev/null || true)"
    cd() { builtin cd "$@" && __check_nvmrc; }
fi

if [[ -x "$HOME/.local/bin/mise" ]]; then
    mise() {
        unset -f mise
        eval "$("$HOME/.local/bin/mise" activate bash)"
        mise "$@"
    }
fi

if [[ -x /usr/bin/lesspipe ]]; then
    eval "$(SHELL=/bin/sh lesspipe)"
elif [[ -x /opt/homebrew/bin/lesspipe.sh ]]; then
    export LESSOPEN='|/opt/homebrew/bin/lesspipe.sh %s'
fi

if is_macos; then
    [[ -s /opt/homebrew/etc/grc.bash ]] && source /opt/homebrew/etc/grc.bash
    [[ -s /usr/local/etc/grc.bash ]] && source /usr/local/etc/grc.bash
elif is_linux; then
    [[ -s /etc/grc.bash ]] && source /etc/grc.bash
fi