# .bashrc — interactive Bash configuration
#
# Load order (cheap → expensive, ready-timer bookends the body):
#   bootstrap → interactive guard → start mark
#   → environment → options/history
#   → prompt/completion/keybindings/tools
#   → aliases/functions → local → tty
#   → login display last (Ready: measures full interactive load)

# Resolve this file when ~/.bashrc is a symlink into the repo.
_df_src=${BASH_SOURCE[0]}
if [ -L "$_df_src" ]; then
    _df_target=$(readlink "$_df_src") || _df_target=
    case $_df_target in
        /*) _df_src=$_df_target ;;
        ?*) _df_src=${BASH_SOURCE[0]%/*}/$_df_target ;;
    esac
fi
# shellcheck source=../lib/bootstrap.sh
. "${_df_src%/*}/../lib/bootstrap.sh"
unset _df_src _df_target

# Non-interactive: stop here (scripts, scp, rsync, etc.)
case $- in *i*) ;; *) return ;; esac

# Interactive sessions create private files. Non-interactive bash never gets here.
umask 077

# Mark start for Ready: reporting (Bash 5+ EPOCHREALTIME). Before heavy work.
if [ -n "${EPOCHREALTIME:-}" ] && [ -z "${DOTFILES_SHELL_START:-}" ]; then
    DOTFILES_SHELL_START=$EPOCHREALTIME
fi

# System bashrc sets a default PS1 and may source bashrc_$TERM_PROGRAM.
# Source it before our prompt so it cannot clobber Starship or PS1.
# shellcheck source=/dev/null
[ -r /etc/bashrc ] && . /etc/bashrc

# --- Environment (shared; source-once) ---
dotfiles_source_once "${DOTFILES_LIB_DIR}/environment.sh"

# Interactive only: let config files own tool colors.
unset BAT_THEME EZA_COLORS EXA_COLORS LS_COLORS LSCOLORS GREP_COLORS FZF_DEFAULT_OPTS

dotfiles_gpg_tty

# Bash sets HISTFILE=~/.bash_history before any rc file, so ${HISTFILE:-...}
# never moves it. Interactive sessions use the XDG file. .bashrc.local may
# override this afterwards.
_df_bash_hist_dir="${XDG_STATE_HOME}/bash"
_df_bash_hist="${_df_bash_hist_dir}/history"
[ -d "$_df_bash_hist_dir" ] || mkdir -p "$_df_bash_hist_dir"
if [ ! -s "$_df_bash_hist" ] && [ -s "$HOME/.bash_history" ]; then
    cp "$HOME/.bash_history" "$_df_bash_hist" && chmod 600 "$_df_bash_hist"
fi
export HISTFILE="$_df_bash_hist"
unset _df_bash_hist_dir _df_bash_hist

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

# Machine-local overrides after our defaults.
if [ -r "$HOME/.bashrc.local" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.bashrc.local"
fi

# Terminal line discipline (interactive TTY only; ignore failure on dumb).
if [ -t 0 ]; then
    stty -ixon 2>/dev/null || true
fi

# $- never contains `l`. login_shell is the Bash test (including 3.2).
# Login shells run the banner from .bash_login so Ready includes this file.
if ! shopt -q login_shell 2>/dev/null; then
    dotfiles_source_once "${DOTFILES_LIB_DIR}/login.sh"
    dotfiles_login
fi
