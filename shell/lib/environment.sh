# environment.sh — environment variables for all shell sessions
# Keep side effects minimal: no heavy tool init here (that belongs in profile/tools).

if [ -n "${DOTFILES_ENV_LOADED:-}" ]; then
    [ -n "${XDG_CONFIG_HOME:-}" ] && return 0
    unset DOTFILES_ENV_LOADED
fi
DOTFILES_ENV_LOADED=1

dotfiles_source_once "${DOTFILES_LIB_DIR}/platform.sh"
dotfiles_source_once "${DOTFILES_LIB_DIR}/xdg.sh"
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

# Ruby (gem)
export GEM_HOME="${XDG_DATA_HOME}/gem"
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"
export BUNDLE_USER_HOME="${XDG_CONFIG_HOME}/bundle"
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}/bundle"
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}/bundle/config"
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}/bundle"

# Node.js / npm / corepack
export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node_repl_history"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"
export COREPACK_HOME="${XDG_DATA_HOME}/corepack"
export TS_NODE_HISTORY="${XDG_STATE_HOME}/ts_node_repl_history"

# Bun
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export BUN_INSTALL_CACHE_DIR="${XDG_CACHE_HOME}/bun"

# Deno
export DENO_DIR="${XDG_CACHE_HOME}/deno"
export DENO_INSTALL_ROOT="${XDG_DATA_HOME}/deno"

# pnpm / Yarn
export PNPM_HOME="${XDG_DATA_HOME}/pnpm"
export YARN_CACHE_FOLDER="${XDG_CACHE_HOME}/yarn"
export YARN_GLOBAL_FOLDER="${XDG_DATA_HOME}/yarn"

# NVM / fnm (paths only; init is lazy in tools.sh / profile.sh)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

# Java — resolve JAVA_HOME for all sessions (login + non-login)
export GRADLE_USER_HOME="${XDG_DATA_HOME}/gradle"
if [ -z "${JAVA_HOME:-}" ]; then
    if is_macos; then
        for _jhome in \
            /opt/homebrew/opt/openjdk \
            /opt/homebrew/opt/openjdk@26 \
            /opt/homebrew/opt/openjdk@25 \
            /opt/homebrew/opt/openjdk@21 \
            /opt/homebrew/opt/openjdk@17 \
            /usr/local/opt/openjdk
        do
            if [ -d "$_jhome/libexec/openjdk.jdk/Contents/Home" ]; then
                export JAVA_HOME="$_jhome/libexec/openjdk.jdk/Contents/Home"
                break
            elif [ -d "$_jhome" ]; then
                export JAVA_HOME="$_jhome"
                break
            fi
        done
        unset _jhome
        if [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
            JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null) && export JAVA_HOME
        fi
    elif is_linux; then
        for _jhome in \
            /usr/lib/jvm/default-java \
            /usr/lib/jvm/java-21-openjdk \
            /usr/lib/jvm/java-21-openjdk-amd64 \
            /usr/lib/jvm/java-17-openjdk \
            /usr/lib/jvm/java-17-openjdk-amd64 \
            /usr/lib/jvm/java-11-openjdk \
            /usr/lib/jvm/java-11-openjdk-amd64
        do
            if [ -d "$_jhome" ]; then
                export JAVA_HOME="$_jhome"
                break
            fi
        done
        unset _jhome
    fi
fi

# Python
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"
export PYTHONUSERBASE="${XDG_DATA_HOME}/python"
export PIP_CACHE_DIR="${XDG_CACHE_HOME}/pip"
export PIPX_HOME="${XDG_DATA_HOME}/pipx"
export PIPX_BIN_DIR="${HOME}/.local/bin"
export UV_CACHE_DIR="${XDG_CACHE_HOME}/uv"
export WORKON_HOME="${XDG_DATA_HOME}/virtualenvs"
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

# Rust
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"

# Go
export GOPATH="${XDG_DATA_HOME}/go"
export GOCACHE="${XDG_CACHE_HOME}/go-build"
export GOMODCACHE="${XDG_CACHE_HOME}/go/mod"

# Mise (XDG-friendly defaults when installed)
export MISE_DATA_DIR="${MISE_DATA_DIR:-${XDG_DATA_HOME}/mise}"
export MISE_CACHE_DIR="${MISE_CACHE_DIR:-${XDG_CACHE_HOME}/mise}"
export MISE_CONFIG_DIR="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME}/mise}"

# SDKMAN (optional; init stays lazy)
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"

# .NET SDK — resolve DOTNET_ROOT for user and system installs
export DOTNET_CLI_TELEMETRY_OPTOUT="${DOTNET_CLI_TELEMETRY_OPTOUT:-1}"
export DOTNET_NOLOGO="${DOTNET_NOLOGO:-1}"
if [ -z "${DOTNET_ROOT:-}" ]; then
    for _dn_root in \
        "$HOME/.dotnet" \
        /usr/local/share/dotnet \
        /opt/homebrew/opt/dotnet/libexec \
        /usr/local/opt/dotnet/libexec
    do
        if [ -x "${_dn_root}/dotnet" ]; then
            export DOTNET_ROOT="$_dn_root"
            break
        fi
    done
    unset _dn_root
fi

# PATH after toolchain vars so BUN_INSTALL / PNPM_HOME / CARGO_HOME / DOTNET_ROOT resolve correctly
dotfiles_source_once "${DOTFILES_LIB_DIR}/path.sh"

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
