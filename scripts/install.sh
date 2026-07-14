#!/bin/sh
# install.sh — deploy shell configuration via symlinks
#
# POSIX /bin/sh. Detects OS and shell; installs only what is needed.
# Idempotent: correct existing symlinks are left alone.
# Non-destructive: existing files are backed up before replacement.
#
# Usage: install.sh [zsh|bash|both|auto]
#        install.sh --help

set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SHELL_CONFIG="${DOTFILES_DIR}/config/shell"
BACKUP_DIR=""
SHELL_TYPE="${1:-${DOTFILES_SHELL:-auto}}"
OS_NAME=$(uname -s 2>/dev/null || echo unknown)

# --- logging (no bashisms; colors only when stdout is a TTY) ---

if [ -t 1 ]; then
    C_INFO=$(printf '\033[34m')
    C_OK=$(printf '\033[32m')
    C_WARN=$(printf '\033[33m')
    C_ERR=$(printf '\033[31m')
    C_RST=$(printf '\033[0m')
else
    C_INFO= C_OK= C_WARN= C_ERR= C_RST=
fi

info()    { printf '%s[INFO]%s %s\n'  "$C_INFO" "$C_RST" "$*"; }
success() { printf '%s[OK]%s %s\n'    "$C_OK"   "$C_RST" "$*"; }
warn()    { printf '%s[WARN]%s %s\n'  "$C_WARN" "$C_RST" "$*"; }
error()   { printf '%s[ERROR]%s %s\n' "$C_ERR"  "$C_RST" "$*" >&2; }

# --- detection ---

detect_shell() {
    # Prefer the login shell ($SHELL), then runtime, then availability.
    case "${SHELL:-}" in
        *zsh)  echo zsh; return ;;
        *bash) echo bash; return ;;
    esac
    if [ -n "${ZSH_VERSION:-}" ]; then
        echo zsh
    elif [ -n "${BASH_VERSION:-}" ]; then
        echo bash
    elif command -v zsh >/dev/null 2>&1; then
        echo zsh
    else
        echo bash
    fi
}

# --- symlink helpers ---

