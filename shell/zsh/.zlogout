# .zlogout — login shell exit
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"

[[ -o login ]] || return

source "${DOTFILES_LIB_DIR}/logout.sh"

if [[ -r "${ZDOTDIR:-$HOME}/.zlogout.local" ]]; then
    source "${ZDOTDIR:-$HOME}/.zlogout.local"
fi
