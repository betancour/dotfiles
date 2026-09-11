# login.sh — interactive login side-effects and banners
#
# Layout (hot → cold):
#   1. guards + deps
#   2. pure formatting (no forks when avoidable)
#   3. session identity (one date max)
#   4. boot/uptime/ready collectors (prefer /proc, sysctl, builtins)
#   5. display paths (compact always-on; full banner opt-in)
#   6. optional side-effects (dev status, updates, tips)
#   7. main entry: early outs, then cost ascending
#
# Shared Bash/Zsh dialect. Keep forks off the compact start-line path.

[ -n "${DOTFILES_LOGIN_LIB_LOADED:-}" ] && return 0
DOTFILES_LOGIN_LIB_LOADED=1

. "${DOTFILES_LIB_DIR}/platform.sh"
. "${DOTFILES_LIB_DIR}/privacy.sh"
. "${DOTFILES_LIB_DIR}/ssh-agent.sh"

# =============================================================================
# Terminal / formatting
# =============================================================================

# True when stdout is a usable interactive terminal.
_dotfiles_is_tty() {
    [ -t 1 ] && [ "${TERM:-}" != dumb ]
}

# Populate SGR color variables (caller unsets).
# ANSI-C quoting ($'...') is Bash/Zsh — zero forks vs printf.
# Sets: BOLD DIM CYAN GREEN BLUE YELLOW MAGENTA RESET  (empty if non-TTY)
# One hue: every named color is green so banners match Green Phosphor off Alacritty.
_dotfiles_term_colors() {
    if _dotfiles_is_tty; then
        BOLD=$'\033[1m'
        DIM=$'\033[2m'
        GREEN=$'\033[32m'
        CYAN=$GREEN
        BLUE=$GREEN
        YELLOW=$GREEN
        MAGENTA=$GREEN
        RESET=$'\033[0m'
    else
        BOLD= DIM= CYAN= GREEN= BLUE= YELLOW= MAGENTA= RESET=
    fi
}

dotfiles_login_width() {
    _w=${COLUMNS:-}
    if [ -z "$_w" ] && command -v tput >/dev/null 2>&1; then
        _w=$(tput cols 2>/dev/null) || _w=
    fi
    _w=${_w:-80}
    [ "$_w" -gt 100 ] 2>/dev/null && _w=100
    [ "$_w" -lt 60 ] 2>/dev/null && _w=60
    printf '%s' "$_w"
    unset _w
}

