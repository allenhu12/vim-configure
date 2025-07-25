#!/bin/bash

# git_sh1_main.sh - Advanced main entry point for modular git_sh1 system
# This is the next-generation entry point with enhanced error handling,
# better module orchestration, and comprehensive parser integration

# Determine script directory (handle symlinks properly)
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
else
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Global error handler
set -E
trap 'handle_error ${LINENO} ${BASH_LINENO[0]} "$BASH_COMMAND" "$?"' ERR

# Enhanced error handling
handle_error() {
    local line_no=$1
    local bash_line_no=$2
    local command="$3"
    local exit_code=$4
    
    echo -e "\n${RED}Error occurred in git_sh1_main.sh:${NC}" >&2
    echo -e "${RED}  Line: $line_no${NC}" >&2
    echo -e "${RED}  Command: $command${NC}" >&2
    echo -e "${RED}  Exit code: $exit_code${NC}" >&2
    
    # Try to provide helpful context
    if [[ "$command" == *"load_module"* ]]; then
        echo -e "${YELLOW}  Module loading failed - check if all module files exist${NC}" >&2
    elif [[ "$command" == *"dispatch_command"* ]]; then
        echo -e "${YELLOW}  Command dispatch failed - check command syntax${NC}" >&2
    fi
    
    # Show troubleshooting hint
    echo -e "\n${CYAN}For troubleshooting help:${NC} $0 --help troubleshooting" >&2
    exit $exit_code
}

# Module loading with enhanced error handling (main script version)
load_main_module() {
    local module_path="$1"
    local full_path="${script_dir}/git_sh1_modules/${module_path}"
    
    
    if [[ ! -f "$full_path" ]]; then
        echo -e "${RED}Error: Module not found: $full_path${NC}" >&2
        echo -e "${YELLOW}Available modules:${NC}" >&2
        find "${script_dir}/git_sh1_modules" -name "*.sh" -type f | sed 's|^.*/git_sh1_modules/||' | sort >&2
        return 1
    fi
    
    if [[ ! -r "$full_path" ]]; then
        echo -e "${RED}Error: Module not readable: $full_path${NC}" >&2
        return 1
    fi
    
    # Source with error checking
    source "$full_path" || {
        echo -e "${RED}Error: Failed to load module: $module_path${NC}" >&2
        return 1
    }
    
    return 0
}

# Initialize system with comprehensive checks
initialize_system() {
    # Store original script_dir because config.sh will overwrite it
    local original_script_dir="$script_dir"
    
    # Set MODULE_BASE for compatibility with module_loader.sh
    # This must be the directory CONTAINING the modules, not the git_sh1_modules directory itself
    export MODULE_BASE="${script_dir}"
    
    # Load core modules directly first (before module_loader which conflicts)
    local core_modules=(
        "core/config.sh"
        "core/logging.sh" 
        "core/validation.sh"
        "core/utils.sh"
    )
    
    for module in "${core_modules[@]}"; do
        if ! load_main_module "$module"; then
            echo -e "${RED}Critical error: Failed to load core module: $module${NC}" >&2
            exit 1
        fi
        
        # Restore script_dir after each module load (config.sh overwrites it)
        if [[ "$module" == "core/config.sh" ]]; then
            script_dir="$original_script_dir"
        fi
    done
    
    # Now load module_loader.sh (which will override load_module function)
    # Force MODULE_BASE to be correct before loading module_loader.sh
    MODULE_BASE="${script_dir}/git_sh1_modules"
    if ! source "${script_dir}/git_sh1_modules/lib/module_loader.sh"; then
        echo -e "${YELLOW}Warning: Advanced module loader not available${NC}" >&2
    fi
    
    # Initialize logging system
    if ! init_logging; then
        echo -e "${RED}Warning: Logging system initialization failed${NC}" >&2
    fi
    
    # Validate system health
    if ! validate_system_health; then
        echo -e "${YELLOW}Warning: System health check failed - some features may not work${NC}" >&2
    fi
    
    return 0
}

# System health validation
validate_system_health() {
    local health_ok=true
    
    # Check module directory structure
    if [[ ! -d "${script_dir}/git_sh1_modules" ]]; then
        echo -e "${RED}Error: Module directory not found${NC}" >&2
        health_ok=false
    fi
    
    # Check critical modules exist
    local critical_modules=(
        "cli/dispatcher.sh"
        "cli/help.sh"
        "cli/parser.sh"
        "cli/completion.sh"
    )
    
    for module in "${critical_modules[@]}"; do
        if [[ ! -f "${script_dir}/git_sh1_modules/${module}" ]]; then
            echo -e "${RED}Error: Critical module missing: $module${NC}" >&2
            health_ok=false
        fi
    done
    
    # Check write permissions for logging
    if [[ ! -w "$script_dir" ]]; then
        echo -e "${YELLOW}Warning: No write permission for logging directory${NC}" >&2
    fi
    
    $health_ok
}

# Advanced command line processing with parser integration
process_command_line() {
    # Load CLI modules using the modular system's load_module function
    load_module "cli/parser.sh" || return 1
    load_module "cli/help.sh" || return 1
    load_module "cli/dispatcher.sh" || return 1
    
    # Handle environment variable propagation
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        export DRY_RUN=true
        echo -e "${YELLOW}Running in DRY_RUN mode${NC}" >&2
    fi
    
    if [[ "${VERBOSE:-}" == "true" ]]; then
        export VERBOSE=true
        echo -e "${CYAN}Verbose mode enabled${NC}" >&2
    fi
    
    # Process arguments through advanced parser if beneficial
    local use_advanced_parser=false
    
    # Use advanced parser for complex commands
    case "${1:-}" in
        worktree|feature|profile)
            use_advanced_parser=true
            ;;
        *)
            use_advanced_parser=false
            ;;
    esac
    
    if $use_advanced_parser && parse_and_validate "$@"; then
        echo -e "${CYAN}Using advanced parser for command validation${NC}" >&2
        # Advanced parsing succeeded - could use parsed results
        # For now, fall through to standard dispatcher
    fi
    
    # Dispatch command through standard system
    dispatch_command "$@"
    return $?
}

# Enhanced completion system setup
setup_completion_integration() {
    # Load completion module
    if load_module "cli/completion.sh" 2>/dev/null; then
        # Setup completion if in interactive shell
        if [[ $- == *i* ]]; then
            setup_git_sh1_completion
        fi
    fi
}

# Main execution flow
main() {
    # Initialize system
    initialize_system || exit 1
    
    # Setup completion (non-fatal if it fails)
    setup_completion_integration 2>/dev/null || true
    
    # Process command line
    process_command_line "$@"
    local exit_code=$?
    
    # Cleanup and logging
    if command -v cleanup_logging >/dev/null 2>&1; then
        cleanup_logging
    fi
    
    return $exit_code
}

# Version information for new main script
show_main_version() {
    echo -e "${CYAN}git_sh1_main.sh (Next-generation modular entry point)${NC}"
    echo -e "Enhanced error handling, advanced parsing, and module orchestration"
    echo -e "Based on git_sh1 modular system - Phase 7 implementation"
}

# Handle direct version request to this script
if [[ "${1:-}" == "--version-main" ]]; then
    show_main_version
    exit 0
fi

# Execute main function with all arguments
main "$@"
exit $?