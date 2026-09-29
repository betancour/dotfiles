# .zprofile — login shell profile
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/profile.sh"

# Docker completions and Terminal.app's shell integration live in completion.zsh
# and /etc/zshrc. Sourcing /etc/zshrc_Apple_Terminal here as well registered
# its precmd hook a second time (and a third from .zshrc).

if [[ -r "${ZDOTDIR:-$HOME}/.zprofile.local" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprofile.local"
fi