# Single-pass pad fill (no per-character printf loop).
dotfiles_separator_line() {
    _char=${1:-=}
    _width=$2
    # printf width is spaces; expand in-shell (Bash/Zsh ${//}).
    _pad=$(printf '%*s' $((_width - 2)) '')
    _pad=${_pad// /$_char}
    printf '+%s+\n' "$_pad"
    unset _char _width _pad
}

dotfiles_center_text() {
    _text=$1
    _color=${2:-}
    _width=$3
    # Strip CSI for width math only (banner path; rare).
    _plain=$(printf '%s' "$_text" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' 2>/dev/null || printf '%s' "$_text")
    _plen=${#_plain}
    if [ "$_plen" -gt $((_width - 4)) ]; then
        _plain=$(printf '%s' "$_plain" | cut -c1-$((_width - 7)))...
        _plen=${#_plain}
    fi
    _pad=$(( (_width - 2 - _plen) / 2 ))
    _rpad=$(( _width - 2 - _pad - _plen ))
    if [ -n "$_color" ]; then
        printf '|%*s%s%s%s%*s|\n' "$_pad" '' "$_color" "$_plain" "${RESET:-}" "$_rpad" ''
    else
        printf '|%*s%s%*s|\n' "$_pad" '' "$_plain" "$_rpad" ''
    fi
    unset _text _color _width _plain _plen _pad _rpad
}

# Phosphor luminance ribbon (one hue). TTY only.
#_dotfiles_color_ribbon() {
#    _dotfiles_is_tty || return 0
#    printf '%s\n' $'\033[40m  \033[42m  \033[40;32m  \033[1;42m  \033[0;32m  \033[42m  \033[40m  \033[0m'
#}

# Cruz-Diez-inspired chromatic vibration ribbon. TTY only.
#_dotfiles_color_ribbon() {
#    _dotfiles_is_tty || return 0
#
#    printf '%s\n' \
#        $'\033[41m \033[43m \033[41m \033[45m \033[44m \033[46m \033[42m \033[43m \033[0m'
#}

# Chromatic displacement ribbon.
# Cruz-Diez-inspired: color interaction, vibration and optical movement.
# TTY only.

_dotfiles_color_ribbon() {
    _dotfiles_is_tty || return 0

    printf '%b' \
        '\e[48;2;220;35;45m  '\
        '\e[48;2;255;110;20m  '\
        '\e[48;2;255;205;20m  '\
        '\e[48;2;100;205;65m  '\
        '\e[48;2;20;190;180m  '\
        '\e[48;2;20;105;220m  '\
        '\e[48;2;110;45;190m  '\
        '\e[48;2;255;255;255m  '\
        '\e[48;2;220;35;45m  '\
        '\e[48;2;255;110;20m  '\
        '\e[48;2;255;205;20m  '\
        '\e[48;2;100;205;65m  '\
        '\e[48;2;20;190;180m  '\
        '\e[48;2;20;105;220m  '\
        '\e[48;2;110;45;190m  '\
        '\e[48;2;5;5;5m  '\
        '\e[0m'
}

# =============================================================================
# Session identity (cheap; shared with logout duration)
# =============================================================================

# One date(1) invocation when neither stamp exists yet.
dotfiles_ensure_session_start() {
    if [ -n "${DOTFILES_LOGIN_TIME:-}" ] && [ -n "${DOTFILES_SESSION_ID:-}" ]; then
        return 0
    fi
    _now=$(date '+%Y-%m-%d %H:%M:%S %s')
    if [ -z "${DOTFILES_LOGIN_TIME:-}" ]; then
        DOTFILES_LOGIN_TIME=${_now% *}
        export DOTFILES_LOGIN_TIME
    fi
    if [ -z "${DOTFILES_SESSION_ID:-}" ]; then
        DOTFILES_SESSION_ID=$$_${_now##* }
        export DOTFILES_SESSION_ID
    fi
    unset _now
}

# =============================================================================
# Boot / uptime / ready collectors
# Prefer kernel interfaces and builtins; cache for the process lifetime.
# =============================================================================

# Format integer seconds → compact uptime string (no forks).
# Writes _DOTFILES_FMT (avoid $() subshell on the compact start-line path).
_dotfiles_fmt_uptime_secs() {
    _s=$1
    _DOTFILES_FMT=unknown
    [ -n "$_s" ] || { unset _s; return; }
    # Drop fractional part if any.
    _s=${_s%%.*}
    case $_s in '' | *[!0-9]*) unset _s; return ;; esac

    _d=$((_s / 86400))
    _h=$(( (_s % 86400) / 3600 ))
    _m=$(( (_s % 3600) / 60 ))

    if [ "$_d" -gt 0 ]; then
        _DOTFILES_FMT="${_d}d ${_h}h ${_m}m"
    elif [ "$_h" -gt 0 ]; then
        _DOTFILES_FMT="${_h}h ${_m}m"
    elif [ "$_m" -gt 0 ]; then
        _DOTFILES_FMT="${_m}m"
    else
        _DOTFILES_FMT="${_s}s"
    fi
    unset _s _d _h _m
}

# Format epoch → "Mon D HH:MM" with one date(1) when needed.
_dotfiles_fmt_boot_epoch() {
    _bsec=$1
    [ -n "$_bsec" ] || return 0
    # GNU date -d; BSD date -r. First success wins.
    date -d "@${_bsec}" '+%b %-d %H:%M' 2>/dev/null \
        || date -r "${_bsec}" '+%b %-d %H:%M' 2>/dev/null \
        || date -d "@${_bsec}" '+%b %e %H:%M' 2>/dev/null \
        || true
    unset _bsec
}

# Populate process-local cache: _DOTFILES_C_UPTIME, _DOTFILES_C_BOOT.
# Idempotent — subsequent calls are free.
_dotfiles_collect_boot_state() {
    [ -n "${_DOTFILES_BOOT_CACHE:-}" ] && return 0
    _DOTFILES_BOOT_CACHE=1
    _DOTFILES_C_UPTIME=unknown
    _DOTFILES_C_BOOT=

    if is_linux && [ -r /proc/uptime ]; then
        # "secs.frac idle.frac" — pure read, no fork.
        read -r _up_raw _ </proc/uptime 2>/dev/null || _up_raw=
        if [ -n "$_up_raw" ]; then
            _dotfiles_fmt_uptime_secs "$_up_raw"
            _DOTFILES_C_UPTIME=${_DOTFILES_FMT:-unknown}
            unset _DOTFILES_FMT
        fi
        unset _up_raw

        if [ -r /proc/stat ]; then
            _bsec=
            while read -r _k _v _; do
                if [ "$_k" = btime ]; then
                    _bsec=$_v
                    break
                fi
            done </proc/stat
            if [ -n "$_bsec" ]; then
                _DOTFILES_C_BOOT=$(_dotfiles_fmt_boot_epoch "$_bsec")
                # Trim accidental whitespace without xargs.
                _DOTFILES_C_BOOT=${_DOTFILES_C_BOOT#"${_DOTFILES_C_BOOT%%[![:space:]]*}"}
                _DOTFILES_C_BOOT=${_DOTFILES_C_BOOT%"${_DOTFILES_C_BOOT##*[![:space:]]}"}
            fi
            unset _bsec _k _v
        fi

    elif is_macos; then
        # One sysctl: "{ sec = N, usec = M } Day Mon D HH:MM:SS YYYY"
        _raw=$(sysctl -n kern.boottime 2>/dev/null) || _raw=
        if [ -n "$_raw" ]; then
            # Epoch seconds via parameter expansion (no sed/awk).
            _tmp=${_raw#*sec = }
            _bsec=${_tmp%%,*}
            _bsec=${_bsec%% *}
            case $_bsec in
                '' | *[!0-9]*) _bsec= ;;
            esac
            if [ -n "$_bsec" ]; then
                if [ -n "${EPOCHSECONDS:-}" ]; then
                    _now=$EPOCHSECONDS
                else
                    _now=$(date +%s)
                fi
                _dotfiles_fmt_uptime_secs $((_now - _bsec))
                _DOTFILES_C_UPTIME=${_DOTFILES_FMT:-unknown}
                unset _now _DOTFILES_FMT
            fi
            # Human boot time from trailing calendar fields after '}'.
            # kern.boottime: "{ sec = N, usec = M } Day Mon D HH:MM:SS YYYY"
            _rest=${_raw#*\}}
            _rest=${_rest#"${_rest%%[![:space:]]*}"}
            # Zsh does not word-split unquoted params; ${=...} forces it.
            if [ -n "${ZSH_VERSION:-}" ]; then
                # shellcheck disable=SC2086,SC2296
                set -- ${=_rest}
            else
                # shellcheck disable=SC2086
                set -- $_rest
            fi
            # $1=Weekday $2=Mon $3=Day $4=HH:MM:SS $5=Year
            if [ "$#" -ge 4 ]; then
                _t=$4
                _hh=${_t%%:*}
                _restt=${_t#*:}
                _mm=${_restt%%:*}
                _DOTFILES_C_BOOT="$2 $3 ${_hh}:${_mm}"
                unset _t _hh _restt _mm
            fi
            unset _tmp _bsec _rest
        fi
        unset _raw

        # Fallback if sysctl missing.
        if [ "${_DOTFILES_C_UPTIME}" = unknown ] && command -v uptime >/dev/null 2>&1; then
            _u=$(uptime 2>/dev/null) || _u=
            _u=${_u#*up }
            _u=${_u%%,*}
            _u=${_u#"${_u%%[![:space:]]*}"}
            _u=${_u%"${_u##*[![:space:]]}"}
            _DOTFILES_C_UPTIME=${_u:-unknown}
            unset _u
        fi

    else
        # Generic: uptime(1) text scrape.
        if command -v uptime >/dev/null 2>&1; then
            _u=$(uptime 2>/dev/null) || _u=
            _u=${_u#*up }
            _u=${_u%%,*}
            _u=${_u#"${_u%%[![:space:]]*}"}
            _u=${_u%"${_u##*[![:space:]]}"}
            _DOTFILES_C_UPTIME=${_u:-unknown}
            unset _u
        fi
        if command -v who >/dev/null 2>&1; then
            _bt=$(who -b 2>/dev/null) || _bt=
            # "         system boot  2026-07-02 08:13" or similar
            _bt=${_bt##*boot }
            _bt=${_bt#"${_bt%%[![:space:]]*}"}
            _DOTFILES_C_BOOT=${_bt:-}
            unset _bt
        fi
    fi

    # Last-resort boot stamp via who -b when still empty.
    if [ -z "${_DOTFILES_C_BOOT}" ] && command -v who >/dev/null 2>&1; then
        _bt=$(who -b 2>/dev/null) || _bt=
        _bt=${_bt##*boot }
        _bt=${_bt#"${_bt%%[![:space:]]*}"}
        if [ -n "${ZSH_VERSION:-}" ]; then
            # shellcheck disable=SC2086,SC2296
            set -- ${=_bt}
        else
            # shellcheck disable=SC2086
            set -- $_bt
        fi
        if [ "$#" -ge 2 ]; then
            _DOTFILES_C_BOOT="$1 $2"
        else
            _DOTFILES_C_BOOT=$_bt
        fi
        unset _bt
    fi
}

dotfiles_system_uptime() {
    _dotfiles_collect_boot_state
    printf '%s' "${_DOTFILES_C_UPTIME:-unknown}"
}

dotfiles_boot_time() {
    _dotfiles_collect_boot_state
    printf '%s' "${_DOTFILES_C_BOOT:-}"
}

# Shell-ready duration since process start (best-effort, ≤1 awk when floats needed).
dotfiles_shell_ready() {
    _ready=

    if [ -n "${ZSH_VERSION:-}" ]; then
        # Float SECONDS set in .zshrc (typeset -F). Pure zsh arithmetic — no fork.
        # Strip fractional part without zsh/mathfunc int().
        _ms=$(( SECONDS * 1000 ))
        _ms=${_ms%.*}
        if [ -n "$_ms" ] && [ "$_ms" -ge 1000 ] 2>/dev/null; then
            _tenths=$(( SECONDS * 10 ))
            _tenths=${_tenths%.*}
            _ready="$((_tenths / 10)).$((_tenths % 10))s"
            unset _tenths
        elif [ -n "$_ms" ] && [ "$_ms" -gt 0 ] 2>/dev/null; then
            _ready="${_ms}ms"
        elif [ -n "${SECONDS:-}" ]; then
            _ready="${SECONDS%.*}s"
        fi
        unset _ms

    elif [ -n "${BASH_VERSION:-}" ] && [ -n "${EPOCHREALTIME:-}" ] \
        && [ -n "${DOTFILES_SHELL_START:-}" ]; then
        # Bash has no float $(( )); one awk for both format branches.
        _ready=$(AWKPATH= awk -v s="$DOTFILES_SHELL_START" -v e="$EPOCHREALTIME" 'BEGIN {
            d = e - s
            if (d < 0) d = 0
            if (d >= 1.0) printf "%.1fs", d
            else printf "%.0fms", d * 1000
        }' 2>/dev/null) || _ready=

    elif [ -n "${SECONDS:-}" ]; then
        _ready="${SECONDS}s"
    fi

    printf '%s' "${_ready:-}"
    unset _ready
}

# =============================================================================
# Display: compact start line (always on for SHLVL=1 TTY)
# =============================================================================

dotfiles_show_start_time() {
    dotfiles_ensure_session_start
    _dotfiles_collect_boot_state
    _ready=$(dotfiles_shell_ready)
    _dotfiles_term_colors

    _line="${CYAN}Started:${RESET} ${DOTFILES_LOGIN_TIME}"
    _line="${_line}  ${YELLOW}Uptime:${RESET} ${_DOTFILES_C_UPTIME}"
    [ -n "${_DOTFILES_C_BOOT}" ] && _line="${_line} ${DIM}(boot ${_DOTFILES_C_BOOT})${RESET}"
    [ -n "$_ready" ] && _line="${_line}  ${GREEN}Ready:${RESET} ${_ready}"

    printf '\n%s\n' "$_line"
    _dotfiles_color_ribbon
    printf '\n'
    unset _ready _line BOLD DIM CYAN GREEN BLUE YELLOW MAGENTA RESET
}

# =============================================================================
# Display: full system banner (opt-in via DOTFILES_SHOW_LOGIN_INFO)
# =============================================================================

dotfiles_show_system_info() {
    _WIDTH=$(dotfiles_login_width)
    dotfiles_ensure_session_start
    _dotfiles_collect_boot_state
    _ready=$(dotfiles_shell_ready)
    _dotfiles_term_colors

    _datetime=$(date '+%A, %B %d, %Y – %H:%M:%S')
    _hostname=$(hostname -s 2>/dev/null || hostname)
    _username=${USER:-$(whoami)}
    _ip=unavailable

    if is_macos; then
        _ip=$(ifconfig en0 2>/dev/null | awk '/inet / {print $2; exit}')
        [ -z "$_ip" ] && _ip=$(ifconfig en1 2>/dev/null | awk '/inet / {print $2; exit}')
    elif is_linux; then
        _ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        [ -z "$_ip" ] && _ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    fi
    [ -z "$_ip" ] && _ip=unavailable

    _load=unknown
    if is_macos; then
        # vm.loadavg → "{ 1.23 4.56 7.89 }" — avoid re-parsing uptime.
        _lr=$(sysctl -n vm.loadavg 2>/dev/null) || _lr=
        if [ -n "$_lr" ]; then
            _lr=${_lr#\{ }
            _lr=${_lr#\{}
            _load=${_lr%% *}
            _load=${_load#"${_load%%[![:space:]]*}"}
        fi
        unset _lr
    elif is_linux && [ -r /proc/loadavg ]; then
        read -r _load _ </proc/loadavg 2>/dev/null || _load=unknown
    fi

    _memory=unknown
    if is_macos && command -v vm_stat >/dev/null 2>&1; then
        # One vm_stat; awk both fields.
        _memory=$(vm_stat 2>/dev/null | awk '
            /Pages free/     { gsub(/\./,"",$3); f=$3 }
            /Pages inactive/ { gsub(/\./,"",$3); i=$3 }
            END {
                if (f != "" && i != "")
                    printf "%dMB free", (f + i) * 4096 / 1024 / 1024
            }') || _memory=unknown
        [ -z "$_memory" ] && _memory=unknown
    elif is_linux && [ -r /proc/meminfo ]; then
        _memory=$(awk '/MemAvailable/ {printf "%dMB available", int($2/1024); exit}' /proc/meminfo) \
            || _memory=unknown
        [ -z "$_memory" ] && _memory=unknown
    fi

    _disk=unknown
    if command -v df >/dev/null 2>&1; then
        _disk=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $4 " available (" $5 " used)"}') \
            || _disk=unknown
        [ -z "$_disk" ] && _disk=unknown
    fi

    echo
    dotfiles_separator_line '=' "$_WIDTH"
    dotfiles_center_text "Welcome back, ${_username}!" "${BOLD}${CYAN}" "$_WIDTH"
    dotfiles_separator_line '-' "$_WIDTH"
    dotfiles_center_text "$_datetime" "$GREEN" "$_WIDTH"
    dotfiles_center_text "Session start: ${DOTFILES_LOGIN_TIME}" "$GREEN" "$_WIDTH"
    if [ -n "${_DOTFILES_C_BOOT}" ]; then
        dotfiles_center_text "Uptime: ${_DOTFILES_C_UPTIME} (since ${_DOTFILES_C_BOOT}) | Load: ${_load}" "$YELLOW" "$_WIDTH"
    else
        dotfiles_center_text "Uptime: ${_DOTFILES_C_UPTIME} | Load: ${_load}" "$YELLOW" "$_WIDTH"
    fi
    [ -n "$_ready" ] && dotfiles_center_text "Shell ready: ${_ready}" "$CYAN" "$_WIDTH"
    dotfiles_center_text "Host: ${_hostname} | IP: ${_ip}" "$BLUE" "$_WIDTH"
    [ "$_memory" != unknown ] && dotfiles_center_text "Memory: ${_memory}" "$MAGENTA" "$_WIDTH"
    [ "$_disk" != unknown ] && dotfiles_center_text "Disk: ${_disk}" "$CYAN" "$_WIDTH"
    dotfiles_separator_line '=' "$_WIDTH"
    echo

    unset _WIDTH _datetime _hostname _username _ip _ready _load _memory _disk
    unset BOLD DIM CYAN GREEN BLUE YELLOW MAGENTA RESET
}

# =============================================================================
# Optional: dev status / updates / tips
# =============================================================================

dotfiles_show_dev_status() {
    _dotfiles_term_colors

    _out=
    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        _branch=$(git branch --show-current 2>/dev/null) || _branch=
        _changes=$(git status --porcelain 2>/dev/null | wc -l)
        _changes=${_changes##* }   # trim leading spaces from wc
        if [ -n "$_branch" ]; then
            _out="${_out}  ${GREEN}Git${RESET}: ${CYAN}${_branch}${RESET} - ${_changes} changes
"
        fi
        unset _branch _changes
    fi

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        _out="${_out}  ${GREEN}Python${RESET}: ${CYAN}${VIRTUAL_ENV##*/}${RESET}
"
    fi

    if command -v node >/dev/null 2>&1; then
        _out="${_out}  ${GREEN}Node${RESET}: ${CYAN}$(node --version 2>/dev/null)${RESET}
"
    fi

    if [ -n "$_out" ]; then
        printf '%s\n' "${DIM}Development Status:${RESET}"
        printf '%s' "$_out"
        echo
    fi
    unset _out BOLD DIM CYAN GREEN BLUE YELLOW MAGENTA RESET
}

dotfiles_check_updates() {
    _check_file="${XDG_CACHE_HOME:-$HOME/.cache}/shell_update_check"
    _today=$(date +%Y%m%d)
    _last=
    [ -f "$_check_file" ] && _last=$(cat "$_check_file" 2>/dev/null)
    if [ "$_last" = "$_today" ]; then
        unset _check_file _today _last
        return 0
    fi
    mkdir -p "${_check_file%/*}" 2>/dev/null || true
    printf '%s\n' "$_today" >"$_check_file"

    # Slow package checks: quiet background (no job-control noise).
    if is_macos && command -v brew >/dev/null 2>&1; then
        dotfiles_bg_quiet sh -c '
            _n=$(brew outdated --quiet 2>/dev/null | wc -l)
            _n=${_n##* }
            _n=${_n:-0}
            if [ "$_n" -gt 0 ] 2>/dev/null; then
                if [ -t 1 ] && [ "${TERM:-}" != dumb ]; then
                    _y=$(printf "\033[32m"); _r=$(printf "\033[0m"); _d=$(printf "\033[2m")
                else
                    _y= _r= _d=
                fi
                if [ "$_n" -eq 1 ]; then
                    _msg="1 Homebrew update available"
                else
                    _msg="$_n Homebrew updates available"
                fi
                printf "\n%s%s%s %s(run: brew upgrade)%s\n" "$_y" "$_msg" "$_r" "$_d" "$_r"
            fi
        '
    fi
    unset _check_file _today _last
}

dotfiles_show_random_tip() {
    # Cheap entropy: seconds + pid. Truncate float SECONDS (zsh typeset -F).
    _s=${SECONDS:-0}
    _idx=$(( (${_s%.*} + $$) % 8 ))
    _dotfiles_term_colors
    case $_idx in
        0) printf '%s\n' "${DIM}Tip: Use z for smart directory jumping (zoxide)${RESET}" ;;
        1) printf '%s\n' "${DIM}Tip: Use fzf / Ctrl+T for fuzzy file finding${RESET}" ;;
        2) printf '%s\n' "${DIM}Tip: Use rg for fast text searching${RESET}" ;;
        3) printf '%s\n' "${DIM}Tip: Use bat for syntax-highlighted file viewing${RESET}" ;;
        4) printf '%s\n' "${DIM}Tip: Use gcm for quick git commits${RESET}" ;;
        5) printf '%s\n' "${DIM}Tip: Press Ctrl+R for interactive history search${RESET}" ;;
        6) printf '%s\n' "${DIM}Tip: Use .. and ... for quick directory navigation${RESET}" ;;
        7) printf '%s\n' "${DIM}Tip: Type help to see available custom commands${RESET}" ;;
    esac
    echo
    unset _s _idx BOLD DIM CYAN GREEN BLUE YELLOW MAGENTA RESET
}

# =============================================================================
# Main entry — called by .zlogin / .bash_login / non-login interactive rc
# =============================================================================

dotfiles_login() {
    # Once per shell process (login + interactive rc may both call this).
    [ -n "${DOTFILES_LOGIN_RAN:-}" ] && return 0
    DOTFILES_LOGIN_RAN=1

    # Cheap stamps first (profile may already have set them on login shells).
    dotfiles_ensure_session_start

    _tty=0
    _top=0
    _dotfiles_is_tty && _tty=1
    [ "${SHLVL:-1}" -eq 1 ] && _top=1

    # --- Display (TTY only; full banner opt-in) ---
    if [ "$_tty" -eq 1 ] && [ "$_top" -eq 1 ]; then
        if dotfiles_show_login_info; then
            dotfiles_show_system_info
        else
            # Compact path: session + uptime + ready. Keep this fast.
            dotfiles_show_start_time
        fi
    fi

    if [ "$_tty" -eq 1 ] && dotfiles_show_dev_status_enabled; then
        dotfiles_show_dev_status
    fi

    # Background update probe (top-level TTY only; rate-limited inside).
    if [ "$_tty" -eq 1 ] && [ "$_top" -eq 1 ]; then
        dotfiles_check_updates
    fi

    # Agent restore/start after display so "Ready" reflects rc load, not agent.
    # Login shells typically already have an agent from profile.sh.
    dotfiles_ssh_agent_setup

    if [ "$_tty" -eq 1 ] && [ "$_top" -eq 1 ]; then
        # ~10% of top-level sessions. Truncate float SECONDS (zsh typeset -F);
        # [ -eq ] requires an integer expression.
        _s=${SECONDS:-0}
        [ $(( (${_s%.*} + $$) % 10 )) -eq 0 ] && dotfiles_show_random_tip
        unset _s
    fi

    unset _tty _top
}
