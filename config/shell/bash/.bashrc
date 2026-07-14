# .bashrc — interactive Bash configuration
. "${BASH_SOURCE[0]%/*}/../lib/bootstrap.sh"

# Non-interactive: stop here (scripts, scp, etc.)
case $- in *i*) ;; *) return ;; esac

dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

# HISTFILE may already be set by .bash_env / login; ensure it for non-login shells
export HISTFILE="${HISTFILE:-${XDG_STATE_HOME}/bash/history}"
[ -d "${XDG_STATE_HOME}/bash" ] || mkdir -p "${XDG_STATE_HOME}/bash"

. "${DOTFILES_SHELL_DIR}/bash/modules/options.bash"
dotfiles_source_once "${DOTFILES_LIB_DIR}/history.sh"
dotfiles_secure_history_file "$HISTFILE"

. "${DOTFILES_SHELL_DIR}/bash/modules/prompt.bash"
. "${DOTFILES_SHELL_DIR}/bash/modules/completion.bash"
. "${DOTFILES_SHELL_DIR}/bash/modules/keybindings.bash"
. "${DOTFILES_SHELL_DIR}/bash/modules/tools.bash"

dotfiles_source_once "${DOTFILES_LIB_DIR}/aliases.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/functions.sh"

[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
[ -r /etc/bashrc ] && . /etc/bashrc

stty -ixon 2>/dev/null || true
