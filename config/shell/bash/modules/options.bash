# options.bash — Bash shell options

shopt -s histappend histverify histreedit 2>/dev/null
shopt -s cdspell dirspell cdable_vars 2>/dev/null
shopt -s progcomp extglob nullglob dotglob 2>/dev/null
shopt -s checkwinsize cmdhist lithist checkjobs 2>/dev/null
# Bash 4.0+ options (gracefully skipped on macOS system bash 3.2)
shopt -s autocd 2>/dev/null
shopt -s globstar 2>/dev/null

source "${DOTFILES_LIB_DIR}/history.sh"

export HISTCONTROL="ignoreboth:erasedups:ignorespace"
export HISTIGNORE
HISTIGNORE="$(dotfiles_history_ignore_patterns)"
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "
export PROMPT_DIRTRIM=3