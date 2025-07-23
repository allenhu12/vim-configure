#!/bin/bash

# Module loader for git_sh1_modules
# Provides centralized module loading with dependency resolution

# Determine module base directory
if [[ -z "$MODULE_BASE" ]]; then
    MODULE_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Track loaded modules to prevent double-loading (using simple variable for compatibility)
LOADED_MODULES=""

# Check if a module is already loaded
is_module_in_loaded_list() {
    local module_path="$1"
    echo "$LOADED_MODULES" | grep -q "|${module_path}|"
}

# Add module to loaded list
add_to_loaded_list() {
    local module_path="$1"
    LOADED_MODULES="${LOADED_MODULES}|${module_path}|"
}

# Load a module with error handling
load_module() {
    local module_path="$1"
    local module_file="${MODULE_BASE}/${module_path}"
    
    # Check if already loaded
    if is_module_in_loaded_list "$module_path"; then
        return 0
    fi
    
    # Verify module file exists
    if [[ ! -f "$module_file" ]]; then
        echo "Error: Module not found: $module_file" >&2
        return 1
    fi
    
    # Load the module
    if source "$module_file"; then
        add_to_loaded_list "$module_path"
        if [[ "${VERBOSE:-false}" == "true" ]]; then
            echo "Loaded module: $module_path" >&2
        fi
        return 0
    else
        echo "Error: Failed to load module: $module_file" >&2
        return 1
    fi
}

# Load core modules in dependency order
load_core_modules() {
    load_module "core/config.sh" || return 1
    load_module "core/logging.sh" || return 1
    load_module "core/validation.sh" || return 1
    load_module "core/utils.sh" || return 1
    return 0
}

# Load repository modules
load_repo_modules() {
    load_core_modules || return 1
    load_module "repo/discovery.sh" || return 1
    load_module "repo/operations.sh" || return 1
    load_module "repo/manager.sh" || return 1
    return 0
}

# Load worktree modules
load_worktree_modules() {
    load_repo_modules || return 1
    load_module "worktree/validator.sh" || return 1
    load_module "worktree/manager.sh" || return 1
    return 0
}

# Load feature modules
load_feature_modules() {
    load_worktree_modules || return 1
    load_module "features/metadata.sh" || return 1
    load_module "features/core.sh" || return 1
    load_module "features/operations.sh" || return 1
    return 0
}

# Load profile modules
load_profile_modules() {
    load_repo_modules || return 1
    load_module "profiles/parser.sh" || return 1
    load_module "profiles/manager.sh" || return 1
    return 0
}

# Load CLI modules
load_cli_modules() {
    load_module "cli/help.sh" || return 1
    load_module "cli/completion.sh" || return 1
    load_module "cli/parser.sh" || return 1
    load_module "cli/dispatcher.sh" || return 1
    return 0
}

# Load all modules
load_all_modules() {
    load_core_modules || return 1
    load_repo_modules || return 1
    load_worktree_modules || return 1
    load_feature_modules || return 1
    load_profile_modules || return 1
    load_cli_modules || return 1
    return 0
}

# Check if a module is loaded (public interface)
is_module_loaded() {
    local module_path="$1"
    is_module_in_loaded_list "$module_path"
}

# List all loaded modules
list_loaded_modules() {
    echo "$LOADED_MODULES" | tr '|' '\n' | grep -v '^$' | sort
}