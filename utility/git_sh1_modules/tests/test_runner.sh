#!/bin/bash

# Test runner for git_sh1_modules
# Provides basic testing framework for modules

# Test configuration
TEST_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_BASE="$(dirname "$TEST_BASE")"
FAILED_TESTS=0
TOTAL_TESTS=0

# ANSI color codes for test output
TEST_RED='\033[0;31m'
TEST_GREEN='\033[0;32m'
TEST_YELLOW='\033[1;33m'
TEST_CYAN='\033[0;36m'
TEST_NC='\033[0m' # No Color

# Test result tracking
declare -a FAILED_TEST_NAMES

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="${3:-assertion}"
    
    ((TOTAL_TESTS++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${TEST_GREEN}✓${TEST_NC} $test_name"
        return 0
    else
        echo -e "${TEST_RED}✗${TEST_NC} $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local test_name="${3:-assertion}"
    
    ((TOTAL_TESTS++))
    
    if [[ "$not_expected" != "$actual" ]]; then
        echo -e "${TEST_GREEN}✓${TEST_NC} $test_name"
        return 0
    else
        echo -e "${TEST_RED}✗${TEST_NC} $test_name"
        echo "  Should not equal: '$not_expected'"
        echo "  Actual:          '$actual'"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

assert_success() {
    local test_name="${1:-command execution}"
    local exit_code="${2:-$?}"
    
    ((TOTAL_TESTS++))
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${TEST_GREEN}✓${TEST_NC} $test_name"
        return 0
    else
        echo -e "${TEST_RED}✗${TEST_NC} $test_name (exit code: $exit_code)"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

assert_failure() {
    local test_name="${1:-command execution}"
    local exit_code="${2:-$?}"
    
    ((TOTAL_TESTS++))
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${TEST_GREEN}✓${TEST_NC} $test_name (expected failure)"
        return 0
    else
        echo -e "${TEST_RED}✗${TEST_NC} $test_name (expected failure but succeeded)"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

# Test suite management
run_test_file() {
    local test_file="$1"
    
    if [[ ! -f "$test_file" ]]; then
        echo -e "${TEST_RED}Error: Test file not found: $test_file${TEST_NC}"
        return 1
    fi
    
    echo -e "${TEST_CYAN}Running tests from: $(basename "$test_file")${TEST_NC}"
    
    # Source the test file in a subshell to isolate environment
    (
        source "$test_file"
    )
    local test_exit_code=$?
    
    echo ""  # Add spacing between test files
    return $test_exit_code
}

run_unit_tests() {
    echo -e "${TEST_CYAN}=== Running Unit Tests ===${TEST_NC}"
    
    local unit_test_dir="${TEST_BASE}/unit"
    if [[ -d "$unit_test_dir" ]]; then
        for test_file in "$unit_test_dir"/test_*.sh; do
            if [[ -f "$test_file" ]]; then
                run_test_file "$test_file"
            fi
        done
    else
        echo "No unit test directory found at: $unit_test_dir"
    fi
}

run_integration_tests() {
    echo -e "${TEST_CYAN}=== Running Integration Tests ===${TEST_NC}"
    
    local integration_test_dir="${TEST_BASE}/integration"
    if [[ -d "$integration_test_dir" ]]; then
        for test_file in "$integration_test_dir"/test_*.sh; do
            if [[ -f "$test_file" ]]; then
                run_test_file "$test_file"
            fi
        done
    else
        echo "No integration test directory found at: $integration_test_dir"
    fi
}

show_test_summary() {
    echo -e "${TEST_CYAN}=== Test Summary ===${TEST_NC}"
    echo "Total tests: $TOTAL_TESTS"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${TEST_GREEN}All tests passed!${TEST_NC}"
        return 0
    else
        echo -e "${TEST_RED}Failed tests: $FAILED_TESTS${TEST_NC}"
        echo "Failed test names:"
        for failed_test in "${FAILED_TEST_NAMES[@]}"; do
            echo "  - $failed_test"
        done
        return 1
    fi
}

# Main test execution
main() {
    local run_unit=true
    local run_integration=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                run_integration=false
                shift
                ;;
            --integration-only)
                run_unit=false
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--unit-only|--integration-only]"
                echo "  --unit-only        Run only unit tests"
                echo "  --integration-only Run only integration tests"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Run tests
    if [[ "$run_unit" == "true" ]]; then
        run_unit_tests
    fi
    
    if [[ "$run_integration" == "true" ]]; then
        run_integration_tests
    fi
    
    # Show summary and exit with appropriate code
    if show_test_summary; then
        exit 0
    else
        exit 1
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi