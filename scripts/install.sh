#!/usr/bin/env bash
# install.sh — symlink dotfiles into $HOME
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_CONFIG="${DOTFILES_DIR}/config/shell"
BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
SHELL_TYPE="${1:-${DOTFILES_SHELL:-auto}}"

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

detect_shell() {
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "${SHELL:-}" == *zsh* ]]; then
        echo zsh
    elif [[ -n "${BASH_VERSION:-}" ]] || [[ "${SHELL:-}" == *bash* ]]; then
        echo bash
    elif command -v zsh >/dev/null 2>&1; then
        echo zsh
    else
        echo bash
    fi
}

backup_and_link() {
    local src="$1" dest="$2"
    [[ -e "$src" ]] || { error "Missing source: $src"; return 1; }

    if [[ -e "$dest" || -L "$dest" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
        warn "Backed up $(basename "$dest")"
    fi

    ln -sf "$src" "$dest"
    success "~/$(basename "$dest") -> $src"
}

validate_zsh() {
    local f
    for f in \
        "${SHELL_CONFIG}/zsh/.zshenv" \
        "${SHELL_CONFIG}/zsh/.zprofile" \
        "${SHELL_CONFIG}/zsh/.zshrc" \
        "${SHELL_CONFIG}/zsh/.zlogin" \
        "${SHELL_CONFIG}/zsh/.zlogout"; do
        zsh -n "$f" || return 1
    done
}

validate_bash() {
    local f
    for f in \
        "${SHELL_CONFIG}/bash/.bash_env" \
        "${SHELL_CONFIG}/bash/.bash_profile" \
        "${SHELL_CONFIG}/bash/.bashrc" \
        "${SHELL_CONFIG}/bash/.bash_login" \
        "${SHELL_CONFIG}/bash/.bash_logout"; do
        bash -n "$f" || return 1
    done
}

install_zsh() {
    info "Installing Zsh configuration..."
    validate_zsh
    backup_and_link "${SHELL_CONFIG}/zsh/.zshenv"   "${HOME}/.zshenv"
    backup_and_link "${SHELL_CONFIG}/zsh/.zprofile" "${HOME}/.zprofile"
    backup_and_link "${SHELL_CONFIG}/zsh/.zshrc"    "${HOME}/.zshrc"
    backup_and_link "${SHELL_CONFIG}/zsh/.zlogin"   "${HOME}/.zlogin"
    backup_and_link "${SHELL_CONFIG}/zsh/.zlogout"  "${HOME}/.zlogout"
    backup_and_link "${SHELL_CONFIG}/.zaliases"     "${HOME}/.zaliases"
    backup_and_link "${SHELL_CONFIG}/.zfunctions"   "${HOME}/.zfunctions"

    local template="${DOTFILES_DIR}/config/terminal/.zshrc.local.template"
    if [[ -f "$template" && ! -f "${HOME}/.zshrc.local" ]]; then
        cp "$template" "${HOME}/.zshrc.local"
        success "Created ~/.zshrc.local from template"
    fi
}

install_bash() {
    info "Installing Bash configuration..."
    validate_bash
    backup_and_link "${SHELL_CONFIG}/bash/.bash_env"      "${HOME}/.bash_env"
    backup_and_link "${SHELL_CONFIG}/bash/.bash_profile"  "${HOME}/.bash_profile"
    backup_and_link "${SHELL_CONFIG}/bash/.bashrc"        "${HOME}/.bashrc"
    backup_and_link "${SHELL_CONFIG}/bash/.bash_login"    "${HOME}/.bash_login"
    backup_and_link "${SHELL_CONFIG}/bash/.bash_logout"   "${HOME}/.bash_logout"

    local template="${DOTFILES_DIR}/config/terminal/.bashrc.local.template"
    if [[ -f "$template" && ! -f "${HOME}/.bashrc.local" ]]; then
        cp "$template" "${HOME}/.bashrc.local"
        success "Created ~/.bashrc.local from template"
    fi
}

usage() {
    cat <<EOF
Usage: $0 [zsh|bash|both|auto]

Install dotfiles shell configuration via symlinks.

  zsh   Install Zsh configuration (main branch default)
  bash  Install Bash configuration
  both  Install both shells
  auto  Detect from current shell (default)
EOF
}

main() {
    [[ "${SHELL_TYPE}" == auto ]] && SHELL_TYPE="$(detect_shell)"

    case "${SHELL_TYPE}" in
        zsh)  install_zsh ;;
        bash) install_bash ;;
        both) install_zsh; install_bash ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown shell type: ${SHELL_TYPE}"; usage; exit 1 ;;
    esac

    if [[ -f "${DOTFILES_DIR}/.gitconfig" ]]; then
        backup_and_link "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
        local gitconfig_local_template="${DOTFILES_DIR}/.gitconfig.local.template"
        if [[ -f "$gitconfig_local_template" && ! -f "${HOME}/.gitconfig.local" ]]; then
            cp "$gitconfig_local_template" "${HOME}/.gitconfig.local"
            chmod 600 "${HOME}/.gitconfig.local"
            success "Created ~/.gitconfig.local from template — edit with your name and email"
        fi
    fi

    [[ -d "$BACKUP_DIR" ]] && warn "Previous files backed up to: $BACKUP_DIR"
    success "Installation complete. Restart your shell or run: exec \$SHELL -l"
}

main