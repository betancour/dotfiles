# .bash_profile — login shell entry point
. "${BASH_SOURCE[0]%/*}/../lib/bootstrap.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/profile.sh"

# Shell-specific local overrides
[ -r "$HOME/.bash_profile.local" ] && . "$HOME/.bash_profile.local"

# Interactive login: load interactive config, then login hooks
if [ -n "${PS1:-}" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
[ -f "$HOME/.bash_login" ] && . "$HOME/.bash_login"
