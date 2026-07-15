#!/bin/sh
# install.sh — production-quality dotfiles installer
#
# POSIX /bin/sh. Modular libraries under lib/. Idempotent. Safe by default.
#
# Usage:
#   ./install.sh [options] [zsh|bash|sh|both|all|auto]
#
# Options:
#   -h, --help          Show help
#   -v, --verbose       Verbose / debug logging
#   -n, --dry-run       Show actions without changing the system
#   -f, --force         Replace existing files (after backup)
#   -y, --yes           Assume yes for confirmations
#   -a, --append        Append managed blocks instead of full symlinks
#   --skip-deps         Do not install packages
#   --only-deps         Only install packages, skip config linking
#   --no-optional       Skip optional packages (starship, shellcheck)
#   --no-git            Skip gitconfig install
#   --no-vim            Skip vimrc install
#   --shell SHELL       Target shell (same as positional)
#   --color WHEN        auto|always|never
#   --version           Print installer version
#
# Environment:
#   DOTFILES_SHELL, DOTFILES_VERBOSE, DOTFILES_FORCE, DOTFILES_DRY_RUN, …
#
# shellcheck shell=sh
# shellcheck source=/dev/null

set -eu

# ---------------------------------------------------------------------------
# Resolve repository root (directory containing this script)
# ---------------------------------------------------------------------------
DOTFILES_ROOT=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
export DOTFILES_ROOT

# ---------------------------------------------------------------------------
# Load libraries (order matters)
# ---------------------------------------------------------------------------
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/logging.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/common.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/detect.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/rollback.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/symlink.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/managed.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/package.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/deps.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/shell_install.sh"
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/bootstrap/ensure-dotfiles-home.sh"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
SHELL_ARG="${DOTFILES_SHELL:-auto}"
ONLY_DEPS=0
SKIP_GIT=0
SKIP_VIM=0
INSTALL_FAILED=0

usage() {
    cat <<EOF
${C_BOLD}dotfiles installer${C_RST} v${DOTFILES_INSTALLER_VERSION}

${C_BOLD}Usage:${C_RST}
  ./install.sh [options] [zsh|bash|sh|both|all|auto]

${C_BOLD}Shell targets:${C_RST}
  auto   Detect from \$SHELL (default)
  zsh    Zsh only
  bash   Bash only
  sh     POSIX sh (.profile) only
  both   Bash + Zsh
  all    Bash + Zsh + sh

${C_BOLD}Options:${C_RST}
  -h, --help         Show this help
  -v, --verbose      Verbose logging
  -n, --dry-run      Print actions; do not modify the system
  -f, --force        Backup and replace conflicting files
  -y, --yes          Non-interactive yes to prompts
  -a, --append       Inject managed source blocks (keep user files)
  --skip-deps        Skip package installation
  --only-deps        Only install packages
  --no-optional      Skip starship / shellcheck
  --no-git           Skip git configuration
  --no-vim           Skip vim configuration
  --shell NAME       Same as positional shell target
  --color WHEN       auto | always | never
  --version          Print version and exit

${C_BOLD}Model:${C_RST}
  - Canonical source of truth: ~/.dotfiles (real Git directory, not a symlink)
  - Installer must run from ~/.dotfiles (or will offer to move the repo there)
  - \$HOME only receives symbolic links pointing into ~/.dotfiles

${C_BOLD}Safety:${C_RST}
  - Idempotent: correct symlinks are left alone
  - Existing files are never overwritten without --force / --yes / confirm
  - Backups land in ~/.dotfiles_backups/<timestamp>/
  - On failure, journaled changes are rolled back when possible

${C_BOLD}Examples:${C_RST}
  ./install.sh
  ./install.sh --dry-run both
  ./install.sh --force --yes zsh
  ./install.sh --append bash
  ./install.sh --only-deps
  ./install.sh --skip-deps --shell all
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                printf '%s\n' "$DOTFILES_INSTALLER_VERSION"
                exit 0
                ;;
            -v|--verbose)
                DOTFILES_VERBOSE=1
                export DOTFILES_VERBOSE
                shift
                ;;
            -n|--dry-run)
                DOTFILES_DRY_RUN=1
                export DOTFILES_DRY_RUN
                shift
                ;;
            -f|--force)
                DOTFILES_FORCE=1
                export DOTFILES_FORCE
                shift
                ;;
            -y|--yes)
                DOTFILES_YES=1
                export DOTFILES_YES
                shift
                ;;
            -a|--append)
                DOTFILES_APPEND=1
                export DOTFILES_APPEND
                shift
                ;;
            --skip-deps)
                DOTFILES_SKIP_DEPS=1
                export DOTFILES_SKIP_DEPS
                shift
                ;;
            --only-deps)
                ONLY_DEPS=1
                shift
                ;;
            --no-optional)
                DOTFILES_WITH_OPTIONAL=0
                export DOTFILES_WITH_OPTIONAL
                shift
                ;;
            --no-git)
                SKIP_GIT=1
                shift
                ;;
            --no-vim)
                SKIP_VIM=1
                shift
                ;;
            --shell)
                if [ -z "${2:-}" ]; then
                    die "--shell requires an argument"
                fi
                SHELL_ARG=$2
                shift 2
                ;;
            --shell=*)
                SHELL_ARG=${1#--shell=}
                shift
                ;;
            --color)
                if [ -z "${2:-}" ]; then
                    die "--color requires auto|always|never"
                fi
                DOTFILES_COLOR=$2
                export DOTFILES_COLOR
                _df_setup_colors
                shift 2
                ;;
            --color=*)
                DOTFILES_COLOR=${1#--color=}
                export DOTFILES_COLOR
                _df_setup_colors
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                die "Unknown option: $1 (try --help)"
                ;;
            zsh|bash|sh|both|all|auto)
                SHELL_ARG=$1
                shift
                ;;
            *)
                die "Unexpected argument: $1 (try --help)"
                ;;
        esac
    done

    if [ "$#" -gt 0 ]; then
        die "Unexpected arguments: $*"
    fi
}

