# symlink.sh — safe, idempotent symlink + backup helpers
# shellcheck shell=sh

# Active backup directory for this install run (set by df_ensure_backup_dir).
DF_BACKUP_DIR=

df_ensure_backup_dir() {
    if [ -n "$DF_BACKUP_DIR" ] && [ -d "$DF_BACKUP_DIR" ]; then
        return 0
    fi
    DF_BACKUP_DIR="${DOTFILES_BACKUP_ROOT}/$(df_timestamp)"
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would create backup dir: $DF_BACKUP_DIR"
        return 0
    fi
    mkdir -p "$DF_BACKUP_DIR" || die "Cannot create backup directory: $DF_BACKUP_DIR"
    log_verbose "Backup directory: $DF_BACKUP_DIR"
    df_journal_record "mkdir|$DF_BACKUP_DIR"
    df_manifest_add backup_dir "$DF_BACKUP_DIR"
}

# Backup an existing path into DF_BACKUP_DIR. Prints backup path on stdout.
df_backup_path() {
    _df_path=$1
    _df_base=$(basename "$_df_path")
    df_ensure_backup_dir

    _df_dest_bak="${DF_BACKUP_DIR}/${_df_base}"
    # Avoid collisions within the same run.
    _df_n=1
    while [ -e "$_df_dest_bak" ]; do
        _df_dest_bak="${DF_BACKUP_DIR}/${_df_base}.${_df_n}"
        _df_n=$((_df_n + 1))
    done

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would backup $_df_path -> $_df_dest_bak"
        printf '%s\n' "$_df_dest_bak"
        unset _df_path _df_base _df_dest_bak _df_n
        return 0
    fi

    # Move preserves symlink vs file distinction.
    mv "$_df_path" "$_df_dest_bak" || {
        log_error "Failed to backup $_df_path"
        unset _df_path _df_base _df_dest_bak _df_n
        return 1
    }
    df_journal_record "backup|${_df_path}|${_df_dest_bak}"
    log_warn "Backed up $(basename "$_df_path") -> $_df_dest_bak"
    printf '%s\n' "$_df_dest_bak"
    unset _df_path _df_base _df_dest_bak _df_n
}

# Link src -> dest.
# Behavior:
#   - Missing src → error
#   - Correct existing symlink → no-op (idempotent)
#   - Wrong symlink / regular file:
#       * --force: backup + replace
#       * --yes: backup + replace (after implicit confirm)
#       * interactive: confirm
#       * non-interactive without force: skip with warning
# Returns 0 on success/skip-ok, 1 on hard failure.
df_link_file() {
    _df_src=$1
    _df_dest=$2
    _df_bak_path=

    if [ ! -e "$_df_src" ] && [ ! -L "$_df_src" ]; then
        log_error "Missing source: $_df_src"
        unset _df_src _df_dest _df_bak_path
        return 1
    fi

    # Resolve src to absolute for stable comparison.
    _df_src_abs=$(df_realpath "$_df_src")

    if [ -L "$_df_dest" ]; then
        _df_cur=$(readlink "$_df_dest" 2>/dev/null || true)
        # Compare both raw and realpath forms.
        if [ "$_df_cur" = "$_df_src" ] || [ "$_df_cur" = "$_df_src_abs" ]; then
            log_verbose "unchanged: $_df_dest"
            log_info "unchanged: $_df_dest"
            unset _df_src _df_dest _df_bak_path _df_src_abs _df_cur
            return 0
        fi
        # Also accept if both resolve to the same path.
        if [ -e "$_df_cur" ]; then
            _df_cur_abs=$(df_realpath "$_df_cur" 2>/dev/null || echo "$_df_cur")
            if [ "$_df_cur_abs" = "$_df_src_abs" ]; then
                log_info "unchanged: $_df_dest"
                unset _df_src _df_dest _df_bak_path _df_src_abs _df_cur _df_cur_abs
                return 0
            fi
            unset _df_cur_abs
        fi
        if ! df_should_replace "$_df_dest"; then
            log_warn "Skipping existing symlink: $_df_dest (use --force to replace)"
            unset _df_src _df_dest _df_bak_path _df_src_abs _df_cur
            return 0
        fi
        _df_bak_path=$(df_backup_path "$_df_dest") || {
            unset _df_src _df_dest _df_bak_path _df_src_abs _df_cur
            return 1
        }
    elif [ -e "$_df_dest" ]; then
        if ! df_should_replace "$_df_dest"; then
            log_warn "Skipping existing file: $_df_dest (use --force or --append)"
            unset _df_src _df_dest _df_bak_path _df_src_abs
            return 0
        fi
        _df_bak_path=$(df_backup_path "$_df_dest") || {
            unset _df_src _df_dest _df_bak_path _df_src_abs
            return 1
        }
    fi

    # Ensure parent directory exists.
    _df_parent=$(dirname "$_df_dest")
    if [ ! -d "$_df_parent" ]; then
        if [ "$DOTFILES_DRY_RUN" = "1" ]; then
            log_dry "Would mkdir -p $_df_parent"
        else
            mkdir -p "$_df_parent" || {
                log_error "Cannot create parent: $_df_parent"
                unset _df_src _df_dest _df_bak_path _df_src_abs _df_parent
                return 1
            }
            df_journal_record "mkdir|$_df_parent"
        fi
    fi

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "ln -s $_df_src_abs -> $_df_dest"
        unset _df_src _df_dest _df_bak_path _df_src_abs _df_cur _df_parent
        return 0
    fi

    ln -s "$_df_src_abs" "$_df_dest" || {
        log_error "Failed to link $_df_dest -> $_df_src_abs"
        # Best-effort restore
        if [ -n "$_df_bak_path" ] && [ -e "$_df_bak_path" ]; then
            mv "$_df_bak_path" "$_df_dest" 2>/dev/null || true
        fi
        unset _df_src _df_dest _df_bak_path _df_src_abs _df_cur _df_parent
        return 1
    }

    df_journal_record "symlink|${_df_dest}|${_df_src_abs}|${_df_bak_path}"
    # Track for uninstall.
    if [ "$DOTFILES_DRY_RUN" != "1" ]; then
        printf '%s\n' "$_df_dest" >>"${DOTFILES_STATE_DIR}/symlinks.list"
    fi
    log_success "$(basename "$_df_dest") -> $_df_src_abs"
    unset _df_src _df_dest _df_bak_path _df_src_abs _df_cur _df_parent
    return 0
}

