#!/bin/sh
# install-java-tools.sh — install or update Apache Maven and Gradle
#
# POSIX /bin/sh. Idempotent. No network during shell startup; run this by hand.
#
# Discovers the latest stable releases from official machine-readable sources
# (Maven Central metadata + Gradle's versions API), verifies checksums, and
# installs under $JAVA_TOOLS_HOME (default: ~/.java-tools).
#
# Usage:
#   scripts/install-java-tools.sh [install|update|status] [options]
#
# Options:
#   -h, --help          Show help
#   -v, --verbose       Verbose logging
#   -n, --dry-run       Discover versions; do not download or install
#   -f, --force         Re-download even when the latest version is present
#   --prefix DIR        Install root (default: $JAVA_TOOLS_HOME or ~/.java-tools)
#   --maven-only        Only install/update Maven
#   --gradle-only       Only install/update Gradle
#
# Environment:
#   JAVA_TOOLS_HOME     Install root (overridden by --prefix)
#   DOTFILES_VERBOSE    Same as --verbose
#   DOTFILES_DRY_RUN    Same as --dry-run
#
# shellcheck shell=sh
# shellcheck source=/dev/null

set -eu
# pipefail is not POSIX; enable when the shell supports it.
# shellcheck disable=SC3040
set -o pipefail 2>/dev/null || true

DOTFILES_ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
# shellcheck disable=SC1091
. "${DOTFILES_ROOT}/lib/logging.sh"

JAVA_TOOLS_HOME="${JAVA_TOOLS_HOME:-$HOME/.java-tools}"
DO_MAVEN=1
DO_GRADLE=1
FORCE=0
ACTION=install

MAVEN_METADATA_URL='https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml'
MAVEN_DOWNLOAD_CGI='https://maven.apache.org/download.cgi'
GRADLE_CURRENT_URL='https://services.gradle.org/versions/current'

usage() {
    cat <<EOF
${C_BOLD}install-java-tools${C_RST} — Apache Maven + Gradle (latest stable)

${C_BOLD}Usage:${C_RST}
  scripts/install-java-tools.sh [install|update|status] [options]

${C_BOLD}Commands:${C_RST}
  install    Install latest stable Maven and Gradle (default; idempotent)
  update     Same as install: upgrade only when a newer release exists
  status     Show installed vs latest versions (network used for "latest")

${C_BOLD}Options:${C_RST}
  -h, --help       Show this help
  -v, --verbose    Verbose logging
  -n, --dry-run    Resolve latest versions; do not download or change files
  -f, --force      Re-download even if the latest version is already installed
  --prefix DIR     Install root (default: \$JAVA_TOOLS_HOME or ~/.java-tools)
  --maven-only     Only Maven
  --gradle-only    Only Gradle

${C_BOLD}Layout:${C_RST}
  \$JAVA_TOOLS_HOME/maven  -> apache-maven-<version>   (MAVEN_HOME)
  \$JAVA_TOOLS_HOME/gradle -> gradle-<version>         (GRADLE_HOME)

Shell startup only reads these directories; it never checks for updates.
Re-run this script (or: make update-java-tools) when you want a newer release.

${C_BOLD}Examples:${C_RST}
  scripts/install-java-tools.sh
  scripts/install-java-tools.sh --dry-run
  scripts/install-java-tools.sh status
  make update-java-tools
EOF
}

# --- argument parsing --------------------------------------------------------

while [ "$#" -gt 0 ]; do
    case "$1" in
        install|update|status)
            ACTION=$1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            DOTFILES_VERBOSE=1
            export DOTFILES_VERBOSE
            shift
            ;;
        -n|--dry-run)
            DOTFILES_DRY_RUN=1
            export DOTFILES_DRY_RUN
            shift
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        --prefix)
            [ "$#" -ge 2 ] || die "--prefix requires a directory"
            JAVA_TOOLS_HOME=$2
            shift 2
            ;;
        --prefix=*)
            JAVA_TOOLS_HOME=${1#--prefix=}
            [ -n "$JAVA_TOOLS_HOME" ] || die "--prefix requires a directory"
            shift
            ;;
        --maven-only)
            DO_MAVEN=1
            DO_GRADLE=0
            shift
            ;;
        --gradle-only)
            DO_MAVEN=0
            DO_GRADLE=1
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            die "Unknown option: $1 (try --help)"
            ;;
        *)
            die "Unexpected argument: $1 (try --help)"
            ;;
    esac