# Sanity checks before mutating the system.
df_preflight() {
    log_step "Preflight checks"

    if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ]; then
        die "HOME is unset or not a directory"
    fi

    if [ ! -d "$DOTFILES_ROOT" ]; then
        die "DOTFILES_ROOT is not a directory: $DOTFILES_ROOT"
    fi

    if [ ! -d "${DOTFILES_ROOT}/shell" ]; then
        die "Invalid repository layout: missing shell/ under $DOTFILES_ROOT"
    fi

    if [ ! -d "${DOTFILES_ROOT}/lib" ]; then
        die "Invalid repository layout: missing lib/ under $DOTFILES_ROOT"
    fi

    # Critical utilities
    for _df_req in ln mkdir mv cp date uname; do
        if ! df_has_cmd "$_df_req"; then
            die "Required utility not found: $_df_req"
        fi
    done

    # Write access to HOME
    if [ ! -w "$HOME" ]; then
        die "HOME is not writable: $HOME"
    fi

    log_success "Preflight OK"
    unset _df_req
}

# Trap handler for unexpected failures.
df_on_error() {
    _df_ec=$?
    if [ "$_df_ec" -ne 0 ] && [ "$INSTALL_FAILED" != "1" ]; then
        INSTALL_FAILED=1
        log_error "Install aborted (exit $_df_ec)"
        if [ "$DOTFILES_DRY_RUN" != "1" ]; then
            df_rollback "exit $_df_ec" || true
        fi
    fi
    unset _df_ec
}

df_install_main() {
    log_header "Dotfiles installer v${DOTFILES_INSTALLER_VERSION}"

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_warn "DRY-RUN mode — no changes will be written"
    fi

    df_preflight
    df_init_state_dirs

    # Detection
    log_step "Detecting environment"
    df_detect_all "$SHELL_ARG"
    # Re-apply shell from resolved detection when auto
    if [ "$SHELL_ARG" = "auto" ]; then
        SHELL_ARG=$DF_SHELL_TYPE
    else
        DF_SHELL_TYPE=$SHELL_ARG
    fi
    df_print_detection_summary

    df_version_checks

    # Journal + manifest
    df_journal_init
    df_manifest_init

    # Enforce canonical repository at ~/.dotfiles (physical dir, not a symlink)
    log_step "Resolving repository root"
    df_ensure_dotfiles_home || die "Repository must live at ~/.dotfiles"
    export DOTFILES_ROOT
    df_manifest_add dotfiles_root "$DOTFILES_ROOT"

    # Dependencies
    df_install_dependencies

    if [ "$ONLY_DEPS" = "1" ]; then
        log_success "Dependency-only install complete"
        return 0
    fi

    # Shell configuration
    df_install_shell "$SHELL_ARG" || {
        INSTALL_FAILED=1
        df_rollback "shell install failed"
        die "Shell configuration install failed"
    }

    # Ancillary configs
    if [ "$SKIP_GIT" != "1" ]; then
        df_install_git || log_warn "Git config install had issues"
    fi
    if [ "$SKIP_VIM" != "1" ]; then
        df_install_vim || log_warn "Vim config install had issues"
    fi
    df_install_starship_config || true
    df_install_alacritty_config || true

    # Summary
    log_step "Summary"
    if [ -n "${DF_BACKUP_DIR:-}" ] && [ -d "${DF_BACKUP_DIR:-}" ]; then
        log_warn "Backups: $DF_BACKUP_DIR"
    fi
    log_info "Manifest: $DOTFILES_MANIFEST"
    log_info "Journal:  $DOTFILES_JOURNAL"
    log_info "Log:      $DOTFILES_LOG_FILE"
    log_success "Installation complete"
    log_info "Restart your shell: exec \"\${SHELL:-/bin/sh}\" -l"
}

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"

    # Re-init colors after possible --color
    _df_setup_colors

    # Error trap (best-effort; not all POSIX sh honor ERR)
    trap 'df_on_error' EXIT
    # Enable pipefail when the shell supports it (bash/zsh; not strict POSIX).
    # shellcheck disable=SC3040
    set -o pipefail 2>/dev/null || true

    df_install_main

    # Clear EXIT trap on success so we don't roll back.
    trap - EXIT
    INSTALL_FAILED=0
}

main "$@"
