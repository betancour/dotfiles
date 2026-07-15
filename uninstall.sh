#!/bin/sh
# uninstall.sh — remove managed dotfiles symlinks and managed blocks
#
# Does NOT uninstall packages by default (use --packages only when you mean it).
# Restores backups from the latest backup directory when available.
#
# Usage:
#   ./uninstall.sh [options]
#
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose logging
#   -n, --dry-run    Show actions only
#   -y, --yes        Skip confirmation
#   -f, --force      Remove more aggressively
#   --keep-backups   Do not offer restore from backups
#   --packages       Also attempt to note packages (does not auto-remove)
#
# shellcheck shell=sh
# shellcheck source=/dev/null

set -eu

DOTFILES_ROOT=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
export DOTFILES_ROOT

. "${DOTFILES_ROOT}/lib/logging.sh"
. "${DOTFILES_ROOT}/lib/common.sh"
. "${DOTFILES_ROOT}/lib/detect.sh"
. "${DOTFILES_ROOT}/lib/rollback.sh"
. "${DOTFILES_ROOT}/lib/symlink.sh"
. "${DOTFILES_ROOT}/lib/managed.sh"

KEEP_BACKUPS=0
NOTE_PACKAGES=0

usage() {
    cat <<EOF
${C_BOLD}dotfiles uninstaller${C_RST} v${DOTFILES_INSTALLER_VERSION}

Usage: ./uninstall.sh [options]

  -h, --help         Show help
  -v, --verbose      Verbose logging
  -n, --dry-run      Print actions only
  -y, --yes          Skip confirmation prompt
  -f, --force        Force removal of known managed paths
  --keep-backups     Do not restore from backup directories
  --packages         Print packages that were installed (no auto-remove)

Removes:
  - Symlinks under \$HOME that point into the dotfiles repository
  - Managed blocks previously appended by the installer
  - Generated loaders under the state directory

Does not remove:
  - Package-manager installed tools (unless you uninstall them yourself)
  - The real repository at ~/.dotfiles
  - *.local customization files
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) DOTFILES_VERBOSE=1; export DOTFILES_VERBOSE; shift ;;
            -n|--dry-run) DOTFILES_DRY_RUN=1; export DOTFILES_DRY_RUN; shift ;;
            -y|--yes) DOTFILES_YES=1; export DOTFILES_YES; shift ;;
            -f|--force) DOTFILES_FORCE=1; export DOTFILES_FORCE; shift ;;
            --keep-backups) KEEP_BACKUPS=1; shift ;;
            --packages) NOTE_PACKAGES=1; shift ;;
            *) die "Unknown option: $1" ;;
        esac
    done
}

# Known home paths the installer may manage.
DF_KNOWN_LINKS="
$HOME/.zshenv
$HOME/.zprofile
$HOME/.zshrc
$HOME/.zlogin
$HOME/.zlogout
$HOME/.zaliases
$HOME/.zfunctions
$HOME/.bash_env
$HOME/.bash_profile
$HOME/.bashrc
$HOME/.bash_login
$HOME/.bash_logout
$HOME/.profile
$HOME/.gitconfig
$HOME/.gitignore_global
$HOME/.vimrc
$HOME/.config/starship.toml
$HOME/.config/alacritty
"

df_uninstall_symlinks() {
    log_step "Removing managed symlinks"

    # Prefer recorded list.
    if [ -f "${DOTFILES_STATE_DIR}/symlinks.list" ]; then
        while IFS= read -r _df_link || [ -n "$_df_link" ]; do
            [ -z "$_df_link" ] && continue
            df_unlink_if_ours "$_df_link" "$DOTFILES_ROOT"
        done <"${DOTFILES_STATE_DIR}/symlinks.list"
    fi

    # Also scan known paths (covers installs before list tracking).
    for _df_link in $DF_KNOWN_LINKS; do
        [ -n "$_df_link" ] || continue
        df_unlink_if_ours "$_df_link" "$DOTFILES_ROOT"
        # Canonical path and legacy locations from earlier layouts.
        df_unlink_if_ours "$_df_link" "$DOTFILES_CANONICAL_HOME"
        df_unlink_if_ours "$_df_link" "$HOME/dotfiles"
        df_unlink_if_ours "$_df_link" "$HOME/Development/dotfiles"
    done
    unset _df_link
}

