#!/bin/bash

# git_sh1_modular.sh - Legacy compatibility wrapper for modular git_sh1 system
# Provides backward compatibility and enhanced error handling

# Determine script directory (handle symlinks properly)
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # Resolve symlink to actual script location
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
else
    # Regular script path
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Legacy compatibility mode detection
LEGACY_MODE=false
if [[ "${0##*/}" == "git_sh1.sh" || "${1:-}" == "--legacy" ]]; then
    LEGACY_MODE=true
    if [[ "${1:-}" == "--legacy" ]]; then
        shift  # Remove --legacy flag
    fi
fi

# Enhanced entry point selection
MAIN_SCRIPT=""
FALLBACK_SCRIPT=""

# Primary: Use new main script if available
if [[ -f "${script_dir}/git_sh1_main.sh" && -x "${script_dir}/git_sh1_main.sh" ]]; then
    MAIN_SCRIPT="${script_dir}/git_sh1_main.sh"
fi

# Fallback: Use module-based approach
if [[ -f "${script_dir}/git_sh1_modules/git_sh1_main.sh" ]]; then
    FALLBACK_SCRIPT="${script_dir}/git_sh1_modules/git_sh1_main.sh"
elif [[ -d "${script_dir}/git_sh1_modules" ]]; then
    # Direct module loading fallback
    FALLBACK_SCRIPT="modules"
fi

# Working directory context detection
# Use preserved user directory if available (from global wrapper)
CURRENT_DIR="${GIT_SH1_USER_PWD:-$(pwd)}"
GIT_DEPOT_CONTEXT=""

# Detect git-depot context based on user's actual working directory
if [[ "$(basename "$CURRENT_DIR")" == "git-depot" || -d "$CURRENT_DIR/repo_base" ]]; then
    GIT_DEPOT_CONTEXT="$CURRENT_DIR"
elif [[ -d "$CURRENT_DIR/git-depot" ]]; then
    GIT_DEPOT_CONTEXT="$CURRENT_DIR/git-depot"
fi

# Environment setup for compatibility
setup_environment() {
    # Export working area context
    if [[ -n "$GIT_DEPOT_CONTEXT" ]]; then
        export WORKING_AREA_OVERRIDE="$GIT_DEPOT_CONTEXT"
    fi
    
    # Legacy compatibility variables
    if $LEGACY_MODE; then
        export GIT_SH1_LEGACY_MODE=true
        export GIT_SH1_SCRIPT_NAME="git_sh1.sh"
    else
        export GIT_SH1_SCRIPT_NAME="git_sh1_modular.sh"
    fi
    
    # Propagate debug flags
    if [[ "${DEBUG:-}" == "true" ]]; then
        export DEBUG=true
        echo -e "\033[36mDebug mode enabled\033[0m" >&2
    fi
}

# Error handling with context
handle_script_error() {
    local exit_code=$1
    local script_path="$2"
    
    echo -e "\033[31mError: Modular git_sh1 system failed (exit code: $exit_code)\033[0m" >&2
    echo -e "\033[33mScript: $script_path\033[0m" >&2
    echo -e "\033[33mWorking directory: $CURRENT_DIR\033[0m" >&2
    
    if [[ $exit_code -eq 127 ]]; then
        echo -e "\033[33mCommand not found - check if script is executable\033[0m" >&2
    elif [[ $exit_code -eq 1 ]]; then
        echo -e "\033[33mGeneral error - check command syntax and arguments\033[0m" >&2
    fi
    
    echo -e "\n\033[36mFor troubleshooting:\033[0m" >&2
    echo -e "  $0 --help troubleshooting" >&2
    echo -e "  $0 test" >&2
    
    return $exit_code
}

# Direct module loading fallback
execute_via_modules() {
    local modules_dir="${script_dir}/git_sh1_modules"
    
    if [[ ! -d "$modules_dir" ]]; then
        echo -e "\033[31mError: Module directory not found: $modules_dir\033[0m" >&2
        return 1
    fi
    
    # Load core modules
    source "${modules_dir}/core/config.sh" || return 1
    source "${modules_dir}/core/logging.sh" || return 1  
    source "${modules_dir}/core/validation.sh" || return 1
    source "${modules_dir}/core/utils.sh" || return 1
    source "${modules_dir}/lib/module_loader.sh" || return 1
    source "${modules_dir}/cli/help.sh" || return 1
    source "${modules_dir}/cli/dispatcher.sh" || return 1
    
    # Initialize logging
    init_logging
    
    # Dispatch command
    dispatch_command "$@"
    return $?
}

# Main execution logic
main() {
    setup_environment
    
    # Handle special flags first
    case "${1:-}" in
        --version-wrapper)
            echo -e "\033[36mgit_sh1_modular.sh (Compatibility wrapper)\033[0m"
            echo -e "Provides legacy compatibility and enhanced error handling"
            echo -e "Routes to: ${MAIN_SCRIPT:-$FALLBACK_SCRIPT}"
            return 0
            ;;
        --debug-paths)
            echo "Script directory: $script_dir"
            echo "Main script: $MAIN_SCRIPT"
            echo "Fallback script: $FALLBACK_SCRIPT"
            echo "Current directory: $CURRENT_DIR"
            echo "Git depot context: $GIT_DEPOT_CONTEXT"
            echo "Legacy mode: $LEGACY_MODE"
            return 0
            ;;
    esac
    
    # Try main script first
    if [[ -n "$MAIN_SCRIPT" ]]; then
        "$MAIN_SCRIPT" "$@"
        local exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            handle_script_error $exit_code "$MAIN_SCRIPT"
        fi
        return $exit_code
    fi
    
    # Try fallback script
    if [[ -n "$FALLBACK_SCRIPT" && "$FALLBACK_SCRIPT" != "modules" ]]; then
        "$FALLBACK_SCRIPT" "$@"
        local exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            handle_script_error $exit_code "$FALLBACK_SCRIPT"
        fi
        return $exit_code
    fi
    
    # Final fallback: direct module loading
    if [[ "$FALLBACK_SCRIPT" == "modules" ]]; then
        execute_via_modules "$@"
        return $?
    fi
    
    # No working script found
    echo -e "\033[31mError: No functional modular git_sh1 system found\033[0m" >&2
    echo -e "\033[33mSearched paths:\033[0m" >&2
    echo -e "  Main: ${MAIN_SCRIPT:-not found}" >&2
    echo -e "  Fallback: ${FALLBACK_SCRIPT:-not found}" >&2
    echo -e "  Modules: ${script_dir}/git_sh1_modules/" >&2
    return 1
}

# Execute main function
main "$@"
exit $?