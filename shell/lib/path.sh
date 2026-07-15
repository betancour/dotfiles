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

# User directories first
_dotfiles_path_add "$HOME/bin"
_dotfiles_path_add "$HOME/.local/bin"
_dotfiles_path_add "$HOME/.grok/bin"

# Language toolchains (XDG-aware where possible)
_dotfiles_path_add "${CARGO_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/cargo}/bin"
_dotfiles_path_add "$HOME/.cargo/bin"
_dotfiles_path_add "${GOPATH:-${XDG_DATA_HOME:-$HOME/.local/share}/go}/bin"
_dotfiles_path_add "$HOME/go/bin"
_dotfiles_path_add "$HOME/.npm-global/bin"

if is_macos; then
    _dotfiles_path_add /opt/homebrew/bin
    _dotfiles_path_add /opt/homebrew/sbin
    _dotfiles_path_add /usr/local/bin
    _dotfiles_path_add /usr/local/sbin
    # Common Homebrew keg paths (exist only if installed)
    _dotfiles_path_add /opt/homebrew/opt/ruby/bin
    _dotfiles_path_add /opt/homebrew/opt/openjdk/bin
    _dotfiles_path_add /opt/homebrew/opt/gnu-sed/libexec/gnubin
    _dotfiles_path_add /opt/homebrew/opt/grep/libexec/gnubin
elif is_linux; then
    _dotfiles_path_add /usr/local/bin
    _dotfiles_path_add /usr/local/sbin
fi

unset -f _dotfiles_path_add
export PATH
