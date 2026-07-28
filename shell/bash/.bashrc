# .bashrc — interactive Bash configuration
#
# Load order (cheap → expensive, ready-timer bookends the body):
#   bootstrap → interactive guard → start mark
#   → environment → options/history
#   → prompt/completion/keybindings/tools
#   → aliases/functions → local → tty
#   → login display last (Ready: measures full interactive load)

. "${BASH_SOURCE[0]%/*}/../lib/bootstrap.sh"

# Non-interactive: stop here (scripts, scp, rsync, etc.)
case $- in *i*) ;; *) return ;; esac

# Mark start for Ready: reporting (Bash 5+ EPOCHREALTIME). Before heavy work.
if [ -n "${EPOCHREALTIME:-}" ] && [ -z "${DOTFILES_SHELL_START:-}" ]; then
    DOTFILES_SHELL_START=$EPOCHREALTIME
fi

# --- Environment (shared; source-once) ---
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

# HISTFILE may already be set by .bash_env / login; ensure for non-login shells.
export HISTFILE="${HISTFILE:-${XDG_STATE_HOME}/bash/history}"
[ -d "${XDG_STATE_HOME}/bash" ] || mkdir -p "${XDG_STATE_HOME}/bash"

# --- Shell behavior ---
. "${DOTFILES_SHELL_DIR}/bash/modules/options.bash"
dotfiles_source_once "${DOTFILES_LIB_DIR}/history.sh"
dotfiles_secure_history_file "$HISTFILE"

# --- Interactive UI (prompt before completion so PS1 is ready early) ---
. "${DOTFILES_SHELL_DIR}/bash/modules/prompt.bash"
. "${DOTFILES_SHELL_DIR}/bash/modules/completion.bash"
. "${DOTFILES_SHELL_DIR}/bash/modules/keybindings.bash"
. "${DOTFILES_SHELL_DIR}/bash/modules/tools.bash"

# --- User surface ---
dotfiles_source_once "${DOTFILES_SHELL_DIR}/.zaliases"
dotfiles_source_once "${DOTFILES_SHELL_DIR}/.zfunctions"

# Machine-local and vendor overrides after our defaults.
[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
[ -r /etc/bashrc ] && . /etc/bashrc

# Terminal line discipline (interactive TTY only; ignore failure on dumb).
stty -ixon 2>/dev/null || true

# Non-login interactive: login shells run this from .bash_login instead.
case $- in
    *l*) ;;
    *)
        dotfiles_source_once "${DOTFILES_LIB_DIR}/login.sh"
        dotfiles_login
        ;;
esac
