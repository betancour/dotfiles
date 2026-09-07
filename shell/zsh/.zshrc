# .zshrc — interactive Zsh configuration
#
# Load order (cheap → expensive, ready-timer bookends the body):
#   bootstrap → optional zprof → interactive guard → float SECONDS
#   → environment → options/history → completion/plugins
#   → prompt/keybindings/tools → aliases/functions → local → tty
#   → login display last (Ready: measures full interactive load)

source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"

# Optional startup profiling: ZSH_PROFILE_STARTUP=1 zsh -i -c 'zprof; exit'
[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && zmodload zsh/zprof 2>/dev/null

[[ $- != *i* ]] && return

# Float SECONDS from process start so login can report Ready in ms (no EPOCHREALTIME needed).
typeset -F SECONDS

# --- Environment (shared; source-once) ---
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

# --- Shell behavior ---
source "${DOTFILES_SHELL_DIR}/zsh/modules/options.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/history.zsh"

# --- Completion + plugins before prompt (autosuggestions / compinit) ---
source "${DOTFILES_SHELL_DIR}/zsh/modules/completion.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/plugins.zsh"

# --- Interactive UI ---
source "${DOTFILES_SHELL_DIR}/zsh/modules/prompt.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/keybindings.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/tools.zsh"

# --- User surface ---
dotfiles_source_once "${DOTFILES_SHELL_DIR}/.zaliases"
dotfiles_source_once "${DOTFILES_SHELL_DIR}/.zfunctions"

# Machine-local and vendor overrides after our defaults.
[[ -r "${ZDOTDIR:-$HOME}/.zshrc.local" ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"
[[ -r "/etc/zshrc_${TERM_PROGRAM:-}" ]] && source "/etc/zshrc_${TERM_PROGRAM}"

# Flow control is disabled via setopt NO_FLOW_CONTROL (no stty fork).

# Non-login interactive: login shells run this from .zlogin instead.
if [[ ! -o login ]]; then
    dotfiles_source_once "${DOTFILES_LIB_DIR}/login.sh"
    dotfiles_login
fi

[[ -n "${ZSH_PROFILE_STARTUP:-}" ]] && zprof 2>/dev/null

# bun completions
[ -s "/Users/betancour/.bun/_bun" ] && source "/Users/betancour/.bun/_bun"
