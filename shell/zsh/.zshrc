# .zshrc — interactive Zsh configuration
#
# Load order (cheap → expensive, ready-timer bookends the body):
#   bootstrap → optional zprof → interactive guard → float SECONDS
#   → environment → history/options → completion/plugins
#   → prompt/keybindings/tools → aliases/functions → local
#   → login display, then syntax highlighting (must wrap every widget)

source "${${(%):-%x}:A:h}/../lib/bootstrap.sh"

# Optional startup profiling: ZSH_PROFILE_STARTUP=1 zsh -i -c 'zprof; exit'
if [[ -n "${ZSH_PROFILE_STARTUP:-}" ]]; then
    zmodload zsh/zprof 2>/dev/null || true
fi

[[ $- != *i* ]] && return

# Interactive sessions create private files. Scripts (zsh -c) do not reach here,
# so they keep the caller's umask.
umask 077

# Float SECONDS from process start so login can report Ready in ms (no EPOCHREALTIME needed).
typeset -F SECONDS

# --- Environment (shared; source-once) ---
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

# Config files own tool colors. Drop inherited overrides for this interactive
# shell only; non-interactive zsh keeps whatever the parent exported.
unset BAT_THEME EZA_COLORS EXA_COLORS LS_COLORS LSCOLORS GREP_COLORS FZF_DEFAULT_OPTS

dotfiles_gpg_tty

# --- Shell behavior ---
# History file and sizes before SHARE_HISTORY, so /etc/zshrc's ~/.zsh_history
# and HISTSIZE=2000 do not win.
source "${DOTFILES_SHELL_DIR}/zsh/modules/history.zsh"
source "${DOTFILES_SHELL_DIR}/zsh/modules/options.zsh"

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
if [[ -r "${ZDOTDIR:-$HOME}/.zshrc.local" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc.local"
fi

# /etc/zshrc already sources /etc/zshrc_$TERM_PROGRAM. Doing it again
# registers Terminal.app's precmd hook twice.
if [[ ${TERM_PROGRAM:-} == iTerm.app ]]; then
    export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
fi

# Flow control is disabled via setopt NO_FLOW_CONTROL (no stty fork).

# Non-login interactive: login shells run this from .zlogin instead.
if [[ ! -o login ]]; then
    dotfiles_source_once "${DOTFILES_LIB_DIR}/login.sh"
    dotfiles_login
fi

# bun completions are ~1200 lines. Load them on the first Tab, not at startup.
_DF_BUN_COMPLETION="${BUN_INSTALL:-$HOME/.bun}/_bun"
if [[ -r $_DF_BUN_COMPLETION ]]; then
    _bun() {
        local _f=$_DF_BUN_COMPLETION
        unfunction _bun
        unset _DF_BUN_COMPLETION
        # shellcheck source=/dev/null
        source "$_f"
        _bun "$@"
    }
    compdef _bun bun 2>/dev/null || true
fi

# After every widget (fzf, local bindkey, bun). Highlighting no-ops without a tty.
_dotfiles_load_syntax_highlighting

if [[ -n "${ZSH_PROFILE_STARTUP:-}" ]]; then
    zprof 2>/dev/null || true
fi
