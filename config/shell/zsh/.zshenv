# .zshenv — always sourced (environment only, keep lean)
source "${${(%):-%x}:A:h}/../lib/dotfiles.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

export HISTFILE="${XDG_STATE_HOME}/zsh/history"
[[ -d "${XDG_STATE_HOME}/zsh" ]] || mkdir -p "${XDG_STATE_HOME}/zsh"

[[ -r "${ZDOTDIR:-$HOME}/.zshenv.local" ]] && source "${ZDOTDIR:-$HOME}/.zshenv.local"