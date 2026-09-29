# history.zsh — Zsh history privacy hook
#
# /etc/zshrc assigns HISTFILE=~/.zsh_history and HISTSIZE=2000 after .zshenv.
# Re-apply the XDG file and the larger limits here, before SHARE_HISTORY is
# enabled, or the shell truncates history to the system sizes.

source "${DOTFILES_LIB_DIR}/history.sh"

_df_hist_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
_df_hist_file="${_df_hist_dir}/history"
_df_hist_legacy="${ZDOTDIR:-$HOME}/.zsh_history"
_df_hist_stamp="${_df_hist_dir}/history.migrated"

[[ -d $_df_hist_dir ]] || mkdir -p "$_df_hist_dir"

# One-time: real history was landing in ~/.zsh_history because of /etc/zshrc.
# Copy it over when it is the larger file, then stop checking.
if [[ -s $_df_hist_legacy && ! -f $_df_hist_stamp ]]; then
    _df_copy=0
    if [[ ! -s $_df_hist_file ]]; then
        _df_copy=1
    else
        _df_legacy_size=$(wc -c < "$_df_hist_legacy")
        _df_xdg_size=$(wc -c < "$_df_hist_file")
        _df_legacy_size=${_df_legacy_size//[[:space:]]/}
        _df_xdg_size=${_df_xdg_size//[[:space:]]/}
        [[ $_df_legacy_size -gt $_df_xdg_size ]] && _df_copy=1
        unset _df_legacy_size _df_xdg_size
    fi
    if [[ $_df_copy -eq 1 ]]; then
        # Keep the smaller XDG file. It can hold lines the legacy file does not.
        if [[ -s $_df_hist_file ]]; then
            cp "$_df_hist_file" "${_df_hist_file}.pre-migration" \
                && chmod 600 "${_df_hist_file}.pre-migration"
        fi
        if cp "$_df_hist_legacy" "$_df_hist_file" && chmod 600 "$_df_hist_file"; then
            : > "$_df_hist_stamp"
        fi
    elif [[ -s $_df_hist_file ]]; then
        : > "$_df_hist_stamp"
    fi
    unset _df_copy
fi

export HISTFILE="$_df_hist_file"
export HISTSIZE=50000
export SAVEHIST=50000
unset _df_hist_dir _df_hist_file _df_hist_legacy _df_hist_stamp

# Reject lines matching secret patterns before they enter history.
zshaddhistory() {
    emulate -L zsh
    [[ "$1" =~ "$DOTFILES_HIST_SECRET_PATTERN" ]] && return 1
    return 0
}

dotfiles_secure_history_file "$HISTFILE"
