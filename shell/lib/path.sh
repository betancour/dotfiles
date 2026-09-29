# path.sh — centralized PATH management (single pass, no duplicates)
#
# Entries are listed highest-priority first. Existing PATH entries that are
# not in that list (path_helper, cryptex, /usr/bin, …) are appended and
# de-duplicated. Re-sourcing after macOS path_helper restores this order;
# path_helper runs between .zshenv and .zprofile and would otherwise leave
# /usr/bin ahead of keg-only tools and duplicate Homebrew.

[ -n "${DOTFILES_PATH_LOADED:-}" ] && return 0
DOTFILES_PATH_LOADED=1

# shellcheck source=platform.sh
. "${DOTFILES_LIB_DIR}/platform.sh"

# Colon-separated priority list. First entry ends up at the front of PATH.
_DF_PATH_FRONT=

_dotfiles_path_add() {
    [ -n "$1" ] || return 0
    [ -d "$1" ] || return 0
    case ":${_DF_PATH_FRONT}:" in
        *":$1:"*) return 0 ;;
    esac
    _DF_PATH_FRONT="${_DF_PATH_FRONT:+${_DF_PATH_FRONT}:}$1"
}

# Add the first existing directory from a list of candidates.
_dotfiles_path_add_first() {
    for _df_p in "$@"; do
        if [ -d "$_df_p" ]; then
            _dotfiles_path_add "$_df_p"
            unset _df_p
            return 0
        fi
    done
    unset _df_p
}

# --- 1. User binaries override everything ---
_dotfiles_path_add "$HOME/.local/bin"
_dotfiles_path_add "$HOME/bin"
_dotfiles_path_add "$HOME/.grok/bin"

# --- 2. Maven / Gradle beat Homebrew and distro packages ---
if [ -n "${GRADLE_HOME:-}" ]; then
    _dotfiles_path_add "${GRADLE_HOME}/bin"
fi
if [ -n "${MAVEN_HOME:-}" ]; then
    _dotfiles_path_add "${MAVEN_HOME}/bin"
fi
_dotfiles_path_add "${JAVA_TOOLS_HOME:-$HOME/.java-tools}/gradle/bin"
_dotfiles_path_add "${JAVA_TOOLS_HOME:-$HOME/.java-tools}/maven/bin"

# --- 3. Keg-only and user toolchains (not linked into Homebrew's bin) ---
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
        /usr/lib/jvm/default-java/bin \
        /usr/lib/jvm/java-21-openjdk/bin \
        /usr/lib/jvm/java-21-openjdk-amd64/bin \
        /usr/lib/jvm/java-17-openjdk/bin \
        /usr/lib/jvm/java-17-openjdk-amd64/bin \
        /usr/lib/jvm/java-11-openjdk/bin \
        /usr/lib/jvm/java-11-openjdk-amd64/bin
    _dotfiles_path_add_first \
        /usr/local/lib/nodejs/bin \
        /usr/lib/node_modules/npm/bin
fi

_dotfiles_path_add "${BUN_INSTALL:-$HOME/.bun}/bin"
_dotfiles_path_add "${CARGO_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/cargo}/bin"
_dotfiles_path_add "$HOME/.cargo/bin"
_dotfiles_path_add "${GOPATH:-${XDG_DATA_HOME:-$HOME/.local/share}/go}/bin"
_dotfiles_path_add "$HOME/go/bin"
_dotfiles_path_add "${NPM_CONFIG_PREFIX:-$HOME/.npm-global}/bin"
_dotfiles_path_add "$HOME/.npm-global/bin"
_dotfiles_path_add "${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"
_dotfiles_path_add "${YARN_GLOBAL_FOLDER:-${XDG_DATA_HOME:-$HOME/.local/share}/yarn}/bin"
_dotfiles_path_add "$HOME/.yarn/bin"
_dotfiles_path_add "${DENO_INSTALL_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/deno}/bin"
_dotfiles_path_add "$HOME/.deno/bin"
_dotfiles_path_add "${GEM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/gem}/bin"
_dotfiles_path_add "$HOME/.rbenv/shims"
_dotfiles_path_add "$HOME/.rbenv/bin"
_dotfiles_path_add "${PYENV_ROOT:-$HOME/.pyenv}/shims"
_dotfiles_path_add "${PYENV_ROOT:-$HOME/.pyenv}/bin"
_dotfiles_path_add "${PYTHONUSERBASE:-${XDG_DATA_HOME:-$HOME/.local/share}/python}/bin"

