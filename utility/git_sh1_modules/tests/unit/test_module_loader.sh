#!/bin/bash

# Unit tests for module_loader.sh

# Set up test environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_BASE="$(dirname "$(dirname "$TEST_DIR")")"

# Source the module loader
source "${MODULE_BASE}/lib/module_loader.sh"

# Test module loader basic functionality
test_module_loader_functions_exist() {
    assert_success "load_module function exists" $(declare -f load_module > /dev/null; echo $?)
    assert_success "load_core_modules function exists" $(declare -f load_core_modules > /dev/null; echo $?)
    assert_success "is_module_loaded function exists" $(declare -f is_module_loaded > /dev/null; echo $?)
}

test_module_base_variable() {
    assert_not_equals "" "$MODULE_BASE" "MODULE_BASE is set"
    assert_success "MODULE_BASE directory exists" $(test -d "$MODULE_BASE"; echo $?)
}

test_loaded_modules_tracking() {
    # Reset loaded modules for clean test
    unset LOADED_MODULES
    declare -A LOADED_MODULES
    
    # Test that a non-existent module is not loaded
    is_module_loaded "nonexistent/module.sh"
    assert_failure "non-existent module should not be loaded" $?
}

# Run the tests
echo "Testing module_loader.sh functionality..."
test_module_loader_functions_exist
test_module_base_variable
test_loaded_modules_tracking