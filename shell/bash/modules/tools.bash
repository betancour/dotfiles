# tools.bash — Bash-specific tool hooks (shared setup in lib/tools.sh)

. "${DOTFILES_LIB_DIR}/tools.sh"

# FZF key bindings
if command -v fzf >/dev/null 2>&1; then
    for _fzf in \
        /opt/homebrew/opt/fzf/shell/key-bindings.bash \
        /usr/share/fzf/key-bindings.bash \
        /usr/share/doc/fzf/examples/key-bindings.bash \
        "$HOME/.fzf.bash"
    do
        if [ -f "$_fzf" ]; then
            # shellcheck source=/dev/null
            . "$_fzf"
            break
        fi
    done
    unset _fzf
fi

# Zoxide / direnv / starship / kubectl — cached until the binary is newer
_dotfiles_eval_cached zoxide_init zoxide init bash || true
_dotfiles_eval_cached direnv_hook direnv hook bash || true
if [ "${TERM:-}" != dumb ]; then
    _dotfiles_eval_cached starship_init starship init bash || true
fi
if [ -n "${__KUBECTL_AVAILABLE:-}" ]; then
    _dotfiles_eval_cached kubectl_comp kubectl completion bash || true
fi

# NVM: load .nvmrc on cd (simple, no chpwd hooks in Bash)
if [ -n "${NVM_DIR:-}" ] && [ -d "$NVM_DIR" ]; then
    __dotfiles_check_nvmrc() {
        [ -f .nvmrc ] && command -v nvm >/dev/null 2>&1 && nvm use >/dev/null 2>&1 || true
    }
    cd() {
        builtin cd "$@" && __dotfiles_check_nvmrc
    }
fi

# GRC colorizer (first match only)
if is_macos; then
    if [ -s /opt/homebrew/etc/grc.bash ]; then
        . /opt/homebrew/etc/grc.bash
    elif [ -s /usr/local/etc/grc.bash ]; then
        . /usr/local/etc/grc.bash
    fi
elif is_linux; then
    [ -s /etc/grc.bash ] && . /etc/grc.bash
fi
