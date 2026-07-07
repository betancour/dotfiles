# path.sh — centralized PATH management (single pass, no duplicate entries)

[[ -n "${DOTFILES_PATH_LOADED:-}" ]] && return
export DOTFILES_PATH_LOADED=1

# shellcheck source=platform.sh
source "${DOTFILES_LIB_DIR}/platform.sh"

add_to_path() {
    [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}

# User directories
add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.grok/bin"

# Language / toolchain binaries
add_to_path "${CARGO_HOME:-$XDG_DATA_HOME/cargo}/bin"
add_to_path "$HOME/.cargo/bin"
add_to_path "$HOME/go/bin"
add_to_path "$HOME/.npm-global/bin"

if is_macos; then
    add_to_path "/opt/homebrew/bin"
    add_to_path "/opt/homebrew/sbin"
    add_to_path "/usr/local/bin"
    add_to_path "/usr/local/sbin"
    add_to_path "/opt/homebrew/opt/ruby/bin"
    add_to_path "/opt/homebrew/opt/python@3.11/bin"
    add_to_path "/opt/homebrew/opt/openjdk/bin"
    add_to_path "/opt/homebrew/opt/gnu-sed/libexec/gnubin"
    add_to_path "/opt/homebrew/opt/grep/libexec/gnubin"
    add_to_path "/opt/homebrew/opt/node@24/bin"
    add_to_path "/opt/homebrew/lib/ruby/gems/4.0.0/bin"
elif is_linux; then
    add_to_path "/usr/local/bin"
    add_to_path "/usr/local/sbin"
    add_to_path "$HOME/.cargo/bin"
    add_to_path "/opt/homebrew/opt/coreutils/libexec/gnubin"
fi

unset -f add_to_path
export PATH