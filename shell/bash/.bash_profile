# .bash_profile — login shell entry point
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
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/profile.sh"

# Shell-specific local overrides
if [ -r "$HOME/.bash_profile.local" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.bash_profile.local"
fi

# PS1 is not a reliable interactive test this early (Linux /etc/profile
# often leaves it unset). $-'s `i` flag is. Prefer the installed symlink,
# then the bashrc next to this file (works when sourcing the repo directly).
case $- in
    *i*)
        if [ -f "$HOME/.bashrc" ]; then
            # shellcheck source=/dev/null
            . "$HOME/.bashrc"
        elif [ -f "${BASH_SOURCE[0]%/*}/.bashrc" ]; then
            # shellcheck source=/dev/null
            . "${BASH_SOURCE[0]%/*}/.bashrc"
        fi
        ;;
esac
if [ -f "$HOME/.bash_login" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.bash_login"
elif [ -f "${BASH_SOURCE[0]%/*}/.bash_login" ]; then
    # shellcheck source=/dev/null
    . "${BASH_SOURCE[0]%/*}/.bash_login"
fi
