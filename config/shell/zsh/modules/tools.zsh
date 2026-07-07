# tools.zsh — lazy-loaded and conditional tool initialization

source "${DOTFILES_LIB_DIR}/platform.sh"

# FZF
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
        /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
        /usr/share/fzf/key-bindings.zsh \
        "$HOME/.fzf.zsh"; do
        [[ -f "$fzf_script" ]] && source "$fzf_script" && break
    done

    for fzf_completion in \
        /opt/homebrew/opt/fzf/shell/completion.zsh \
        /usr/share/fzf/completion.zsh; do
        [[ -f "$fzf_completion" ]] && source "$fzf_completion" && break
    done
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# NVM lazy loading
if [[ -n "${NVM_DIR:-}" && -d "$NVM_DIR" ]]; then
    nvm() {
        unset -f nvm
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
        nvm "$@"
    }

    autoload -U add-zsh-hook
    load-nvmrc() {
        local node_version nvmrc_path nvmrc_node_version
        node_version="$(nvm version)"
        nvmrc_path="$(nvm_find_nvmrc)"
        if [[ -n "$nvmrc_path" ]]; then
            nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
            [[ "$nvmrc_node_version" == N/A ]] && nvm install
            [[ "$nvmrc_node_version" != "$node_version" ]] && nvm use
        elif [[ "$node_version" != "$(nvm version default)" ]]; then
            nvm use default
        fi
    }
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc
fi

# Mise lazy loading (preserved from live $HOME config)
if [[ -x "$HOME/.local/bin/mise" ]]; then
    mise() {
        unset -f mise
        eval "$("$HOME/.local/bin/mise" activate zsh)"
        mise "$@"
    }
fi

# Kubectl completion
if [[ -n "${__KUBECTL_AVAILABLE:-}" ]] && command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# GRC colorizer
if is_macos; then
    [[ -s /opt/homebrew/etc/grc.zsh ]] && source /opt/homebrew/etc/grc.zsh
    [[ -s /usr/local/etc/grc.zsh ]] && source /usr/local/etc/grc.zsh
elif is_linux; then
    [[ -s /etc/grc.zsh ]] && source /etc/grc.zsh
fi