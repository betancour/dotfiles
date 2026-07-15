# tools.zsh — Zsh-specific tool hooks (shared setup in lib/tools.sh)

source "${DOTFILES_LIB_DIR}/tools.sh"

# FZF key bindings + completion
if command -v fzf >/dev/null 2>&1; then
    for _fzf in \
        /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
        /usr/share/fzf/key-bindings.zsh \
        /usr/share/doc/fzf/examples/key-bindings.zsh \
        "$HOME/.fzf.zsh"
    do
        [[ -f "$_fzf" ]] && source "$_fzf" && break
    done
    for _fzf in \
        /opt/homebrew/opt/fzf/shell/completion.zsh \
        /usr/share/fzf/completion.zsh \
        /usr/share/doc/fzf/examples/completion.zsh
    do
        [[ -f "$_fzf" ]] && source "$_fzf" && break
    done
    unset _fzf
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# Starship prompt (optional; replaces modules/prompt.zsh when present)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# NVM: .nvmrc on directory change (Zsh chpwd hook)
if [[ -n "${NVM_DIR:-}" && -d "$NVM_DIR" ]]; then
    autoload -Uz add-zsh-hook
    _dotfiles_load_nvmrc() {
        [[ -f .nvmrc ]] || return 0
        # nvm is a lazy stub until first call
        nvm use >/dev/null 2>&1 || true
    }
    add-zsh-hook chpwd _dotfiles_load_nvmrc
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
