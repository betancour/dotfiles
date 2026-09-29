# .zlogin — post-interactive login setup
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"

[[ -o login ]] || return

dotfiles_source_once "${DOTFILES_LIB_DIR}/login.sh"
dotfiles_login

if [[ -r "${ZDOTDIR:-$HOME}/.zlogin.local" ]]; then
    source "${ZDOTDIR:-$HOME}/.zlogin.local"
fi
