# .bash_logout — login shell exit
_df_src=${BASH_SOURCE[0]}
if [ -L "$_df_src" ]; then
    _df_target=$(readlink "$_df_src") || _df_target=
    case $_df_target in
        /*) _df_src=$_df_target ;;
        ?*) _df_src=${BASH_SOURCE[0]%/*}/$_df_target ;;
    esac
fi
# shellcheck source=../lib/bootstrap.sh
. "${_df_src%/*}/../lib/bootstrap.sh"
unset _df_src _df_target

shopt -q login_shell 2>/dev/null || return 0

. "${DOTFILES_LIB_DIR}/logout.sh"

if [ -r "$HOME/.bash_logout.local" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.bash_logout.local"
fi
