#!/bin/bash

# Zed Compatibility Test Script
# =============================
# This script tests that the dotfiles fixes are working correctly with Zed editor
# Run this script to verify that all Zed-related issues have been resolved

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_command="$2"

    ((TESTS_RUN++))
    log_info "Running test: $test_name"

    if eval "$test_command"; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        return 1
    fi
}

# Test: Zed environment detection
test_zed_detection() {
    if [[ "$TERM_PROGRAM" == "zed" ]]; then
        return 0
    else
        echo "Expected TERM_PROGRAM=zed, got: $TERM_PROGRAM"
        return 1
    fi
}

# Test: Zellij auto-start protection
test_zellij_protection() {
    # Check if the protection logic exists in .zshrc
    if grep -q 'TERM_PROGRAM.*zed.*return' ~/.zshrc; then
        return 0
    elif grep -q 'ZED.*return' ~/.zshrc; then
        return 0
    else
        echo "No Zed protection found in .zshrc"
        return 1
    fi
}

# Test: Zed settings JSON validity
test_zed_settings() {
    local settings_file="$HOME/.config/zed/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        echo "Zed settings file not found: $settings_file"
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        if jq empty "$settings_file" 2>/dev/null; then
            return 0
        else
            echo "Invalid JSON in Zed settings"
            return 1
        fi
    else
        # Basic JSON check without jq
        if [[ $(head -c 1 "$settings_file") == "{" ]] && [[ $(tail -c 2 "$settings_file" | head -c 1) == "}" ]]; then
            return 0
        else
            echo "Settings file doesn't appear to be valid JSON"
            return 1
        fi
    fi
}

# Test: Terminal shell configuration
test_terminal_config() {
    local settings_file="$HOME/.config/zed/settings.json"

    if grep -q '"program": "/bin/zsh"' "$settings_file" && grep -q '"arguments"' "$settings_file"; then
        return 0
    else
        echo "Terminal shell configuration not found in Zed settings"
        return 1
    fi
}

# Test: PATH cleanliness
test_path_duplicates() {
    local path_entries=()
    local duplicates_found=false

    IFS=':' read -ra path_entries <<< "$PATH"

    # Use associative array to count occurrences
    declare -A path_count
    for path in "${path_entries[@]}"; do
        if [[ -n "${path_count[$path]:-}" ]]; then
            duplicates_found=true
            break
        fi
        path_count[$path]=1
    done

    if [[ "$duplicates_found" == "false" ]]; then
        return 0
    else
        echo "PATH contains duplicate entries"
        return 1
    fi
}

# Test: Shell startup performance
test_shell_performance() {
    local startup_time
    startup_time=$(time ($SHELL -c 'exit') 2>&1 | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')

    # Check if startup time is reasonable (less than 1 second)
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$startup_time < 1.0" | bc -l) )); then
            return 0
        else
            echo "Shell startup time too slow: ${startup_time}s"
            return 1
        fi
    else
        # Fallback check without bc
        if [[ "${startup_time:0:1}" == "0" ]]; then
            return 0
        else
            echo "Shell startup time may be too slow: ${startup_time}s"
            return 1
        fi
    fi
}

# Test: Environment isolation
test_environment_isolation() {
    # Test that problematic commands skip execution in Zed environment
    if [[ "$TERM_PROGRAM" == "zed" ]]; then
        # In Zed, check that we're not in an interactive login shell context
        # where Zellij would normally start
        if [[ -o login ]] && [[ -o interactive ]] && [[ "$SHLVL" -eq 1 ]]; then
            echo "Shell context suggests Zellij might try to start"
            return 1
        else
            return 0
        fi
    else
        echo "Not running in Zed environment"
        return 1
    fi
}

# Test: Required tools availability
test_basic_tools() {
    local required_tools=("git" "zsh")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        return 0
    else
        echo "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
}

# Test: File permissions
test_file_permissions() {
    local important_files=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.config/zed/settings.json"
    )

    for file in "${important_files[@]}"; do
        if [[ ! -r "$file" ]]; then
            echo "Cannot read important file: $file"
            return 1
        fi
    done

    return 0
}

# Test: Helper scripts installation
test_helper_scripts() {
    if [[ -x "$HOME/.local/bin/debug-zed-shell.sh" ]]; then
        return 0
    else
        echo "Debug helper script not found or not executable"
        return 1
    fi
}

# Main test execution
main() {
    echo "🧪 Zed Compatibility Test Suite"
    echo "==============================="
    echo

    log_info "Testing environment: $(date)"
    log_info "Shell: $SHELL"
    log_info "TERM_PROGRAM: ${TERM_PROGRAM:-<not set>}"
    log_info "ZED: ${ZED:-<not set>}"
    echo

    # Run all tests
    run_test "Zed Environment Detection" "test_zed_detection"
    run_test "Zellij Auto-start Protection" "test_zellij_protection"
    run_test "Zed Settings JSON Validity" "test_zed_settings"
    run_test "Terminal Shell Configuration" "test_terminal_config"
    run_test "PATH Duplicate Check" "test_path_duplicates"
    run_test "Shell Startup Performance" "test_shell_performance"
    run_test "Environment Isolation" "test_environment_isolation"
    run_test "Basic Tools Availability" "test_basic_tools"
    run_test "File Permissions" "test_file_permissions"
    run_test "Helper Scripts Installation" "test_helper_scripts"

    echo
    echo "📊 Test Results Summary"
    echo "======================="
    echo "Tests run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_pass "🎉 All tests passed! Zed compatibility is working correctly."
        echo
        log_info "✅ Your dotfiles are now fully compatible with Zed editor"
        log_info "✅ Shell hanging issues should be resolved"
        log_info "✅ Environment detection is working properly"
        log_info "✅ Configuration files are valid and optimized"
        echo
        return 0
    else
        log_fail "❌ Some tests failed. Please review the issues above."
        echo
        log_info "🔧 Troubleshooting steps:"
        echo "  1. Run: ~/.local/bin/debug-zed-shell.sh"
        echo "  2. Check Zed logs: ~/Library/Logs/Zed/Zed.log"
        echo "  3. Restart Zed editor completely"
        echo "  4. Re-run this test script"
        echo
        return 1
    fi
}

# Handle script interruption
trap 'log_warning "Test interrupted"; exit 130' INT TERM

# Run main function
main "$@"
