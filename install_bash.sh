#!/bin/bash

# Bash Dotfiles Installation Script
# This script will backup existing bash dotfiles and create symbolic links to the new ones

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_bash_$(date +%Y%m%d_%H%M%S)"

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
    if ! command_exists "bash"; then
        missing_deps+=("bash")
    fi

    if ! command_exists "git"; then
        missing_deps+=("git")
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

# Function to setup directories
setup_directories() {
    print_status "Creating necessary directories..."

    # Create XDG directories
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}"
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"

    # Create Bash-specific directories
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/bash"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/bash"

    print_success "Created necessary directories"
}

# Function to install bash completion
install_bash_completion() {
    print_status "Setting up bash completion..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists "brew"; then
            if ! brew list bash-completion 2>/dev/null; then
                print_status "Installing bash-completion via Homebrew..."
                brew install bash-completion
            fi
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt >/dev/null 2>&1; then
            if ! dpkg -l | grep -q bash-completion; then
                print_status "Installing bash-completion via apt..."
                sudo apt update && sudo apt install -y bash-completion
            fi
        fi
    fi
}

# Function to test configuration
test_configuration() {
    print_status "Testing bash configuration..."

    # Test that files can be sourced without errors
    if bash -n "$DOTFILES_DIR/.bash_env"; then
        print_success ".bash_env syntax check passed"
    else
        print_error ".bash_env has syntax errors"
        return 1
    fi

    if bash -n "$DOTFILES_DIR/.bash_profile"; then
        print_success ".bash_profile syntax check passed"
    else
        print_error ".bash_profile has syntax errors"
        return 1
    fi

    if bash -n "$DOTFILES_DIR/.bashrc"; then
        print_success ".bashrc syntax check passed"
    else
        print_error ".bashrc has syntax errors"
        return 1
    fi

    if bash -n "$DOTFILES_DIR/.bash_aliases"; then
        print_success ".bash_aliases syntax check passed"
    else
        print_error ".bash_aliases has syntax errors"
        return 1
    fi

    if bash -n "$DOTFILES_DIR/.bash_functions"; then
        print_success ".bash_functions syntax check passed"
    else
        print_error ".bash_functions has syntax errors"
        return 1
    fi
}

# Main installation function
main() {
    echo
    echo "======================================"
    echo "  Bash Dotfiles Installation Script"
    echo "======================================"
    echo

    print_status "Starting bash dotfiles installation..."
    print_status "Dotfiles directory: $DOTFILES_DIR"

    # Test configuration first
    if ! test_configuration; then
        print_error "Configuration test failed. Aborting installation."
        exit 1
    fi

    # Check dependencies
    install_dependencies

    # Setup directories
    setup_directories

    # Install bash completion
    install_bash_completion

    # Create symbolic links for dotfiles
    print_status "Creating symbolic links..."

    # Bash configuration files
    create_link ".bash_env" ".bash_env"
    create_link ".bash_profile" ".bash_profile"
    create_link ".bashrc" ".bashrc"
    create_link ".bash_logout" ".bash_logout"
    create_link ".bash_aliases" ".bash_aliases"
    create_link ".bash_functions" ".bash_functions"

    # Create local customization files if they don't exist
    if [[ ! -f "$HOME/.bashrc.local" ]]; then
        if [[ -f "$DOTFILES_DIR/.bashrc.local.template" ]]; then
            cp "$DOTFILES_DIR/.bashrc.local.template" "$HOME/.bashrc.local"
            print_success "Created .bashrc.local from template"
        fi
    fi

    # Git configuration (if it exists)
    if [[ -f "$DOTFILES_DIR/.gitconfig" ]]; then
        create_link ".gitconfig" ".gitconfig"
    fi

    # Vim configuration (if it exists)
    if [[ -f "$DOTFILES_DIR/.vimrc" ]]; then
        create_link ".vimrc" ".vimrc"
    fi

    # Show backup information
    if [[ -d "$BACKUP_DIR" ]]; then
        print_warning "Your old dotfiles have been backed up to: $BACKUP_DIR"
    fi

    echo
    print_success "Bash dotfiles installation completed!"
    echo
    print_status "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.bash_profile"
    echo "  2. Edit ~/.bashrc.local for machine-specific customizations"
    echo "  3. Type 'help' in your shell to see available custom functions"
    echo "  4. Review BASH_CONFIG.md for detailed documentation"
    echo "  5. Customize any settings to your preference"
    echo

    # Ask to change shell to bash if not already
    if [[ "$SHELL" != *"bash" ]]; then
        echo -e "${YELLOW}Current shell is not Bash.${NC}"
        read -p "Would you like to change your default shell to Bash? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command_exists "bash"; then
                local bash_path=$(which bash)
                chsh -s "$bash_path"
                print_success "Default shell changed to Bash. Please log out and log back in for the change to take effect."
            else
                print_error "Bash not found. Please install Bash first."
            fi
        fi
    fi

    # Test the installation
    print_status "Testing installation..."
    if bash -c "source ~/.bash_env && source ~/.bashrc && echo 'Installation test successful!'" 2>/dev/null; then
        print_success "Installation test passed!"
    else
        print_warning "Installation test had some issues, but files are installed. Check the configuration."
    fi
}

# Function to show help
show_help() {
    echo "Bash Dotfiles Installation Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -t, --test     Test configuration only (no installation)"
    echo "  -f, --force    Force installation without prompts"
    echo
    echo "This script will install comprehensive Bash configuration files including:"
    echo "  - .bash_env (environment variables)"
    echo "  - .bash_profile (login shell setup)"
    echo "  - .bashrc (interactive shell configuration)"
    echo "  - .bash_logout (exit cleanup)"
    echo "  - .bash_aliases (command shortcuts)"
    echo "  - .bash_functions (custom utilities)"
    echo
    echo "Existing files will be backed up before replacement."
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -t|--test)
        echo "Testing configuration..."
        test_configuration
        exit $?
        ;;
    -f|--force)
        export FORCE_INSTALL=1
        main
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
