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

# Zoxide / direnv / starship — cached until the binary is newer than the dump
_dotfiles_eval_cached zoxide_init zoxide init zsh || true
_dotfiles_eval_cached direnv_hook direnv hook zsh || true
# Starship refuses dumb terminals (scp, emacs, `zsh -c`); keep native prompt.
if [[ "${TERM:-}" != dumb ]]; then
    _dotfiles_eval_cached starship_init starship init zsh || true
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

# Kubectl completion (generated once; reused until kubectl is newer)
if [[ -n "${__KUBECTL_AVAILABLE:-}" ]]; then
    _dotfiles_eval_cached kubectl_comp kubectl completion zsh || true
fi

# GRC colorizer (first match only)
if is_macos; then
    if [[ -s /opt/homebrew/etc/grc.zsh ]]; then
        source /opt/homebrew/etc/grc.zsh
    elif [[ -s /usr/local/etc/grc.zsh ]]; then
        source /usr/local/etc/grc.zsh
    fi
elif is_linux; then
    [[ -s /etc/grc.zsh ]] && source /etc/grc.zsh
fi