df_uninstall_managed_blocks() {
    log_step "Removing managed blocks"

    if [ -f "${DOTFILES_STATE_DIR}/managed.list" ]; then
        while IFS= read -r _df_file || [ -n "$_df_file" ]; do
            [ -z "$_df_file" ] && continue
            df_remove_managed_block "$_df_file"
        done <"${DOTFILES_STATE_DIR}/managed.list"
    fi

    # Known targets that may contain managed blocks.
    for _df_file in \
        "$HOME/.zshrc" "$HOME/.zshenv" \
        "$HOME/.bashrc" "$HOME/.bash_profile" \
        "$HOME/.profile"
    do
        df_remove_managed_block "$_df_file"
    done
    unset _df_file
}

df_restore_latest_backup() {
    if [ "$KEEP_BACKUPS" = "1" ]; then
        log_info "Keeping backups in place (--keep-backups)"
        return 0
    fi

    if [ ! -d "$DOTFILES_BACKUP_ROOT" ]; then
        log_verbose "No backup root found"
        return 0
    fi

    # Pick newest backup directory (timestamp names sort lexicographically).
    _df_latest=$(
        for _df_cand in "$DOTFILES_BACKUP_ROOT"/*; do
            [ -d "$_df_cand" ] || continue
            basename "$_df_cand"
        done | sort | tail -n 1
    )
    if [ -z "$_df_latest" ]; then
        log_verbose "No backups to restore"
        unset _df_latest
        return 0
    fi
    _df_dir="${DOTFILES_BACKUP_ROOT}/${_df_latest}"
    if [ ! -d "$_df_dir" ]; then
        unset _df_latest _df_dir
        return 0
    fi

    if ! df_confirm "Restore files from backup $_df_dir into \$HOME?"; then
        log_info "Skipping backup restore"
        unset _df_latest _df_dir
        return 0
    fi

    log_step "Restoring from $_df_dir"
    for _df_item in "$_df_dir"/*; do
        [ -e "$_df_item" ] || continue
        _df_base=$(basename "$_df_item")
        # Strip numeric collision suffixes like .1 .2
        _df_name=$(printf '%s' "$_df_base" | sed 's/\.[0-9][0-9]*$//')
        _df_dest="$HOME/$_df_name"
        if [ -e "$_df_dest" ] || [ -L "$_df_dest" ]; then
            log_warn "Destination exists, skip restore: $_df_dest"
            continue
        fi
        if [ "$DOTFILES_DRY_RUN" = "1" ]; then
            log_dry "Would restore $_df_item -> $_df_dest"
        else
            cp -a "$_df_item" "$_df_dest"
            log_success "Restored $_df_dest"
        fi
    done
    unset _df_latest _df_dir _df_item _df_base _df_name _df_dest
}

df_note_packages() {
    if [ "$NOTE_PACKAGES" != "1" ]; then
        return 0
    fi
    log_step "Packages recorded in journal (not removed)"
    if [ -f "$DOTFILES_JOURNAL" ]; then
        grep '^package|' "$DOTFILES_JOURNAL" 2>/dev/null || log_info "(none in current journal)"
    fi
    # Also scan rotated journals
    for _df_j in "${DOTFILES_JOURNAL}".*; do
        [ -f "$_df_j" ] || continue
        grep '^package|' "$_df_j" 2>/dev/null || true
    done
    log_info "Remove packages manually with your package manager if desired"
    unset _df_j
}

df_cleanup_state() {
    log_step "Cleaning installer state"
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would clear ${DOTFILES_STATE_DIR}/symlinks.list managed.list loaders/"
        return 0
    fi
    rm -f "${DOTFILES_STATE_DIR}/symlinks.list" \
          "${DOTFILES_STATE_DIR}/managed.list" 2>/dev/null || true
    rm -rf "${DOTFILES_STATE_DIR}/loaders" 2>/dev/null || true
    log_success "State cleaned (manifest/journal retained for audit)"
}

main() {
    parse_args "$@"
    _df_setup_colors
    df_init_state_dirs
    df_detect_os

    log_header "Dotfiles uninstaller v${DOTFILES_INSTALLER_VERSION}"

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_warn "DRY-RUN mode"
    fi

    if ! df_confirm "Remove managed dotfiles configuration from \$HOME?"; then
        log_info "Aborted"
        exit 0
    fi

    # Prefer journal rollback when available (precise reverse of last install).
    if [ -f "$DOTFILES_JOURNAL" ]; then
        log_step "Rolling back last install journal"
        df_rollback "uninstall" || true
    fi

    df_uninstall_symlinks
    df_uninstall_managed_blocks
    df_restore_latest_backup
    df_note_packages
    df_cleanup_state

    log_success "Uninstall complete"
    log_info "Repository at $DOTFILES_ROOT was left intact"
    log_info "Local overrides (*.local) were left intact"
}

main "$@"
