# LSCOLORS environment variable
#
## This file defines the colors to use for different file types and attributes
# in the ls command.
#

if [[ "$OSTYPE" == "linux-gnu"* ]]; then  # For Linux
    # Check if dark mode is enabled (customize this logic based on your setup)
    if [[ $(gsettings get org.gnome.desktop.interface color-scheme) == "'prefer-dark'" ]]; then
        export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43' # Dark theme
    else
        export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43' # Light theme
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then  # For macOS
    export CLICOLOR=1
    # Check for dark mode (use macOS-specific commands)
    if [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]; then
        export LSCOLORS="GxFxCxDxBxEgEdAgAc" # Dark theme
    else
        export LSCOLORS="ExFxBxDxCxegedabagacad" # Light theme
    fi
else
    echo "Unsupported OS"
fi

. "$HOME/.cargo/env"