# Decide whether to replace an existing path.
df_should_replace() {
    _df_target=$1
    if [ "$DOTFILES_FORCE" = "1" ]; then
        unset _df_target
        return 0
    fi
    if [ "$DOTFILES_YES" = "1" ]; then
        unset _df_target
        return 0
    fi
    if [ -t 0 ]; then
        if df_confirm "Replace existing $_df_target (will backup)?"; then
            unset _df_target
            return 0
        fi
        unset _df_target
        return 1
    fi
    # Non-interactive without force/yes: do not clobber.
    unset _df_target
    return 1
}

# Install a template only when destination is missing.
df_install_template() {
    _df_template=$1
    _df_dest=$2

    if [ ! -f "$_df_template" ]; then
        log_verbose "Template missing (skip): $_df_template"
        unset _df_template _df_dest
        return 0
    fi
    if [ -e "$_df_dest" ]; then
        log_verbose "Template dest exists (skip): $_df_dest"
        unset _df_template _df_dest
        return 0
    fi

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would copy template $_df_template -> $_df_dest"
        unset _df_template _df_dest
        return 0
    fi

    _df_parent=$(dirname "$_df_dest")
    [ -d "$_df_parent" ] || mkdir -p "$_df_parent"
    cp "$_df_template" "$_df_dest" || {
        log_error "Failed to install template: $_df_dest"
        unset _df_template _df_dest _df_parent
        return 1
    }
    df_journal_record "copy|${_df_dest}|${_df_template}"
    log_success "created $(basename "$_df_dest") from template"
    unset _df_template _df_dest _df_parent
    return 0
}

# Remove a symlink only if it points into our dotfiles tree.
df_unlink_if_ours() {
    _df_dest=$1
    _df_root=${2:-$DOTFILES_ROOT}

    if [ ! -L "$_df_dest" ]; then
        log_verbose "Not a symlink (skip remove): $_df_dest"
        unset _df_dest _df_root
        return 0
    fi
    _df_cur=$(readlink "$_df_dest" 2>/dev/null || true)
    # Match current root, canonical ~/.dotfiles, and legacy paths from older layouts.
    case "$_df_cur" in
        "$_df_root"/*|"$DOTFILES_CANONICAL_HOME"/*|"$HOME/dotfiles"/*|"$HOME/Development/dotfiles"/*)
            if [ "$DOTFILES_DRY_RUN" = "1" ]; then
                log_dry "Would remove symlink $_df_dest"
            else
                rm -f "$_df_dest"
                log_success "Removed symlink: $_df_dest"
            fi
            ;;
        *)
            log_warn "Leaving non-dotfiles symlink: $_df_dest -> $_df_cur"
            ;;
    esac
    unset _df_dest _df_root _df_cur
}
