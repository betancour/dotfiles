# path.sh — centralized PATH management (single pass, no duplicates)

[ -n "${DOTFILES_PATH_LOADED:-}" ] && return 0
DOTFILES_PATH_LOADED=1

# shellcheck source=platform.sh
. "${DOTFILES_LIB_DIR}/platform.sh"

# Prepend directory to PATH if it exists and is not already present.
_dotfiles_path_add() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# Add the first existing directory from a list of candidates.
_dotfiles_path_add_first() {
    _df_p=
    for _df_p in "$@"; do
        if [ -d "$_df_p" ]; then
            _dotfiles_path_add "$_df_p"
            unset _df_p
            return 0
        fi
    done
    unset _df_p
}

# User directories first
_dotfiles_path_add "$HOME/bin"
_dotfiles_path_add "$HOME/.local/bin"
_dotfiles_path_add "$HOME/.grok/bin"

# --- Language toolchains (XDG-aware where possible) ---

# Rust
_dotfiles_path_add "${CARGO_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/cargo}/bin"
_dotfiles_path_add "$HOME/.cargo/bin"

# Go
_dotfiles_path_add "${GOPATH:-${XDG_DATA_HOME:-$HOME/.local/share}/go}/bin"
_dotfiles_path_add "$HOME/go/bin"

# Node: npm global prefix, then Homebrew keg-only Node (versioned formulas)
_dotfiles_path_add "${NPM_CONFIG_PREFIX:-$HOME/.npm-global}/bin"
_dotfiles_path_add "$HOME/.npm-global/bin"
if is_macos; then
    _dotfiles_path_add_first \
        /opt/homebrew/opt/node/bin \
        /opt/homebrew/opt/node@24/bin \
        /opt/homebrew/opt/node@22/bin \
        /opt/homebrew/opt/node@20/bin \
        /usr/local/opt/node/bin \
        /usr/local/opt/node@24/bin \
        /usr/local/opt/node@22/bin \
        /usr/local/opt/node@20/bin
elif is_linux; then
    _dotfiles_path_add_first \
        /usr/local/lib/nodejs/bin \
        /usr/lib/node_modules/npm/bin
fi

# Bun
_dotfiles_path_add "${BUN_INSTALL:-$HOME/.bun}/bin"

# Deno
_dotfiles_path_add "${DENO_INSTALL_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/deno}/bin"
_dotfiles_path_add "$HOME/.deno/bin"

# pnpm / Yarn
_dotfiles_path_add "${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"
_dotfiles_path_add "${YARN_GLOBAL_FOLDER:-${XDG_DATA_HOME:-$HOME/.local/share}/yarn}/bin"
_dotfiles_path_add "$HOME/.yarn/bin"

# Ruby (gem / rbenv)
_dotfiles_path_add "${GEM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/gem}/bin"
_dotfiles_path_add "$HOME/.rbenv/bin"
_dotfiles_path_add "$HOME/.rbenv/shims"

# Python (pyenv / pipx already covered by ~/.local/bin)
_dotfiles_path_add "${PYENV_ROOT:-$HOME/.pyenv}/bin"
_dotfiles_path_add "${PYENV_ROOT:-$HOME/.pyenv}/shims"
_dotfiles_path_add "${PYTHONUSERBASE:-${XDG_DATA_HOME:-$HOME/.local/share}/python}/bin"

# Java — Homebrew OpenJDK (keg-only) and JAVA_HOME/bin when already set
if [ -n "${JAVA_HOME:-}" ]; then
    _dotfiles_path_add "${JAVA_HOME}/bin"
fi
if is_macos; then
    _dotfiles_path_add_first \
        /opt/homebrew/opt/openjdk/bin \
        /opt/homebrew/opt/openjdk@26/bin \
        /opt/homebrew/opt/openjdk@25/bin \
        /opt/homebrew/opt/openjdk@21/bin \
        /opt/homebrew/opt/openjdk@17/bin \
        /usr/local/opt/openjdk/bin
elif is_linux; then
    _dotfiles_path_add_first \
        /usr/lib/jvm/default-java/bin \
        /usr/lib/jvm/java-21-openjdk/bin \
        /usr/lib/jvm/java-17-openjdk/bin \
        /usr/lib/jvm/java-11-openjdk/bin
fi

# Android SDK (optional)
if [ -n "${ANDROID_HOME:-}" ]; then
    _dotfiles_path_add "${ANDROID_HOME}/platform-tools"
    _dotfiles_path_add "${ANDROID_HOME}/tools"
    _dotfiles_path_add "${ANDROID_HOME}/tools/bin"
elif [ -d "${ANDROID_SDK_ROOT:-}" ]; then
    _dotfiles_path_add "${ANDROID_SDK_ROOT}/platform-tools"
fi

# Flutter
_dotfiles_path_add "$HOME/flutter/bin"
_dotfiles_path_add "$HOME/development/flutter/bin"

# Mise shims (when not activated via shell hook)
_dotfiles_path_add "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"

# Platform package managers / coreutils
if is_macos; then
    _dotfiles_path_add /opt/homebrew/bin
    _dotfiles_path_add /opt/homebrew/sbin
    _dotfiles_path_add /usr/local/bin
    _dotfiles_path_add /usr/local/sbin
    # Common Homebrew keg paths (exist only if installed)
    _dotfiles_path_add /opt/homebrew/opt/ruby/bin
    _dotfiles_path_add /opt/homebrew/opt/gnu-sed/libexec/gnubin
    _dotfiles_path_add /opt/homebrew/opt/grep/libexec/gnubin
    _dotfiles_path_add /opt/homebrew/opt/coreutils/libexec/gnubin
elif is_linux; then
    _dotfiles_path_add /usr/local/bin
    _dotfiles_path_add /usr/local/sbin
fi

unset -f _dotfiles_path_add _dotfiles_path_add_first
export PATH
