# xdg.sh — XDG Base Directory setup

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Only set XDG_RUNTIME_DIR when the system has not already provided one.
if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    _xdg_uid="${UID:-$(id -u 2>/dev/null)}"
    if [ -n "$_xdg_uid" ] && [ -d "/tmp/runtime-${_xdg_uid}" ]; then
        export XDG_RUNTIME_DIR="/tmp/runtime-${_xdg_uid}"
    fi
    unset _xdg_uid
fi

# mkdir only when missing. umask 077 (environment.sh) makes new dirs 700;
# skip chmod on the existing-dir hot path.
for _xdg_dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
    if [ ! -d "$_xdg_dir" ]; then
        mkdir -p "$_xdg_dir"
        chmod 700 "$_xdg_dir" 2>/dev/null || true
    fi
done
unset _xdg_dir
