# environment.sh — environment variables for all shell sessions
# Keep side effects minimal: no heavy tool init here (that belongs in profile/tools).

if [ -n "${DOTFILES_ENV_LOADED:-}" ]; then
    [ -n "${XDG_CONFIG_HOME:-}" ] && return 0
    unset DOTFILES_ENV_LOADED
fi
DOTFILES_ENV_LOADED=1

dotfiles_source_once "${DOTFILES_LIB_DIR}/platform.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/xdg.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/path.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/privacy.sh"

umask 077

# Locale
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"

# Editor and pager — prefer nvim, then vim, then vi (no repeated lookups later)
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim VISUAL=nvim
elif command -v vim >/dev/null 2>&1; then
    export EDITOR=vim VISUAL=vim
else
    export EDITOR=vi VISUAL=vi
fi

export PAGER=less
export MANPAGER="less -X"
export LESS="-R -F -X -M -i -J --tabs=4"
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
[ -d "${XDG_STATE_HOME}/less" ] || mkdir -p "${XDG_STATE_HOME}/less"

# History size (shell-specific modules set HISTFILE and shell options)
export HISTSIZE=50000
export SAVEHIST=50000

# Tool config paths (XDG)
export FZF_DEFAULT_OPTS="--height=50% --layout=reverse --border --inline-info --color=dark --bind=ctrl-u:page-up,ctrl-d:page-down"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}/bat/config"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"
export GEM_HOME="${XDG_DATA_HOME}/gem"
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"
export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node_repl_history"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"
export PYTHONUSERBASE="${XDG_DATA_HOME}/python"
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export GOPATH="${XDG_DATA_HOME}/go"
export GOCACHE="${XDG_CACHE_HOME}/go-build"

if is_macos; then
    export CLICOLOR=1
    export LSCOLORS="GxFxCxDxBxegedabagaced"
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_ENV_HINTS=1
    export SHELL_SESSION_HISTORY=0
elif is_linux; then
    export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43"
fi
