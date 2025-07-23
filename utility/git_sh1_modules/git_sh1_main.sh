#!/bin/bash

# git_sh1_main.sh - Modular entry point for git_sh1 functionality
# This is the new lightweight main script that orchestrates modular components

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_BASE="${SCRIPT_DIR}"

# Set global variables that modules depend on
script_dir="$SCRIPT_DIR"

# Load module loader
if ! source "${MODULE_BASE}/lib/module_loader.sh"; then
    echo "Error: Failed to load module loader" >&2
    exit 1
fi

# Load all required modules in dependency order
if ! load_all_modules; then
    echo "Error: Failed to load required modules" >&2
    exit 1
fi

# Main entry point - delegates to the dispatcher
main() {
    local exit_code=0
    
    # Initialize logging and acquire lock (from core modules)
    init_logging
    log "INFO" "Starting git_sh1_main.sh from directory: $script_dir"
    
    if ! acquire_lock; then
        exit 1
    fi
    
    # Set up dry-run and verbose modes from environment
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}Running in DRY-RUN mode - no changes will be made${NC}"
    fi
    
    # Delegate to CLI dispatcher
    if command -v dispatch_command > /dev/null 2>&1; then
        dispatch_command "$@"
        exit_code=$?
    else
        echo "Error: Command dispatcher not available" >&2
        exit_code=1
    fi
    
    return $exit_code
}

# Handle script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
    exit $?
fi

# If sourced, the main function is available for calling