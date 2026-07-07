# environment.sh — environment variables for all shell sessions

[[ -n "${DOTFILES_ENV_LOADED:-}" ]] && return
export DOTFILES_ENV_LOADED=1

dotfiles_source_once "${DOTFILES_LIB_DIR}/platform.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/xdg.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/path.sh"

umask 022

# Locale
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"

# Editor and pager
export EDITOR="vi"
export VISUAL="vi"
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
    export VISUAL="vim"
fi

export PAGER="less"
export MANPAGER="less -X"
export LESS="-R -F -X -M -i -J --tabs=4"
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
[[ -d "${XDG_STATE_HOME}/less" ]] || mkdir -p "${XDG_STATE_HOME}/less"

# History location (shell-specific files may override HISTFILE)
export HISTSIZE=50000
export SAVEHIST=50000
export HIST_EXPIRE_DUPS_FIRST=1

# Compilation flags (macOS)
export ARCHFLAGS="-arch $(uname -m)"

# Tool-specific environment
export FZF_DEFAULT_OPTS="
    --height=50%
    --layout=reverse
    --border
    --inline-info
    --color=dark
    --color=fg:-1,bg:-1,hl:#5fff87,fg+:-1,bg+:-1,hl+:#ffaf5f
    --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7
    --bind='ctrl-u:page-up,ctrl-d:page-down'
"
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
    export HOMEBREW_BAT=1
    export HOMEBREW_PREFIX="/opt/homebrew"
    export SHELL_SESSION_HISTORY=0
elif is_linux; then
    export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43"
fi