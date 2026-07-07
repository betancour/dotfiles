# .zshrc — interactive shell configuration
source "${${(%):-%x}:A:h}/../lib/dotfiles.sh"

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && zmodload zsh/zprof
[[ $- != *i* ]] && return

# Ensure system paths available for interactive sessions
PATH="/usr/bin:/usr/sbin:$PATH"
export PATH

source "${DOTFILES_SHELL_DIR}/zsh/modules/options.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/history.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/completion.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/plugins.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/prompt.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/keybindings.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/tools.zsh"

dotfiles_source_once "${DOTFILES_LIB_DIR}/aliases.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/functions.sh"

[[ -r "${ZDOTDIR:-$HOME}/.zshrc.local" ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"
[[ -r "/etc/zshrc_${TERM_PROGRAM:-}" ]] && source "/etc/zshrc_${TERM_PROGRAM}"

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && zprof

stty -ixon 2>/dev/null || true

if [[ ! -o login && -t 1 ]]; then
    echo "Welcome back! Type 'help' for available commands."
fi