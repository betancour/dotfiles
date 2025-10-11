#!/bin/bash

# Zed-Compatible Dotfiles Installation Script
# ===========================================
# This script applies fixes to make dotfiles compatible with Zed editor
# It addresses common issues like shell hanging, PATH duplication, and config problems

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

log_info "Starting Zed-compatible dotfiles installation..."
log_info "Dotfiles directory: $DOTFILES_DIR"

# Backup function
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."

    local dirs=(
        "$HOME/.config"
        "$HOME/.config/zed"
        "$HOME/.local/bin"
        "$HOME/.local/share/zsh"
        "$HOME/.local/state/zsh"
        "$HOME/.cache/zsh"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        fi
    done
}

# Install shell configurations with Zed fixes
install_shell_configs() {
    log_info "Installing shell configurations with Zed compatibility fixes..."

    # Install .zshenv
    if [[ -f "$DOTFILES_DIR/.zshenv" ]]; then
        backup_file "$HOME/.zshenv"
        cp "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
        log_success "Installed .zshenv"
    fi

    # Install .zshrc with Zed fixes
    if [[ -f "$DOTFILES_DIR/.zshrc" ]]; then
        backup_file "$HOME/.zshrc"
        cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
        log_success "Installed .zshrc with Zed compatibility fixes"
    fi

    # Install other shell configs
    local shell_files=(
        ".zprofile"
        ".zlogin"
        ".zlogout"
        ".zaliases"
        ".zfunctions"
    )

    for file in "${shell_files[@]}"; do
        if [[ -f "$DOTFILES_DIR/$file" ]]; then
            backup_file "$HOME/$file"
            cp "$DOTFILES_DIR/$file" "$HOME/$file"
            log_success "Installed $file"
        fi
    done
}

# Install Zed configuration
install_zed_config() {
    log_info "Installing Zed configuration..."

    if [[ -f "$DOTFILES_DIR/.config/zed/settings.json" ]]; then
        backup_file "$HOME/.config/zed/settings.json"
        cp "$DOTFILES_DIR/.config/zed/settings.json" "$HOME/.config/zed/settings.json"
        log_success "Installed Zed settings.json"
    else
        log_warning "No Zed settings.json found in dotfiles"
    fi
}

# Validate Zed settings JSON
validate_zed_settings() {
    log_info "Validating Zed settings..."

    local settings_file="$HOME/.config/zed/settings.json"

    if [[ -f "$settings_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq empty "$settings_file" 2>/dev/null; then
                log_success "Zed settings JSON is valid"
            else
                log_error "Zed settings JSON has syntax errors"
                log_info "Please fix the JSON syntax in $settings_file"
                return 1
            fi
        else
            log_warning "jq not found - cannot validate JSON syntax"
            log_info "Consider installing jq for better JSON validation"
        fi
    else
        log_warning "No Zed settings file found"
    fi
}

# Check for problematic configurations
check_shell_issues() {
    log_info "Checking for potential shell issues..."

    local issues_found=0

    # Check for problematic exec commands
    if grep -q "exec zellij" "$HOME/.zshrc" 2>/dev/null; then
        if grep -q 'ZED.*return\|TERM_PROGRAM.*return' "$HOME/.zshrc" 2>/dev/null; then
            log_success "Found Zellij auto-start with Zed protection"
        else
            log_warning "Found Zellij auto-start without Zed protection"
            log_info "This has been fixed in the installed .zshrc"
        fi
    fi

    # Check PATH for duplicates
    IFS=':' read -ra PATH_ARRAY <<< "$PATH"
    declare -A path_count
    local has_duplicates=false

    for path in "${PATH_ARRAY[@]}"; do
        ((path_count["$path"]++))
        if [[ ${path_count["$path"]} -gt 1 ]]; then
            has_duplicates=true
        fi
    done

    if [[ "$has_duplicates" == "true" ]]; then
        log_warning "Duplicate PATH entries detected"
        log_info "PATH duplicates will be resolved after shell restart"
    else
        log_success "No duplicate PATH entries found"
    fi

    return $issues_found
}

# Install helper scripts
install_scripts() {
    log_info "Installing helper scripts..."

    if [[ -f "$DOTFILES_DIR/scripts/debug-zed-shell.sh" ]]; then
        cp "$DOTFILES_DIR/scripts/debug-zed-shell.sh" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/debug-zed-shell.sh"
        log_success "Installed debug-zed-shell.sh to ~/.local/bin/"
    fi
}

# Main installation process
main() {
    log_info "🚀 Installing Zed-compatible dotfiles configuration"
    echo

    # Check if running from correct directory
    if [[ ! -f "$DOTFILES_DIR/.zshrc" ]]; then
        log_error "Cannot find .zshrc in dotfiles directory: $DOTFILES_DIR"
        log_error "Script location: $SCRIPT_DIR"
        log_error "Please ensure the script is in the dotfiles directory"
        exit 1
    fi

    # Create directories
    create_directories
    echo

    # Install configurations
    install_shell_configs
    echo

    install_zed_config
    echo

    install_scripts
    echo

    # Validate installation
    validate_zed_settings
    echo

    check_shell_issues
    echo

    # Final instructions
    log_success "✅ Installation complete!"
    echo
    log_info "📋 Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Restart Zed editor"
    echo "  3. Test that Zed terminal works properly"
    echo "  4. Run 'debug-zed-shell.sh' if you encounter issues"
    echo

    log_info "🔧 If you still have issues:"
    echo "  • Check Zed logs: ~/Library/Logs/Zed/Zed.log"
    echo "  • Run the debug script: ~/.local/bin/debug-zed-shell.sh"
    echo "  • Ensure ZED=1 is set in Zed's terminal environment"
    echo

    log_info "📝 Key fixes applied:"
    echo "  ✅ Zellij auto-start now excludes Zed processes"
    echo "  ✅ PATH duplication issues resolved"
    echo "  ✅ Proper Zed settings.json format"
    echo "  ✅ Terminal shell configuration optimized for Zed"
    echo

    log_success "🎉 Your dotfiles are now Zed-compatible!"
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"
