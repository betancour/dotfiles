# .zprofile
# User specific environment and startup programs
# This file is sourced for login shells

# Note: .zshenv is automatically sourced first
# Note: .zshrc is automatically sourced after .zprofile for interactive shells
# Note: .zaliases is sourced from .zshrc

# Add any login-specific initialization here
# For example, starting services, setting up environment for GUI applications, etc.

# Homebrew setup for macOS (if not already in PATH)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -x "/opt/homebrew/bin/brew" ]] && [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Start SSH agent if not running (optional)
# if ! pgrep -u "$USER" ssh-agent > /dev/null; then
#     ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
# fi
# if [[ ! "$SSH_AUTH_SOCK" ]]; then
#     source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
# fi
