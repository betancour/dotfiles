# invoke.sh — launch a real shell and keep the captured streams.

df_run() {
    local mode=$1
    shift
    DF_OUT=$SB_ROOT/last.out
    DF_ERR=$SB_ROOT/last.err
    : > "$DF_OUT"
    : > "$DF_ERR"
    local meta
    meta=$(python3 "$DF_LIB/pty_run.py" \
        --mode "$mode" \
        --capture "$DF_OUT" \
        --stderr "$DF_ERR" \
        --cwd "$SB_CWD" \
        --env-file "$SB_ENV" \
        --timeout "${DF_TIMEOUT:-30}" \
        -- "$@" 2>"$SB_ROOT/pty.err") || meta=
    if [ -z "$meta" ]; then
        DF_RC=1
        DF_MS=0
        if [ -s "$SB_ROOT/pty.err" ]; then
            cat "$SB_ROOT/pty.err" >> "$DF_ERR"
        fi
    else
        DF_RC=${meta%% *}
        DF_MS=${meta#* }
    fi
}

df_capture() {
    local name=$1 mode=$2
    shift 2
    mkdir -p "$DF_WORK/cap"
    sb_write_env
    df_run "$mode" "$@"
    tr -d '\r' < "$DF_OUT" > "$DF_WORK/cap/$name.out"
    tr -d '\r' < "$DF_ERR" > "$DF_WORK/cap/$name.err"
    printf '%s %s\n' "$DF_RC" "$DF_MS" > "$DF_WORK/cap/$name.meta"
    printf '%s\n' "$SB_HOME" > "$DF_WORK/cap/$name.home"
}

df_meta_rc() {
    local meta
    meta=$(cat "$DF_WORK/cap/$1.meta")
    printf '%s\n' "${meta%% *}"
}

df_probe() {
    # $1 capture name  $2 field. Last occurrence wins (behavior lines repeat defaults).
    awk -v k="$2" '
        $0 == "DF_PROBE_BEGIN" { p = 1; next }
        $0 == "DF_PROBE_END" { p = 0 }
        p && index($0, k "=") == 1 { v = substr($0, length(k) + 2) }
        END { print v }
    ' "$DF_WORK/cap/$1.out"
}

df_probe_block() {
    # $1 capture  $2 begin  $3 end  $4 dest  $5 home to rewrite
    local home=$5
    awk -v s="$2" -v e="$3" '
        $0 == s { p = 1; next }
        $0 == e { p = 0 }
        p { print }
    ' "$DF_WORK/cap/$1.out" | sed \
        -e "s|$home|~|g" \
        -e "s|$HOME|~|g" > "$4"
}

df_tilde_file() {
    local home=$2
    sed -e "s|$home|~|g" -e "s|$HOME|~|g" "$1"
}
