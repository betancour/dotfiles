# .bashrc — interactive shell configuration
source "${BASH_SOURCE[0]%/*}/../lib/dotfiles.sh"

[[ -n "${BASH_PROFILE_STARTUP:-}" ]] && BASH_START_TIME=$(date +%s.%N)
case $- in *i*) ;; *) return ;; esac

dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

source "${DOTFILES_SHELL_DIR}/bash/modules/options.bash"
source "${DOTFILES_LIB_DIR}/history.sh"
dotfiles_secure_history_file "$HISTFILE"
source "${DOTFILES_SHELL_DIR}/bash/modules/prompt.bash"
source "${DOTFILES_SHELL_DIR}/bash/modules/completion.bash"
source "${DOTFILES_SHELL_DIR}/bash/modules/keybindings.bash"
source "${DOTFILES_SHELL_DIR}/bash/modules/tools.bash"

dotfiles_source_once "${DOTFILES_LIB_DIR}/aliases.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/functions.sh"

[[ -r "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
[[ -r /etc/bashrc ]] && source /etc/bashrc

stty -ixon 2>/dev/null || true

if [[ "$SHLVL" -eq 1 && ! "$-" == *l* && -t 1 ]]; then
    echo "Welcome back! Type 'help' for available commands."
fi

if [[ -n "${BASH_PROFILE_STARTUP:-}" && -n "${BASH_START_TIME:-}" ]]; then
    BASH_END_TIME=$(date +%s.%N)
    echo "Bashrc loaded in: $(echo "$BASH_END_TIME - $BASH_START_TIME" | bc 2>/dev/null || echo unknown)s" >&2
    unset BASH_START_TIME BASH_END_TIME
fi