# options.bash — Bash shell options and history policy

shopt -s histappend histverify histreedit 2>/dev/null || true
shopt -s cdspell dirspell cdable_vars 2>/dev/null || true
shopt -s progcomp extglob nullglob 2>/dev/null || true
shopt -s checkwinsize cmdhist lithist 2>/dev/null || true
# Bash 4+ (no-op on macOS system bash 3.2)
shopt -s autocd 2>/dev/null || true
shopt -s globstar 2>/dev/null || true
shopt -s checkjobs 2>/dev/null || true

. "${DOTFILES_LIB_DIR}/history.sh"

export HISTCONTROL="ignoreboth:erasedups:ignorespace"
HISTIGNORE="$(dotfiles_history_ignore_patterns)"
export HISTIGNORE
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "
export PROMPT_DIRTRIM=3
