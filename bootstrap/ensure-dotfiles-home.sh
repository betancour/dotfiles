# ensure-dotfiles-home.sh — enforce canonical repository at ~/.dotfiles
# shellcheck shell=sh
#
# Canonical model (traditional Unix layout):
#   - ~/.dotfiles is a physical directory (never a symlink).
#   - ~/.dotfiles/.git holds Git metadata.
#   - Every tracked configuration file lives under ~/.dotfiles.
#   - Files under $HOME are only symbolic links pointing into ~/.dotfiles.
#   - There is no second copy of the repository (not ~/dotfiles, not ~/Development/...).
#
# The installer must be executed from ~/.dotfiles. If it is run from another
# path, this helper either refuses or offers to move the repository there.
#
# Expects: DOTFILES_ROOT, logging helpers, common helpers (df_realpath, df_confirm).

df_ensure_dotfiles_home() {
    _df_canonical="${DOTFILES_CANONICAL_HOME:-$HOME/.dotfiles}"
    _df_root="${DOTFILES_ROOT}"

    if [ -z "$_df_root" ]; then
        log_error "DOTFILES_ROOT is not set"
        unset _df_canonical _df_root
        return 1
    fi

    _df_root_abs=$(df_realpath "$_df_root")
    if [ ! -d "$_df_root_abs" ]; then
        log_error "DOTFILES_ROOT is not a directory: $_df_root_abs"
        unset _df_canonical _df_root _df_root_abs
        return 1
    fi

    # ~/.dotfiles must never be a symlink — even if it currently points at us.
    if [ -L "$_df_canonical" ]; then
        _df_link=$(readlink "$_df_canonical" 2>/dev/null || true)
        log_error "\$HOME/.dotfiles is a symlink (-> ${_df_link}); it must be a real directory"
        if [ "$DOTFILES_FORCE" = "1" ]; then
            if [ "$DOTFILES_DRY_RUN" = "1" ]; then
                log_dry "Would remove invalid symlink $_df_canonical"
            else
                rm -f "$_df_canonical"
                df_journal_record "unlink|${_df_canonical}|${_df_link}|"
                log_success "Removed invalid symlink $_df_canonical"
            fi
        else
            log_error "Remove it with: rm ~/.dotfiles  (or re-run with --force)"
            unset _df_canonical _df_root _df_root_abs _df_link
            return 1
        fi
        unset _df_link
    fi

    # Already at the canonical physical path.
    if [ "$_df_root_abs" = "$_df_canonical" ]; then
        if [ -L "$_df_root_abs" ]; then
            log_error "Repository path resolves as a symlink; refuse to treat it as canonical"
            unset _df_canonical _df_root _df_root_abs
            return 1
        fi
        if [ ! -e "${_df_root_abs}/.git" ]; then
            log_warn "No .git metadata at $_df_root_abs (continuing; clone may be incomplete)"
        fi
        log_verbose "Repository already at canonical path: $_df_canonical"
        DOTFILES_ROOT=$_df_root_abs
        export DOTFILES_ROOT
        unset _df_canonical _df_root _df_root_abs
        return 0
    fi

    # Running from a non-canonical location (e.g. ~/dotfiles or a clone elsewhere).
    log_warn "Installer is running from: $_df_root_abs"
    log_warn "Canonical repository location: $_df_canonical (real directory, not a symlink)"

    if [ -e "$_df_canonical" ]; then
        _df_canon_abs=$(df_realpath "$_df_canonical" 2>/dev/null || printf '%s' "$_df_canonical")
        if [ "$_df_canon_abs" = "$_df_root_abs" ]; then
            # Same inode via an alternate path name — still require the path ~/.dotfiles.
            log_error "Repository is reachable as $_df_root_abs but must live at $_df_canonical"
        else
            log_error "Refusing to proceed: $_df_canonical already exists and is not this repository"
            log_error "Keep a single copy at ~/.dotfiles and remove the other path"
        fi
        unset _df_canonical _df_root _df_root_abs _df_canon_abs
        return 1
    fi

    if [ "$DOTFILES_DRY_RUN" = "1" ]; then
        log_dry "Would move repository: $_df_root_abs -> $_df_canonical"
        log_info "Dry-run continues using the current tree; a real install will relocate first"
        DOTFILES_ROOT=$_df_root_abs
        export DOTFILES_ROOT
        unset _df_canonical _df_root _df_root_abs
        return 0
    fi

    if [ "$DOTFILES_YES" = "1" ] || [ "$DOTFILES_FORCE" = "1" ]; then
        :
    elif df_confirm "Move the repository to $_df_canonical and continue?"; then
        :
    else
        log_error "Refusing to install from a non-canonical path"
        log_error "Move it yourself:"
        log_error "  mv \"$_df_root_abs\" \"$_df_canonical\""
        log_error "  cd ~/.dotfiles && ./install.sh"
        log_error "Or re-run with --yes to move automatically"
        unset _df_canonical _df_root _df_root_abs
        return 1
    fi

    log_step "Moving repository to $_df_canonical"
    # Move the physical tree (preserves .git history and permissions).
    if ! mv "$_df_root_abs" "$_df_canonical"; then
        log_error "Failed to move repository to $_df_canonical"
        unset _df_canonical _df_root _df_root_abs
        return 1
    fi

    if [ -L "$_df_canonical" ] || [ ! -d "$_df_canonical" ]; then
        log_error "Post-move check failed: $_df_canonical is not a real directory"
        unset _df_canonical _df_root _df_root_abs
        return 1
    fi

    DOTFILES_ROOT=$(df_realpath "$_df_canonical")
    export DOTFILES_ROOT
    df_journal_record "move|${_df_root_abs}|${DOTFILES_ROOT}"
    log_success "Repository moved to $DOTFILES_ROOT (Git history preserved)"

    unset _df_canonical _df_root _df_root_abs
    return 0
}
