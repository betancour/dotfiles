# .zlogin — post-interactive login setup
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"

[[ -o login ]] || return

dotfiles_source_once "${DOTFILES_LIB_DIR}/login.sh"
dotfiles_login

[[ -r "${ZDOTDIR:-$HOME}/.zlogin.local" ]] && source "${ZDOTDIR:-$HOME}/.zlogin.local"