done

# --- helpers -----------------------------------------------------------------

_JT_TMP=
jt_cleanup() {
    if [ -n "${_JT_TMP:-}" ] && [ -d "$_JT_TMP" ]; then
        rm -rf "$_JT_TMP"
    fi
}
trap 'jt_cleanup' EXIT INT HUP TERM

jt_require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# HTTPS-only curl. Archives go to -o FILE; metadata is printed to stdout.
jt_curl() {
    jt_require_cmd curl
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 1 \
        --connect-timeout 20 "$@"
}

jt_curl_file() {
    log_verbose "GET $1 -> $2"
    jt_curl --max-time "${3:-600}" -o "$2" "$1" || return 1
    [ -s "$2" ]
}

# First hex token (handles "HASH", "HASH  file", "SHA256(file)= HASH").
jt_parse_hash() {
    awk '{
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^[0-9a-fA-F]{64,}$/) { print $i; exit }
        }
    }' | tr 'A-F' 'a-f'
}

jt_hash_file() {
    # $1 = sha256|sha512, $2 = file. Prints hex digest to stdout.
    _jt_hf_algo=$1
    _jt_hf_file=$2
    _jt_hf_bits=256
    [ "$_jt_hf_algo" = sha512 ] && _jt_hf_bits=512

    if command -v shasum >/dev/null 2>&1; then
        shasum -a "$_jt_hf_bits" "$_jt_hf_file" | awk '{print $1}'
    elif command -v "${_jt_hf_algo}sum" >/dev/null 2>&1; then
        "${_jt_hf_algo}sum" "$_jt_hf_file" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -"$_jt_hf_algo" "$_jt_hf_file" | awk '{print $NF}'
    else
        unset _jt_hf_algo _jt_hf_file _jt_hf_bits
        return 1
    fi
    unset _jt_hf_algo _jt_hf_file _jt_hf_bits
}

jt_verify_checksum() {
    # $1 = file, $2 = expected digest (possibly with filename), $3 = sha256|sha512
    _jt_ck_file=$1
    _jt_ck_algo=$3
    _jt_ck_expected=$(printf '%s\n' "$2" | jt_parse_hash)
    [ -n "$_jt_ck_expected" ] || {
        log_error "Could not parse expected $_jt_ck_algo checksum"
        unset _jt_ck_file _jt_ck_expected _jt_ck_algo _jt_ck_actual
        return 1
    }
    _jt_ck_actual=$(jt_hash_file "$_jt_ck_algo" "$_jt_ck_file") || {
        log_error "No checksum tool found (need shasum, ${_jt_ck_algo}sum, or openssl)"
        unset _jt_ck_file _jt_ck_expected _jt_ck_algo _jt_ck_actual
        return 1
    }
    _jt_ck_actual=$(printf '%s\n' "$_jt_ck_actual" | tr 'A-F' 'a-f')
    if [ "$_jt_ck_actual" != "$_jt_ck_expected" ]; then
        log_error "Checksum mismatch for $(basename "$_jt_ck_file")"
        log_error "  expected: $_jt_ck_expected"
        log_error "  actual:   $_jt_ck_actual"
        unset _jt_ck_file _jt_ck_expected _jt_ck_algo _jt_ck_actual
        return 1
    fi
    log_verbose "$_jt_ck_algo OK for $(basename "$_jt_ck_file")"
    unset _jt_ck_file _jt_ck_expected _jt_ck_algo _jt_ck_actual
    return 0
}

# GA: only digits and dots (rejects alpha / beta / rc / milestone / SNAPSHOT).
jt_is_ga_version() {
    case "$1" in
        ''|*[!0-9.]*|.*|*.|*.*.*.*) return 1 ;;
    esac
    case "$1" in
        [0-9]*.[0-9]*.[0-9]*) return 0 ;;
        *) return 1 ;;
    esac
}

# First whitespace-delimited token; reject unless it is a GA version.
jt_only_ga() {
    _jt_og=$(printf '%s\n' "$1" | awk 'NF { print $1; exit }')
    if ! jt_is_ga_version "$_jt_og"; then
        unset _jt_og
        return 1
    fi
    printf '%s\n' "$_jt_og"
    unset _jt_og
}

