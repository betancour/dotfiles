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

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
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

# GRC colorizer
if is_macos; then
    [ -s /opt/homebrew/etc/grc.bash ] && . /opt/homebrew/etc/grc.bash
    [ -s /usr/local/etc/grc.bash ] && . /usr/local/etc/grc.bash
elif is_linux; then
    [ -s /etc/grc.bash ] && . /etc/grc.bash
fi
