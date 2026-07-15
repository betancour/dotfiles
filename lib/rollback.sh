# rollback.sh — journal-based install rollback
# shellcheck shell=sh
#
# Journal format (one action per line):
#   symlink|<dest>|<src>|<backup_path_or_EMPTY>
#   backup|<original_path>|<backup_path>
#   managed_block|<file_path>
#   mkdir|<path>
#   package|<pkg_manager>|<package_name>
#   copy|<dest>|<src>

df_journal_init() {
    df_init_state_dirs
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        return 0
    fi
    # Rotate previous journal.
    if [ -f "$DOTFILES_JOURNAL" ]; then
        mv "$DOTFILES_JOURNAL" "${DOTFILES_JOURNAL}.$(df_timestamp)" 2>/dev/null || true
    fi
    : >"$DOTFILES_JOURNAL"
    log_verbose "Journal: $DOTFILES_JOURNAL"
}

df_journal_record() {
    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        return 0
    fi
    df_init_state_dirs
    # shellcheck disable=SC2145
    printf '%s\n' "$*" >>"$DOTFILES_JOURNAL"
}

# Attempt to reverse journal entries in reverse order.
df_rollback() {
    _df_reason=${1:-installation failure}
    log_warn "Rolling back changes ($_df_reason)..."

    if [ ! -f "$DOTFILES_JOURNAL" ]; then
        log_warn "No journal found; nothing to roll back"
        return 0
    fi

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would roll back actions from $DOTFILES_JOURNAL"
        return 0
    fi

    # Process last-to-first.
    _df_tmp="${DOTFILES_STATE_DIR}/journal.reverse"
    # portable reverse: awk
    awk '{ lines[NR]=$0 } END { for (i=NR; i>0; i--) print lines[i] }' \
        "$DOTFILES_JOURNAL" >"$_df_tmp" 2>/dev/null || {
        log_error "Failed to reverse journal"
        unset _df_reason _df_tmp
        return 1
    }

    _df_ok=0
    _df_fail=0
    while IFS= read -r _df_line || [ -n "$_df_line" ]; do
        [ -z "$_df_line" ] && continue
        _df_action=$(printf '%s' "$_df_line" | cut -d'|' -f1)
        case "$_df_action" in
            symlink)
                _df_dest=$(printf '%s' "$_df_line" | cut -d'|' -f2)
                _df_src=$(printf '%s' "$_df_line" | cut -d'|' -f3)
                _df_bak=$(printf '%s' "$_df_line" | cut -d'|' -f4)
                if [ -L "$_df_dest" ]; then
                    _df_cur=$(readlink "$_df_dest" 2>/dev/null || true)
                    if [ "$_df_cur" = "$_df_src" ]; then
                        rm -f "$_df_dest"
                        log_verbose "Removed symlink: $_df_dest"
                    fi
                fi
                if [ -n "$_df_bak" ] && [ -e "$_df_bak" ] && [ ! -e "$_df_dest" ]; then
                    mv "$_df_bak" "$_df_dest"
                    log_verbose "Restored backup: $_df_dest"
                fi
                _df_ok=$((_df_ok + 1))
                ;;
            backup)
                # backup|original|backup_path — restore if original missing
                _df_orig=$(printf '%s' "$_df_line" | cut -d'|' -f2)
                _df_bak=$(printf '%s' "$_df_line" | cut -d'|' -f3)
                if [ -e "$_df_bak" ] && [ ! -e "$_df_orig" ]; then
                    mv "$_df_bak" "$_df_orig"
                    log_verbose "Restored: $_df_orig"
                    _df_ok=$((_df_ok + 1))
                fi
                ;;
            managed_block)
                _df_file=$(printf '%s' "$_df_line" | cut -d'|' -f2)
                if [ -f "$_df_file" ]; then
                    df_remove_managed_block "$_df_file" || true
                    _df_ok=$((_df_ok + 1))
                fi
                ;;
            mkdir)
                # Do not remove directories on rollback — may contain user data.
                log_verbose "Skip mkdir rollback: $(printf '%s' "$_df_line" | cut -d'|' -f2)"
                ;;
            package)
                log_verbose "Package installs are not auto-uninstalled: $_df_line"
                ;;
            copy)
                _df_dest=$(printf '%s' "$_df_line" | cut -d'|' -f2)
                if [ -f "$_df_dest" ] || [ -L "$_df_dest" ]; then
                    rm -f "$_df_dest"
                    log_verbose "Removed copy: $_df_dest"
                    _df_ok=$((_df_ok + 1))
                fi
                ;;
            *)
                log_verbose "Unknown journal action: $_df_action"
                _df_fail=$((_df_fail + 1))
                ;;
        esac
    done <"$_df_tmp"
    rm -f "$_df_tmp"

    log_warn "Rollback finished (restored≈$_df_ok, skipped/unknown≈$_df_fail)"
    unset _df_reason _df_tmp _df_ok _df_fail _df_line _df_action
    unset _df_dest _df_src _df_bak _df_cur _df_orig _df_file
}
