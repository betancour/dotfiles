# .zshenv — always sourced (environment only, keep lean)
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

# HISTFILE is set in the interactive rc, after /etc/zshrc. Setting it here
# would point every script and `zsh -c` at the history file, and /etc/zshrc
# would overwrite it for interactive shells anyway.

# `[[ -r ]] && source` would leave $? = 1 when the file is absent, and
# `zsh -c exit` would then exit 1.
if [[ -r "${ZDOTDIR:-$HOME}/.zshenv.local" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshenv.local"
fi
