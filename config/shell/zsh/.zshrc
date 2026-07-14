# .zshrc — interactive Zsh configuration
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"

# Optional startup profiling: ZSH_PROFILE_STARTUP=1 zsh -i -c 'zprof; exit'
[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && zmodload zsh/zprof 2>/dev/null

[[ $- != *i* ]] && return

dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

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

stty -ixon 2>/dev/null || true

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && zprof 2>/dev/null