ensure_backup_dir() {
    if [ -z "$BACKUP_DIR" ]; then
        BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Link src -> dest. Skip if already correct. Backup non-matching targets.
link_file() {
    _src=$1
    _dest=$2

    if [ ! -e "$_src" ]; then
        error "Missing source: $_src"
        return 1
    fi

    if [ -L "$_dest" ]; then
        _cur=$(readlink "$_dest" 2>/dev/null || true)
        if [ "$_cur" = "$_src" ]; then
            info "unchanged: $_dest"
            unset _src _dest _cur
            return 0
        fi
        ensure_backup_dir
        mv "$_dest" "$BACKUP_DIR/"
        warn "backed up symlink $(basename "$_dest")"
    elif [ -e "$_dest" ]; then
        ensure_backup_dir
        mv "$_dest" "$BACKUP_DIR/"
        warn "backed up $(basename "$_dest")"
    fi

    ln -s "$_src" "$_dest"
    success "$(basename "$_dest") -> $_src"
    unset _src _dest _cur
}

install_template() {
    _template=$1
    _dest=$2
    if [ -f "$_template" ] && [ ! -e "$_dest" ]; then
        cp "$_template" "$_dest"
        success "created $(basename "$_dest") from template"
    fi
    unset _template _dest
}

# --- validation ---

validate_zsh() {
    command -v zsh >/dev/null 2>&1 || {
        warn "zsh not installed; skipping syntax check"
        return 0
    }
    for _f in \
        "${SHELL_CONFIG}/zsh/.zshenv" \
        "${SHELL_CONFIG}/zsh/.zprofile" \
        "${SHELL_CONFIG}/zsh/.zshrc" \
        "${SHELL_CONFIG}/zsh/.zlogin" \
        "${SHELL_CONFIG}/zsh/.zlogout"
    do
        zsh -n "$_f" || return 1
    done
    unset _f
}

validate_bash() {
    command -v bash >/dev/null 2>&1 || {
        warn "bash not installed; skipping syntax check"
        return 0
    }
    for _f in \
        "${SHELL_CONFIG}/bash/.bash_env" \
        "${SHELL_CONFIG}/bash/.bash_profile" \
        "${SHELL_CONFIG}/bash/.bashrc" \
        "${SHELL_CONFIG}/bash/.bash_login" \
        "${SHELL_CONFIG}/bash/.bash_logout"
    do
        bash -n "$_f" || return 1
    done
    unset _f
}

# --- installers ---

install_zsh() {
    info "Installing Zsh configuration (OS=${OS_NAME})..."
    validate_zsh
    link_file "${SHELL_CONFIG}/zsh/.zshenv"   "${HOME}/.zshenv"
    link_file "${SHELL_CONFIG}/zsh/.zprofile" "${HOME}/.zprofile"
    link_file "${SHELL_CONFIG}/zsh/.zshrc"    "${HOME}/.zshrc"
    link_file "${SHELL_CONFIG}/zsh/.zlogin"   "${HOME}/.zlogin"
    link_file "${SHELL_CONFIG}/zsh/.zlogout"  "${HOME}/.zlogout"
    install_template \
        "${DOTFILES_DIR}/config/terminal/.zshrc.local.template" \
        "${HOME}/.zshrc.local"
}

install_bash() {
    info "Installing Bash configuration (OS=${OS_NAME})..."
    validate_bash
    link_file "${SHELL_CONFIG}/bash/.bash_env"     "${HOME}/.bash_env"
    link_file "${SHELL_CONFIG}/bash/.bash_profile" "${HOME}/.bash_profile"
    link_file "${SHELL_CONFIG}/bash/.bashrc"       "${HOME}/.bashrc"
    link_file "${SHELL_CONFIG}/bash/.bash_login"   "${HOME}/.bash_login"
    link_file "${SHELL_CONFIG}/bash/.bash_logout"  "${HOME}/.bash_logout"
    install_template \
        "${DOTFILES_DIR}/config/terminal/.bashrc.local.template" \
        "${HOME}/.bashrc.local"

    # Ensure Bash loads env for non-login interactive shells that skip .bash_profile.
    # BASH_ENV is used by non-interactive Bash; login uses .bash_profile.
    # Documented for users who want it: export BASH_ENV=$HOME/.bash_env
}

install_gitconfig() {
    if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
        link_file "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
        install_template \
            "${DOTFILES_DIR}/.gitconfig.local.template" \
            "${HOME}/.gitconfig.local"
        if [ -f "${HOME}/.gitconfig.local" ]; then
            chmod 600 "${HOME}/.gitconfig.local" 2>/dev/null || true
        fi
    fi
}

usage() {
    cat <<EOF
Usage: $0 [zsh|bash|both|auto]

Deploy shell configuration from this repository via symlinks.

  zsh   Install Zsh only
  bash  Install Bash only
  both  Install both shells
  auto  Detect from \$SHELL (default)

Environment:
  DOTFILES_SHELL   Override default shell type (same values as above)

The installer:
  - Detects OS (reported in logs; config is OS-agnostic)
  - Creates symlinks idempotently
  - Backs up conflicting files to ~/.dotfiles_backup_<timestamp>
  - Never deletes user data without backing it up
  - Installs local templates only when missing
EOF
}

# --- main ---

main() {
    case "$SHELL_TYPE" in
        -h|--help) usage; exit 0 ;;
        auto) SHELL_TYPE=$(detect_shell) ;;
    esac

    info "dotfiles root: $DOTFILES_DIR"
    info "target shell:  $SHELL_TYPE"
    info "OS:            $OS_NAME"

    case "$SHELL_TYPE" in
        zsh)  install_zsh ;;
        bash) install_bash ;;
        both)
            install_zsh
            install_bash
            ;;
        *)
            error "Unknown shell type: $SHELL_TYPE"
            usage
            exit 1
            ;;
    esac

    install_gitconfig

    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        warn "Previous files backed up to: $BACKUP_DIR"
    fi
    success "Installation complete. Restart your shell: exec \$SHELL -l"
}

main
