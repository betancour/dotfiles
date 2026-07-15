# common.sh — shared constants, paths, and small utilities
# shellcheck shell=sh
# Sourced by install.sh / uninstall.sh. Requires DOTFILES_ROOT to be set.

# Version of the installer itself (semver).
DOTFILES_INSTALLER_VERSION="2.1.0"

# Canonical repository location: a real physical directory at ~/.dotfiles.
# Never a symlink. All $HOME config links point into this tree.
DOTFILES_CANONICAL_HOME="${DOTFILES_CANONICAL_HOME:-$HOME/.dotfiles}"

# State / backup locations (XDG-aware).
DOTFILES_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
DOTFILES_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
DOTFILES_BACKUP_ROOT="${DOTFILES_BACKUP_ROOT:-$HOME/.dotfiles_backups}"
# Used by rollback.sh / install.sh / uninstall.sh (exported for sourced modules).
# shellcheck disable=SC2034
DOTFILES_JOURNAL="${DOTFILES_STATE_DIR}/install.journal"
DOTFILES_MANIFEST="${DOTFILES_STATE_DIR}/install.manifest"
DOTFILES_LOG_FILE="${DOTFILES_LOG_FILE:-${DOTFILES_STATE_DIR}/install.log}"

# Managed block markers (append mode). Used by managed.sh.
# shellcheck disable=SC2034
DOTFILES_MANAGED_BEGIN="# >>> DOTFILES MANAGED BLOCK (do not edit) >>>"
# shellcheck disable=SC2034
DOTFILES_MANAGED_END="# <<< DOTFILES MANAGED BLOCK <<<"

# Feature flags (overridden by CLI).
DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-0}"
DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-0}"
DOTFILES_FORCE="${DOTFILES_FORCE:-0}"
DOTFILES_YES="${DOTFILES_YES:-0}"
DOTFILES_APPEND="${DOTFILES_APPEND:-0}"
DOTFILES_SKIP_DEPS="${DOTFILES_SKIP_DEPS:-0}"
DOTFILES_WITH_OPTIONAL="${DOTFILES_WITH_OPTIONAL:-1}"
DOTFILES_COLOR="${DOTFILES_COLOR:-auto}"

# Ensure a directory exists (respects dry-run).
df_mkdir_p() {
    _df_dir=$1
    if [ -d "$_df_dir" ]; then
        unset _df_dir
        return 0
    fi
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "mkdir -p $_df_dir"
        unset _df_dir
        return 0
    fi
    mkdir -p "$_df_dir" || {
        log_error "Failed to create directory: $_df_dir"
        unset _df_dir
        return 1
    }
    unset _df_dir
}

# Absolute path of a file/dir (portable; falls back to cd/pwd).
df_realpath() {
    _df_target=$1
    if command -v realpath >/dev/null 2>&1; then
        realpath "$_df_target" 2>/dev/null && { unset _df_target; return 0; }
    fi
    if command -v readlink >/dev/null 2>&1; then
        # GNU readlink -f
        readlink -f "$_df_target" 2>/dev/null && { unset _df_target; return 0; }
    fi
    if [ -d "$_df_target" ]; then
        (CDPATH='' cd -- "$_df_target" && pwd)
        _df_rc=$?
        unset _df_target
        return $_df_rc
    fi
    _df_parent=$(dirname "$_df_target")
    _df_base=$(basename "$_df_target")
    if [ -d "$_df_parent" ]; then
        printf '%s/%s\n' "$(CDPATH='' cd -- "$_df_parent" && pwd)" "$_df_base"
        unset _df_target _df_parent _df_base
        return 0
    fi
    printf '%s\n' "$_df_target"
    unset _df_target _df_parent _df_base
    return 0
}

# Return 0 if command exists.
df_has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Ask yes/no. Returns 0 for yes. Honors --yes and non-TTY (default no).
df_confirm() {
    _df_prompt=$1
    if [ "$DOTFILES_YES" = "1" ] || [ "$DOTFILES_FORCE" = "1" ]; then
        unset _df_prompt
        return 0
    fi
    if [ ! -t 0 ]; then
        log_warn "Non-interactive session; declining: $_df_prompt"
        unset _df_prompt
        return 1
    fi
    printf '%s [y/N] ' "$_df_prompt" >/dev/tty
    read -r _df_ans </dev/tty || _df_ans=n
    case "$_df_ans" in
        [yY]|[yY][eE][sS])
            unset _df_prompt _df_ans
            return 0
            ;;
        *)
            unset _df_prompt _df_ans
            return 1
            ;;
    esac
}

# ISO-ish timestamp for backups and logs.
df_timestamp() {
    date +%Y%m%d_%H%M%S 2>/dev/null || date +%Y%m%d%H%M%S
}

# Ensure state directories exist (real, not dry-run — needed for logging).
df_init_state_dirs() {
    mkdir -p "$DOTFILES_STATE_DIR" "$DOTFILES_CACHE_DIR" "$DOTFILES_BACKUP_ROOT" 2>/dev/null || true
}

# Write a key=value pair to the install manifest (overwrite file first with header).
df_manifest_init() {
    df_init_state_dirs
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        return 0
    fi
    {
        printf '# dotfiles install manifest — do not edit by hand\n'
        printf 'version=%s\n' "$DOTFILES_INSTALLER_VERSION"
        printf 'installed_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
        printf 'dotfiles_root=%s\n' "${DOTFILES_ROOT:-}"
        printf 'os=%s\n' "${DF_OS:-unknown}"
        printf 'arch=%s\n' "${DF_ARCH:-unknown}"
        printf 'pkg_manager=%s\n' "${DF_PKG_MANAGER:-unknown}"
        printf 'shell=%s\n' "${DF_SHELL_TYPE:-unknown}"
    } >"$DOTFILES_MANIFEST"
}

df_manifest_add() {
    _df_key=$1
    _df_val=$2
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        unset _df_key _df_val
        return 0
    fi
    [ -f "$DOTFILES_MANIFEST" ] || df_manifest_init
    # Remove existing key then append (idempotent).
    if [ -f "$DOTFILES_MANIFEST" ]; then
        _df_tmp="${DOTFILES_MANIFEST}.tmp"
        grep -v "^${_df_key}=" "$DOTFILES_MANIFEST" >"$_df_tmp" 2>/dev/null || true
        mv "$_df_tmp" "$DOTFILES_MANIFEST"
    fi
    printf '%s=%s\n' "$_df_key" "$_df_val" >>"$DOTFILES_MANIFEST"
    unset _df_key _df_val _df_tmp
}

# Minimal require: abort if empty.
df_require() {
    _df_name=$1
    _df_val=$2
    if [ -z "$_df_val" ]; then
        log_error "Required value missing: $_df_name"
        unset _df_name _df_val
        return 1
    fi
    unset _df_name _df_val
    return 0
}
