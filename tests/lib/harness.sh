# harness.sh — reporting helpers for tests/run.sh. Sourced, not executed.
# Bash 3.2 is the floor: no associative arrays, no mapfile, no ${var,,}.

df_usage() {
    cat <<'EOF'
Usage: ./tests/run.sh [--update-baseline]

  ./tests/run.sh                 run the contract; never writes baselines
  ./tests/run.sh --update-baseline
                                 record the current shells, then run the contract

Environment:
  DOTFILES_TEST_ITERS            timing iterations (default 10)
  DOTFILES_TEST_PERF_RATIO       median regression ratio (default 1.5)
  DOTFILES_TEST_PERF_SLACK_MS    absolute median slack in milliseconds (default 25)

A timing fails only when the new median exceeds both the ratio and the slack.
EOF
}

df_section_begin() {
    DF_SECTION=$1
    DF_SECTION_OK=1
    : > "$DF_WORK/reasons"
}

df_fail() {
    DF_SECTION_OK=0
    printf '%s\n' "$1" >> "$DF_WORK/reasons"
    if [ -n "${2:-}" ]; then
        printf 'Expected:\n%s\nActual:\n%s\n' "$2" "${3:-}" >> "$DF_WORK/reasons"
    fi
}

df_section_end() {
    if [ "$DF_SECTION_OK" = 1 ]; then
        printf '[PASS] %s\n' "$DF_SECTION"
        DF_PASSES=$((DF_PASSES + 1))
    else
        printf '[FAIL] %s\n\nReason:\n' "$DF_SECTION"
        sed 's/^/  /' "$DF_WORK/reasons"
        printf '\n'
        DF_FAILS=$((DF_FAILS + 1))
    fi
}

df_expect() {
    # $1 actual  $2 expected  $3 message
    if [ "$1" != "$2" ]; then
        df_fail "$3" "$2" "$1"
        return 1
    fi
    return 0
}

df_need_file() {
    if [ ! -f "$1" ]; then
        df_fail "No baseline at $1
Run ./tests/run.sh --update-baseline after reviewing the live behavior."
        return 1
    fi
    return 0
}

df_fail_stderr() {
    if [ -s "$1" ]; then
        df_fail "Unexpected stderr from $2:
$(sed 's/^/  /' "$1")"
        return 1
    fi
    return 0
}

df_deny_output() {
    local hit
    hit=$(LC_ALL=C grep -a -n -E "can't change option|command not found|No such file or directory|parse error|syntax error|bad substitution|Permission denied|operation not permitted|compinit: insecure" "$1" || true)
    if [ -n "$hit" ]; then
        df_fail "Startup output matched an error pattern ($2):
$hit"
        return 1
    fi
    return 0
}

df_no_esc() {
    if LC_ALL=C grep -a -q "$(printf '\033')" "$1"; then
        df_fail "Escape sequence in output that should be plain ($2)"
        return 1
    fi
    return 0
}

df_umask_interactive() {
    case $1 in
        *77) return 0 ;;
    esac
    return 1
}

df_umask_plain() {
    case $1 in
        *22) return 0 ;;
    esac
    return 1
}

df_note() {
    printf '%s\n' "$1" >> "$DF_WORK/summary"
}

df_digest() {
    if [ ! -e "$1" ]; then
        printf 'missing %s\n' "$1"
        return 0
    fi
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1"
    else
        cksum "$1"
    fi
}

df_stats() {
    python3 -c '
import sys
xs = []
for line in sys.stdin:
    line = line.strip()
    if line:
        xs.append(float(line))
if not xs:
    sys.exit(1)
xs.sort()
n = len(xs)
if n % 2:
    med = xs[n // 2]
else:
    med = (xs[n // 2 - 1] + xs[n // 2]) / 2.0
sys.stdout.write("%.3f %.3f %.3f\n" % (xs[0], med, xs[-1]))
'
}

df_over_limit() {
    # stdin unused. args: current baseline ratio slack. Prints limit and "fail" or "ok".
    python3 -c '
import sys
cur = float(sys.argv[1])
base = float(sys.argv[2])
ratio = float(sys.argv[3])
slack = float(sys.argv[4])
limit = max(base * ratio, base + slack)
sys.stdout.write("%.3f %s\n" % (limit, "fail" if cur > limit else "ok"))
' "$1" "$2" "$3" "$4"
}
