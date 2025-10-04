#!/bin/bash

# Dotfiles Installation Script
# This script will backup existing dotfiles and create symbolic links to the new ones

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup existing files
backup_file() {
    local file="$1"
    if [[ -e "$HOME/$file" ]] || [[ -L "$HOME/$file" ]]; then
        print_warning "Backing up existing $file"
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/$file" "$BACKUP_DIR/"
    fi
}

# Function to create symbolic links
create_link() {
    local source="$1"
    local target="$2"

    if [[ -f "$DOTFILES_DIR/$source" ]] || [[ -d "$DOTFILES_DIR/$source" ]]; then
        backup_file "$target"
        ln -sf "$DOTFILES_DIR/$source" "$HOME/$target"
        print_success "Linked $source -> ~/$target"
    else
        print_error "Source file $source not found in dotfiles directory"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    print_status "Checking for required dependencies..."

    local missing_deps=()
    local optional_deps=()

    # Check for essential tools
    if ! command_exists "git"; then
        missing_deps+=("git")
    fi

    if ! command_exists "zsh"; then
        missing_deps+=("zsh")
    fi

    # Check for optional modern CLI tools
    if ! command_exists "eza"; then
        optional_deps+=("eza")
    fi

    if ! command_exists "bat"; then
        optional_deps+=("bat")
    fi

    if ! command_exists "rg"; then
        optional_deps+=("ripgrep")
    fi

    if ! command_exists "fzf"; then
        optional_deps+=("fzf")
    fi

    if ! command_exists "fd"; then
        optional_deps+=("fd")
    fi

    if ! command_exists "zoxide"; then
        optional_deps+=("zoxide")
    fi

    if ! command_exists "nvim"; then
        optional_deps+=("neovim")
    fi

    # Report missing essential dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing essential dependencies: ${missing_deps[*]}"
        print_status "Please install them first:"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install ${missing_deps[*]}"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "  sudo apt update && sudo apt install ${missing_deps[*]}"
        fi

        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Report missing optional dependencies
    if [[ ${#optional_deps[@]} -gt 0 ]]; then
        print_warning "Missing optional dependencies: ${optional_deps[*]}"
        print_status "For the best experience, consider installing them:"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install ${optional_deps[*]}"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "  sudo apt update && sudo apt install ${optional_deps[*]}"
        fi
        echo
    fi
}

# Function to setup ZSH plugins
setup_zsh_plugins() {
    print_status "Setting up ZSH plugins..."

    # Check if Oh My Zsh is installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_warning "Oh My Zsh not found. Installing..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Install zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        print_status "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        print_success "Installed zsh-autosuggestions"
    else
        print_status "zsh-autosuggestions already installed"
    fi

    # Install zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        print_status "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        print_success "Installed zsh-syntax-highlighting"
    else
        print_status "zsh-syntax-highlighting already installed"
    fi
}

# Function to setup directories
setup_directories() {
    print_status "Creating necessary directories..."

    # Create config directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.cache"

    # Create XDG directories
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}"
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"

    # Create ZSH-specific directories
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

    print_success "Created necessary directories"
}

# Main installation function
main() {
    echo
    echo "======================================"
    echo "  Dotfiles Installation Script"
    echo "======================================"
    echo

    print_status "Starting dotfiles installation..."
    print_status "Dotfiles directory: $DOTFILES_DIR"

    # Check dependencies
    install_dependencies

    # Setup directories
    setup_directories

    # Create symbolic links for dotfiles
    print_status "Creating symbolic links..."

    # Shell configuration files
    create_link ".zshrc" ".zshrc"
    create_link ".zaliases" ".zaliases"
    create_link ".zshenv" ".zshenv"
    create_link ".zprofile" ".zprofile"
    create_link ".zlogin" ".zlogin"
    create_link ".zlogout" ".zlogout"
    create_link ".zfunctions" ".zfunctions"

    # Create local customization files if they don't exist
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        if [[ -f "$DOTFILES_DIR/.zshrc.local.template" ]]; then
            cp "$DOTFILES_DIR/.zshrc.local.template" "$HOME/.zshrc.local"
            print_success "Created .zshrc.local from template"
        fi
    fi

    # Git configuration
    create_link ".gitconfig" ".gitconfig"
    create_link ".gitignore" ".gitignore"

    # Vim configuration
    create_link ".vimrc" ".vimrc"

    # Neovim configuration
    create_link "nvim" ".config/nvim"

    # Alacritty configuration
    create_link "alacritty" ".config/alacritty"

    # Setup ZSH plugins
    setup_zsh_plugins

    # Show backup information
    if [[ -d "$BACKUP_DIR" ]]; then
        print_warning "Your old dotfiles have been backed up to: $BACKUP_DIR"
    fi

    echo
    print_success "Dotfiles installation completed!"
    echo
    print_status "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Open Neovim and run: :Lazy to install plugins"
    echo "  3. Edit ~/.zshrc.local for machine-specific customizations"
    echo "  4. Type 'help' in your shell to see available custom functions"
    echo "  5. Customize any settings to your preference"
    echo

    # Ask to change shell to zsh
    if [[ "$SHELL" != *"zsh" ]]; then
        echo -e "${YELLOW}Current shell is not ZSH.${NC}"
        read -p "Would you like to change your default shell to ZSH? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command_exists "zsh"; then
                chsh -s "$(which zsh)"
                print_success "Default shell changed to ZSH. Please log out and log back in for the change to take effect."
            else
                print_error "ZSH not found. Please install ZSH first."
            fi
        fi
    fi
}

# Run the main function
main "$@"