# Exit 0 when $1 > $2 (numeric dotted versions).
jt_version_gt() {
    awk -v a="$1" -v b="$2" 'BEGIN {
        n = split(a, A, ".")
        m = split(b, B, ".")
        max = (n > m) ? n : m
        for (i = 1; i <= max; i++) {
            ai = (i <= n) ? A[i] + 0 : 0
            bi = (i <= m) ? B[i] + 0 : 0
            if (ai > bi) exit 0
            if (ai < bi) exit 1
        }
        exit 1
    }'
}

jt_pick_latest_ga() {
    _jt_best=
    for _jt_v in "$@"; do
        jt_is_ga_version "$_jt_v" || continue
        if [ -z "$_jt_best" ] || jt_version_gt "$_jt_v" "$_jt_best"; then
            _jt_best=$_jt_v
        fi
    done
    [ -n "$_jt_best" ] || return 1
    printf '%s\n' "$_jt_best"
    unset _jt_best _jt_v
}

jt_json_string_field() {
    # $1 = JSON text, $2 = field name. Prints the first matching string value.
    printf '%s\n' "$1" | sed -n \
        "s/^[[:space:]]*\"${2}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" \
        | head -n 1
}

jt_readlink() {
    readlink "$1" 2>/dev/null || true
}

jt_installed_version() {
    # $1 = maven|gradle
    _jt_name=$1
    _jt_link="${JAVA_TOOLS_HOME}/${_jt_name}"
    _jt_ver=

    if [ -L "$_jt_link" ]; then
        _jt_target=$(jt_readlink "$_jt_link")
        _jt_base=$(basename "$_jt_target")
        case "$_jt_name" in
            maven) _jt_ver=${_jt_base#apache-maven-} ;;
            gradle) _jt_ver=${_jt_base#gradle-} ;;
        esac
    fi

    if [ -z "$_jt_ver" ] && [ -f "${JAVA_TOOLS_HOME}/versions" ]; then
        _jt_ver=$(sed -n "s/^${_jt_name}=//p" "${JAVA_TOOLS_HOME}/versions" | head -n 1)
    fi

    printf '%s' "${_jt_ver:-}"
    unset _jt_name _jt_link _jt_ver _jt_target _jt_base
}

jt_tool_ok() {
    # $1 = maven|gradle
    case "$1" in
        maven) [ -x "${JAVA_TOOLS_HOME}/maven/bin/mvn" ] ;;
        gradle) [ -x "${JAVA_TOOLS_HOME}/gradle/bin/gradle" ] ;;
        *) return 1 ;;
    esac
}

jt_write_versions() {
    _jt_file="${JAVA_TOOLS_HOME}/versions"
    _jt_maven=$(jt_installed_version maven)
    _jt_gradle=$(jt_installed_version gradle)
    {
        printf '# managed by scripts/install-java-tools.sh — do not edit by hand\n'
        [ -n "$_jt_maven" ] && printf 'maven=%s\n' "$_jt_maven"
        [ -n "$_jt_gradle" ] && printf 'gradle=%s\n' "$_jt_gradle"
        printf 'updated_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
    } >"${_jt_file}.tmp"
    mv -f "${_jt_file}.tmp" "$_jt_file"
    unset _jt_file _jt_maven _jt_gradle
}

# Atomic current-symlink update. Link text is relative to JAVA_TOOLS_HOME.
jt_set_current() {
    _jt_cur_name=$1
    _jt_cur_target=$2
    _jt_cur_link="${JAVA_TOOLS_HOME}/${_jt_cur_name}"
    _jt_cur_tmp="${JAVA_TOOLS_HOME}/.${_jt_cur_name}.link.$$"

    if [ -e "$_jt_cur_link" ] && [ ! -L "$_jt_cur_link" ]; then
        _jt_cur_bak="${_jt_cur_link}.bak.$(date +%Y%m%d_%H%M%S 2>/dev/null || echo $$)"
        log_warn "$_jt_cur_link is not a symlink; moving aside to $_jt_cur_bak"
        mv "$_jt_cur_link" "$_jt_cur_bak"
        unset _jt_cur_bak
    fi

    ln -s "$_jt_cur_target" "$_jt_cur_tmp"
    mv -f "$_jt_cur_tmp" "$_jt_cur_link"
    unset _jt_cur_name _jt_cur_target _jt_cur_link _jt_cur_tmp
}

