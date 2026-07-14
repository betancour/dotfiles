# .bash_logout — login shell exit
. "${BASH_SOURCE[0]%/*}/../lib/bootstrap.sh"

case $- in *l*) ;; *) return ;; esac

. "${DOTFILES_LIB_DIR}/logout.sh"

[ -r "$HOME/.bash_logout.local" ] && . "$HOME/.bash_logout.local"
