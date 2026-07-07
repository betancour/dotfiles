# .bash_profile — login shell entry point
source "${BASH_SOURCE[0]%/*}/../lib/dotfiles.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"
source "${DOTFILES_SHELL_DIR}/bash/modules/profile.bash"

# Interactive login shells: load interactive config then login hooks
if [[ -n "${PS1:-}" && -f "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi

[[ -f "$HOME/.bash_login" ]] && source "$HOME/.bash_login"