jt_extract_tar_gz() {
    mkdir -p "$2"
    tar -xzf "$1" -C "$2"
}

jt_extract_zip() {
    mkdir -p "$2"
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$1" -d "$2"
    elif tar -xf "$1" -C "$2" 2>/dev/null; then
        :
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' \
            "$1" "$2"
    else
        log_error "Cannot extract zip (need unzip, tar, or python3)"
        return 1
    fi
}

# --- Maven discovery ---------------------------------------------------------

jt_discover_maven_from_metadata() {
    log_verbose "Fetching Maven metadata: $MAVEN_METADATA_URL"
    _jt_xml=$(jt_curl --max-time 30 "$MAVEN_METADATA_URL") || return 1
    _jt_vers=$(printf '%s\n' "$_jt_xml" | sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p')
    [ -n "$_jt_vers" ] || return 1
    # shellcheck disable=SC2086
    jt_pick_latest_ga $_jt_vers
    unset _jt_xml _jt_vers
}

jt_discover_maven_from_download_cgi() {
    log_verbose "Fetching Maven download page: $MAVEN_DOWNLOAD_CGI"
    _jt_html=$(jt_curl --max-time 30 "$MAVEN_DOWNLOAD_CGI") || return 1
    _jt_vers=$(printf '%s\n' "$_jt_html" \
        | sed -n 's/.*apache-maven-\([0-9][^"/[:space:]]*\)-bin\.tar\.gz.*/\1/p' \
        | sort -u)
    [ -n "$_jt_vers" ] || return 1
    # shellcheck disable=SC2086
    jt_pick_latest_ga $_jt_vers
    unset _jt_html _jt_vers
}

jt_discover_maven() {
    _jt_v=
    _jt_v=$(jt_discover_maven_from_metadata) || _jt_v=
    _jt_v=$(jt_only_ga "${_jt_v:-}") || _jt_v=
    if [ -z "$_jt_v" ]; then
        log_warn "Maven Central metadata failed; trying maven.apache.org/download.cgi"
        _jt_v=$(jt_discover_maven_from_download_cgi) || _jt_v=
        _jt_v=$(jt_only_ga "${_jt_v:-}") || _jt_v=
    fi
    [ -n "$_jt_v" ] || return 1
    printf '%s\n' "$_jt_v"
    unset _jt_v
}

jt_maven_archive_urls() {
    # Prints candidate archive URLs, one per line (first success wins).
    _jt_ver=$1
    _jt_maj=${_jt_ver%%.*}
    _jt_file="apache-maven-${_jt_ver}-bin.tar.gz"
    printf '%s\n' \
        "https://dlcdn.apache.org/maven/maven-${_jt_maj}/${_jt_ver}/binaries/${_jt_file}" \
        "https://downloads.apache.org/maven/maven-${_jt_maj}/${_jt_ver}/binaries/${_jt_file}" \
        "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${_jt_ver}/${_jt_file}" \
        "https://archive.apache.org/dist/maven/maven-${_jt_maj}/${_jt_ver}/binaries/${_jt_file}"
    unset _jt_ver _jt_maj _jt_file
}

jt_maven_checksum_urls() {
    _jt_ver=$1
    _jt_maj=${_jt_ver%%.*}
    _jt_file="apache-maven-${_jt_ver}-bin.tar.gz.sha512"
    printf '%s\n' \
        "https://downloads.apache.org/maven/maven-${_jt_maj}/${_jt_ver}/binaries/${_jt_file}" \
        "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${_jt_ver}/apache-maven-${_jt_ver}-bin.tar.gz.sha512" \
        "https://archive.apache.org/dist/maven/maven-${_jt_maj}/${_jt_ver}/binaries/${_jt_file}"
    unset _jt_ver _jt_maj _jt_file
}

jt_fetch_first() {
    # $1 = dest file; remaining args = URLs
    _jt_fetch_dest=$1
    shift
    for _jt_fetch_url in "$@"; do
        log_verbose "try $_jt_fetch_url"
        if jt_curl_file "$_jt_fetch_url" "$_jt_fetch_dest"; then
            unset _jt_fetch_dest _jt_fetch_url
            return 0
        fi
    done
    unset _jt_fetch_dest _jt_fetch_url
    return 1
}

# --- Gradle discovery --------------------------------------------------------

jt_discover_gradle() {
    log_verbose "Fetching Gradle current release: $GRADLE_CURRENT_URL"
    _jt_json=$(jt_curl --max-time 30 "$GRADLE_CURRENT_URL") || return 1
    _jt_ver=$(jt_json_string_field "$_jt_json" version)
    _jt_ver=$(jt_only_ga "${_jt_ver:-}") || _jt_ver=
    unset _jt_json
    [ -n "$_jt_ver" ] || return 1
    printf '%s\n' "$_jt_ver"
    unset _jt_ver
}

# --- installers --------------------------------------------------------------

jt_ensure_tmpdir() {
    if [ -n "${_JT_TMP:-}" ] && [ -d "$_JT_TMP" ]; then
        return 0
    fi
    if command -v mktemp >/dev/null 2>&1; then
        _JT_TMP=$(mktemp -d "${TMPDIR:-/tmp}/java-tools.XXXXXX")
    else
        _JT_TMP="${TMPDIR:-/tmp}/java-tools.$$"
        mkdir -p "$_JT_TMP"
    fi
}

jt_install_maven() {
    _jt_latest=$1
    _jt_have=$(jt_installed_version maven)
    _jt_dest="${JAVA_TOOLS_HOME}/apache-maven-${_jt_latest}"

    if [ "$FORCE" != 1 ] && [ "$_jt_have" = "$_jt_latest" ] && jt_tool_ok maven; then
        log_success "Maven ${_jt_latest} already installed"
        unset _jt_latest _jt_have _jt_dest
        return 0
    fi

    if [ "${DOTFILES_DRY_RUN:-0}" = "1" ]; then
        if [ -n "$_jt_have" ]; then
            log_dry "Would update Maven ${_jt_have} -> ${_jt_latest}"
        else
            log_dry "Would install Maven ${_jt_latest} into ${JAVA_TOOLS_HOME}"
        fi
        unset _jt_latest _jt_have _jt_dest
        return 0
    fi

    log_step "Installing Maven ${_jt_latest}"
    jt_ensure_tmpdir
    _jt_archive="${_JT_TMP}/apache-maven-${_jt_latest}-bin.tar.gz"
    _jt_sumfile="${_JT_TMP}/apache-maven-${_jt_latest}-bin.tar.gz.sha512"
    _jt_extract="${_JT_TMP}/maven-extract"

    # shellcheck disable=SC2046
    if ! jt_fetch_first "$_jt_archive" $(jt_maven_archive_urls "$_jt_latest"); then
        log_error "Failed to download Maven ${_jt_latest} (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract
        return 1
    fi

    _jt_expected=
    # shellcheck disable=SC2046
    if jt_fetch_first "$_jt_sumfile" $(jt_maven_checksum_urls "$_jt_latest"); then
        _jt_expected=$(cat "$_jt_sumfile")
    else
        log_error "Failed to download Maven ${_jt_latest} sha512 (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_expected
        return 1
    fi

    if ! jt_verify_checksum "$_jt_archive" "$_jt_expected" sha512; then
        log_error "Maven archive failed verification (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_expected
        return 1
    fi

    rm -rf "$_jt_extract"
    mkdir -p "$_jt_extract"
    if ! jt_extract_tar_gz "$_jt_archive" "$_jt_extract"; then
        log_error "Failed to extract Maven archive (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_expected
        return 1
    fi

    _jt_unpacked="${_jt_extract}/apache-maven-${_jt_latest}"
    if [ ! -x "${_jt_unpacked}/bin/mvn" ]; then
        log_error "Extracted Maven tree is missing bin/mvn (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_expected _jt_unpacked
        return 1
    fi

    mkdir -p "$JAVA_TOOLS_HOME"
    _jt_staging="${JAVA_TOOLS_HOME}/.apache-maven-${_jt_latest}.$$"
    rm -rf "$_jt_staging"
    mv "$_jt_unpacked" "$_jt_staging"
    if [ -d "$_jt_dest" ]; then
        rm -rf "${_jt_dest}.old"
        mv "$_jt_dest" "${_jt_dest}.old"
    fi
    if ! mv "$_jt_staging" "$_jt_dest"; then
        log_error "Failed to move Maven into place"
        [ -d "${_jt_dest}.old" ] && mv "${_jt_dest}.old" "$_jt_dest"
        rm -rf "$_jt_staging"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_expected _jt_unpacked _jt_staging
        return 1
    fi
    rm -rf "${_jt_dest}.old"

    jt_set_current maven "apache-maven-${_jt_latest}"
    log_success "Maven ${_jt_latest} installed -> ${JAVA_TOOLS_HOME}/maven"
    unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_expected _jt_unpacked _jt_staging
    return 0
}

jt_install_gradle() {
    _jt_latest=$1
    _jt_have=$(jt_installed_version gradle)
    _jt_dest="${JAVA_TOOLS_HOME}/gradle-${_jt_latest}"

    if [ "$FORCE" != 1 ] && [ "$_jt_have" = "$_jt_latest" ] && jt_tool_ok gradle; then
        log_success "Gradle ${_jt_latest} already installed"
        unset _jt_latest _jt_have _jt_dest
        return 0
    fi

    if [ "${DOTFILES_DRY_RUN:-0}" = "1" ]; then
        if [ -n "$_jt_have" ]; then
            log_dry "Would update Gradle ${_jt_have} -> ${_jt_latest}"
        else
            log_dry "Would install Gradle ${_jt_latest} into ${JAVA_TOOLS_HOME}"
        fi
        unset _jt_latest _jt_have _jt_dest
        return 0
    fi

    log_step "Installing Gradle ${_jt_latest}"
    jt_ensure_tmpdir
    _jt_archive="${_JT_TMP}/gradle-${_jt_latest}-bin.zip"
    _jt_sumfile="${_JT_TMP}/gradle-${_jt_latest}-bin.zip.sha256"
    _jt_extract="${_JT_TMP}/gradle-extract"

    _jt_url="https://services.gradle.org/distributions/gradle-${_jt_latest}-bin.zip"
    _jt_url2="https://downloads.gradle.org/distributions/gradle-${_jt_latest}-bin.zip"
    if ! jt_curl_file "$_jt_url" "$_jt_archive"; then
        log_warn "Primary Gradle URL failed; trying downloads.gradle.org"
        if ! jt_curl_file "$_jt_url2" "$_jt_archive"; then
            log_error "Failed to download Gradle ${_jt_latest} (existing install left unchanged)"
            unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_url _jt_url2
            return 1
        fi
    fi

    _jt_sum_url="https://services.gradle.org/distributions/gradle-${_jt_latest}-bin.zip.sha256"
    _jt_sum_url2="https://downloads.gradle.org/distributions/gradle-${_jt_latest}-bin.zip.sha256"
    if ! jt_curl_file "$_jt_sum_url" "$_jt_sumfile" 30; then
        log_warn "Primary Gradle checksum URL failed; trying downloads.gradle.org"
        if ! jt_curl_file "$_jt_sum_url2" "$_jt_sumfile" 30; then
            log_error "Failed to download Gradle ${_jt_latest} sha256 (existing install left unchanged)"
            unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_url _jt_url2 _jt_sum_url _jt_sum_url2
            return 1
        fi
    fi
    _jt_expected=$(cat "$_jt_sumfile")

    if ! jt_verify_checksum "$_jt_archive" "$_jt_expected" sha256; then
        log_error "Gradle archive failed verification (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_url _jt_url2 _jt_sum_url _jt_sum_url2 _jt_expected
        return 1
    fi

    rm -rf "$_jt_extract"
    mkdir -p "$_jt_extract"
    if ! jt_extract_zip "$_jt_archive" "$_jt_extract"; then
        log_error "Failed to extract Gradle archive (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_extract _jt_url _jt_url2 _jt_expected
        return 1
    fi

    _jt_unpacked="${_jt_extract}/gradle-${_jt_latest}"
    if [ ! -x "${_jt_unpacked}/bin/gradle" ]; then
        log_error "Extracted Gradle tree is missing bin/gradle (existing install left unchanged)"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_url _jt_url2 _jt_sum_url _jt_sum_url2 _jt_expected _jt_unpacked
        return 1
    fi

    mkdir -p "$JAVA_TOOLS_HOME"
    _jt_staging="${JAVA_TOOLS_HOME}/.gradle-${_jt_latest}.$$"
    rm -rf "$_jt_staging"
    mv "$_jt_unpacked" "$_jt_staging"
    if [ -d "$_jt_dest" ]; then
        rm -rf "${_jt_dest}.old"
        mv "$_jt_dest" "${_jt_dest}.old"
    fi
    if ! mv "$_jt_staging" "$_jt_dest"; then
        log_error "Failed to move Gradle into place"
        [ -d "${_jt_dest}.old" ] && mv "${_jt_dest}.old" "$_jt_dest"
        rm -rf "$_jt_staging"
        unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_url _jt_url2 _jt_sum_url _jt_sum_url2 _jt_expected _jt_unpacked _jt_staging
        return 1
    fi
    rm -rf "${_jt_dest}.old"

    jt_set_current gradle "gradle-${_jt_latest}"
    log_success "Gradle ${_jt_latest} installed -> ${JAVA_TOOLS_HOME}/gradle"
    unset _jt_latest _jt_have _jt_dest _jt_archive _jt_sumfile _jt_extract _jt_url _jt_url2 _jt_sum_url _jt_sum_url2 _jt_expected _jt_unpacked _jt_staging
    return 0
}

jt_print_status() {
    _jt_m_have=$(jt_installed_version maven)
    _jt_g_have=$(jt_installed_version gradle)
    _jt_m_ok=no
    _jt_g_ok=no
    jt_tool_ok maven && _jt_m_ok=yes
    jt_tool_ok gradle && _jt_g_ok=yes

    printf 'Install root: %s\n' "$JAVA_TOOLS_HOME"
    if [ -n "$_jt_m_have" ]; then
        printf 'Maven  installed: %s (ok=%s)\n' "$_jt_m_have" "$_jt_m_ok"
    else
        printf 'Maven  installed: (none)\n'
    fi
    if [ -n "$_jt_g_have" ]; then
        printf 'Gradle installed: %s (ok=%s)\n' "$_jt_g_have" "$_jt_g_ok"
    else
        printf 'Gradle installed: (none)\n'
    fi

    if [ "$DO_MAVEN" = "1" ]; then
        if _jt_m_latest=$(jt_discover_maven); then
            printf 'Maven  latest:    %s\n' "$_jt_m_latest"
        else
            log_warn "Could not discover latest Maven version"
        fi
    fi
    if [ "$DO_GRADLE" = "1" ]; then
        if _jt_g_latest=$(jt_discover_gradle); then
            printf 'Gradle latest:    %s\n' "$_jt_g_latest"
        else
            log_warn "Could not discover latest Gradle version"
        fi
    fi
    unset _jt_m_have _jt_g_have _jt_m_ok _jt_g_ok _jt_m_latest _jt_g_latest
}

# --- main --------------------------------------------------------------------

main() {
    log_header "Java tools (${ACTION})"
    log_info "prefix=${JAVA_TOOLS_HOME}"

    if [ "$ACTION" = status ]; then
        jt_print_status
        return 0
    fi

    _jt_rc=0

    if [ "$DO_MAVEN" = "1" ]; then
        log_step "Resolving latest stable Maven"
        if _jt_maven_latest=$(jt_discover_maven); then
            log_info "Latest stable Maven: ${_jt_maven_latest}"
            jt_install_maven "$_jt_maven_latest" || _jt_rc=1
        else
            log_error "Could not determine the latest stable Maven release"
            _jt_rc=1
        fi
    fi

    if [ "$DO_GRADLE" = "1" ]; then
        log_step "Resolving latest stable Gradle"
        if _jt_gradle_latest=$(jt_discover_gradle); then
            log_info "Latest stable Gradle: ${_jt_gradle_latest}"
            jt_install_gradle "$_jt_gradle_latest" || _jt_rc=1
        else
            log_error "Could not determine the latest stable Gradle release"
            _jt_rc=1
        fi
    fi

    if [ "${DOTFILES_DRY_RUN:-0}" != "1" ] && [ -d "$JAVA_TOOLS_HOME" ]; then
        jt_write_versions
    fi

    if [ "$_jt_rc" -eq 0 ]; then
        log_success "Done"
        if [ "${DOTFILES_DRY_RUN:-0}" != "1" ]; then
            log_info "MAVEN_HOME=${JAVA_TOOLS_HOME}/maven  GRADLE_HOME=${JAVA_TOOLS_HOME}/gradle"
            log_info "Open a new shell, or: exec \"\$SHELL\" -l"
        fi
    else
        log_error "One or more tools failed to install; any previous versions were left in place"
    fi

    unset _jt_maven_latest _jt_gradle_latest
    return "$_jt_rc"
}

main
