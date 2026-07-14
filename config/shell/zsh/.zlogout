# .zlogout — login shell exit
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"

[[ -o login ]] || return

source "${DOTFILES_LIB_DIR}/logout.sh"

[[ -r "${ZDOTDIR:-$HOME}/.zlogout.local" ]] && source "${ZDOTDIR:-$HOME}/.zlogout.local"
