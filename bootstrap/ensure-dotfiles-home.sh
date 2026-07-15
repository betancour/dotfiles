# ensure-dotfiles-home.sh — place repository at ~/.dotfiles
# shellcheck shell=sh
#
# Strategy (idempotent):
#   1. If DOTFILES_ROOT is already $HOME/.dotfiles → done.
#   2. If ~/.dotfiles is missing → symlink DOTFILES_ROOT → ~/.dotfiles
#      (or copy when DOTFILES_COPY_HOME=1).
#   3. If ~/.dotfiles exists and is a different path:
#        - matching content / symlink to us → OK
#        - otherwise warn and keep using DOTFILES_ROOT unless --force
#
# Expects: DOTFILES_ROOT, logging helpers, common helpers.

df_ensure_dotfiles_home() {
    _df_canonical="${DOTFILES_CANONICAL_HOME:-$HOME/.dotfiles}"
    _df_root="${DOTFILES_ROOT}"

    if [ -z "$_df_root" ]; then
        log_error "DOTFILES_ROOT is not set"
        unset _df_canonical _df_root
        return 1
    fi

    # Normalize for comparison.
    _df_root_abs=$(df_realpath "$_df_root")
    _df_canon_abs=$(df_realpath "$_df_canonical" 2>/dev/null || printf '%s' "$_df_canonical")

    if [ "$_df_root_abs" = "$_df_canon_abs" ]; then
        log_verbose "Repository already at canonical path: $_df_canonical"
        DOTFILES_ROOT=$_df_root_abs
        unset _df_canonical _df_root _df_root_abs _df_canon_abs
        return 0
    fi

    if [ -L "$_df_canonical" ]; then
        _df_link=$(readlink "$_df_canonical" 2>/dev/null || true)
        _df_link_abs=$(df_realpath "$_df_link" 2>/dev/null || printf '%s' "$_df_link")
        if [ "$_df_link_abs" = "$_df_root_abs" ]; then
            log_info "Canonical home symlink OK: $_df_canonical -> $_df_root_abs"
            DOTFILES_ROOT=$_df_root_abs
            unset _df_canonical _df_root _df_root_abs _df_canon_abs _df_link _df_link_abs
            return 0
        fi
        log_warn "\$HOME/.dotfiles points elsewhere ($_df_link)"
        if [ "$DOTFILES_FORCE" = "1" ]; then
            if [ "$DOTFILES_DRY_RUN" = "1" ]; then
                log_dry "Would repoint $_df_canonical -> $_df_root_abs"
            else
                rm -f "$_df_canonical"
                ln -s "$_df_root_abs" "$_df_canonical"
                df_journal_record "symlink|${_df_canonical}|${_df_root_abs}|"
                log_success "Repointed $_df_canonical -> $_df_root_abs"
            fi
        else
            log_warn "Keeping existing ~/.dotfiles; using $_df_root_abs as DOTFILES_ROOT"
            DOTFILES_ROOT=$_df_root_abs
            unset _df_canonical _df_root _df_root_abs _df_canon_abs _df_link _df_link_abs
            return 0
        fi
    elif [ -d "$_df_canonical" ]; then
        log_warn "$_df_canonical already exists as a directory (not our symlink)"
        log_warn "Using repository at $_df_root_abs"
        DOTFILES_ROOT=$_df_root_abs
        unset _df_canonical _df_root _df_root_abs _df_canon_abs
        return 0
    elif [ -e "$_df_canonical" ]; then
        log_error "$_df_canonical exists and is not a directory/symlink"
        unset _df_canonical _df_root _df_root_abs _df_canon_abs
        return 1
    else
        # Create ~/.dotfiles → repo
        if [ "${DOTFILES_COPY_HOME:-0}" = "1" ]; then
            log_info "Copying repository to $_df_canonical"
            if [ "$DOTFILES_DRY_RUN" = "1" ]; then
                log_dry "Would cp -a $_df_root_abs $_df_canonical"
            else
                cp -a "$_df_root_abs" "$_df_canonical" || {
                    log_error "Failed to copy to $_df_canonical"
                    unset _df_canonical _df_root _df_root_abs _df_canon_abs
                    return 1
                }
                df_journal_record "mkdir|$_df_canonical"
                DOTFILES_ROOT=$(df_realpath "$_df_canonical")
                log_success "Copied repository to $_df_canonical"
            fi
        else
            log_info "Creating $_df_canonical -> $_df_root_abs"
            if [ "$DOTFILES_DRY_RUN" = "1" ]; then
                log_dry "Would ln -s $_df_root_abs $_df_canonical"
            else
                ln -s "$_df_root_abs" "$_df_canonical" || {
                    log_error "Failed to create $_df_canonical"
                    unset _df_canonical _df_root _df_root_abs _df_canon_abs
                    return 1
                }
                df_journal_record "symlink|${_df_canonical}|${_df_root_abs}|"
                log_success "$_df_canonical -> $_df_root_abs"
            fi
            DOTFILES_ROOT=$_df_root_abs
        fi
    fi

    unset _df_canonical _df_root _df_root_abs _df_canon_abs _df_link _df_link_abs
    return 0
}
