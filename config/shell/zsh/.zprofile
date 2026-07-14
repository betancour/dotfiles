# .zprofile — login shell profile
source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/profile.sh"

# Zsh: Docker desktop completion path
if [[ -d /Applications/Docker.app/Contents/Resources/etc ]]; then
    fpath+=(/Applications/Docker.app/Contents/Resources/etc)
fi

# Terminal-specific integration
case "${TERM_PROGRAM:-}" in
    Apple_Terminal) [[ -r /etc/zshrc_Apple_Terminal ]] && source /etc/zshrc_Apple_Terminal ;;
    iTerm.app)      export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES ;;
esac

[[ -r "${ZDOTDIR:-$HOME}/.zprofile.local" ]] && source "${ZDOTDIR:-$HOME}/.zprofile.local"
