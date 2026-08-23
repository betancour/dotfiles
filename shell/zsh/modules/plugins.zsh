# plugins.zsh — autosuggestions + syntax highlighting
# Prefer standalone plugins (Homebrew / system / ~/.zsh / OMZ custom).
# The Oh My Zsh *framework* re-runs compinit, audits fpath, greps the dump,
# zrecompiles, and checks for upgrades (~100–200ms). Opt in only if you
# need OMZ plugins beyond the two we load here:
#   export DOTFILES_USE_OMZ=1

_dotfiles_source_first() {
    emulate -L zsh
    local _p
    for _p in "$@"; do
        if [[ -f "$_p" ]]; then
            # shellcheck source=/dev/null
            source "$_p"
            return 0
        fi
    done
    return 1
}

if [[ "${DOTFILES_USE_OMZ:-0}" = 1 && -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME=""
    CASE_SENSITIVE=false
    HYPHEN_INSENSITIVE=true
    DISABLE_AUTO_UPDATE=true
    DISABLE_UPDATE_PROMPT=true
    ENABLE_CORRECTION=false
    COMPLETION_WAITING_DOTS=false
    DISABLE_UNTRACKED_FILES_DIRTY=true
    ZSH_DISABLE_COMPFIX=true
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    # shellcheck source=/dev/null
    source "$ZSH/oh-my-zsh.sh"
else
    _dotfiles_source_first \
        /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" \
        "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

    _dotfiles_source_first \
        /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
        "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset -f _dotfiles_source_first