if [ -n "${DOTNET_ROOT:-}" ]; then
    _dotfiles_path_add "$DOTNET_ROOT"
    _dotfiles_path_add "$DOTNET_ROOT/tools"
fi
_dotfiles_path_add "$HOME/.dotnet"
_dotfiles_path_add "$HOME/.dotnet/tools"
_dotfiles_path_add /usr/local/share/dotnet
if is_macos; then
    _dotfiles_path_add_first \
        /opt/homebrew/opt/dotnet/libexec \
        /usr/local/opt/dotnet/libexec
fi

if [ -n "${ANDROID_HOME:-}" ]; then
    _dotfiles_path_add "${ANDROID_HOME}/platform-tools"
    _dotfiles_path_add "${ANDROID_HOME}/tools"
    _dotfiles_path_add "${ANDROID_HOME}/tools/bin"
elif [ -n "${ANDROID_SDK_ROOT:-}" ]; then
    _dotfiles_path_add "${ANDROID_SDK_ROOT}/platform-tools"
fi
_dotfiles_path_add "$HOME/flutter/bin"
_dotfiles_path_add "$HOME/development/flutter/bin"

# --- 4. Homebrew, then legacy /usr/local, then mise shims ---
# mise shims stay behind Homebrew so a linked brew ruby/node is not
# replaced by an unused shim. GNU prefixes stay ahead of BSD /usr/bin.
if is_macos; then
    _dotfiles_path_add /opt/homebrew/opt/coreutils/libexec/gnubin
    _dotfiles_path_add /opt/homebrew/opt/grep/libexec/gnubin
    _dotfiles_path_add /opt/homebrew/opt/gnu-sed/libexec/gnubin
    _dotfiles_path_add /opt/homebrew/bin
    _dotfiles_path_add /opt/homebrew/sbin
    _dotfiles_path_add /opt/homebrew/opt/ruby/bin
    _dotfiles_path_add /usr/local/bin
    _dotfiles_path_add /usr/local/sbin
elif is_linux; then
    _dotfiles_path_add "${HOME}/.linuxbrew/bin"
    _dotfiles_path_add "${HOME}/.linuxbrew/sbin"
    _dotfiles_path_add /home/linuxbrew/.linuxbrew/bin
    _dotfiles_path_add /home/linuxbrew/.linuxbrew/sbin
    _dotfiles_path_add /usr/local/bin
    _dotfiles_path_add /usr/local/sbin
fi
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
    _dotfiles_path_add "${HOMEBREW_PREFIX}/bin"
    _dotfiles_path_add "${HOMEBREW_PREFIX}/sbin"
fi

_dotfiles_path_add "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"

# Merge: priority list, then whatever PATH already contained, skipping dupes
# and empty components (a leading colon from path_helper must not survive).
_df_new=
_df_seen=:
_df_rest=${_DF_PATH_FRONT}${PATH:+:${PATH}}
while [ -n "$_df_rest" ]; do
    case $_df_rest in
        *:*) _df_dir=${_df_rest%%:*}; _df_rest=${_df_rest#*:} ;;
        *) _df_dir=$_df_rest; _df_rest= ;;
    esac
    [ -n "$_df_dir" ] || continue
    case "${_df_seen}" in
        *":${_df_dir}:"*) continue ;;
    esac
    _df_new="${_df_new:+${_df_new}:}${_df_dir}"
    _df_seen="${_df_seen}${_df_dir}:"
done

PATH=$_df_new
export PATH

unset _DF_PATH_FRONT _df_new _df_seen _df_rest _df_dir
unset -f _dotfiles_path_add _dotfiles_path_add_first
