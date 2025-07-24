#!/bin/bash

# features/core.sh - Feature core management for git_sh1_modules
# Handles feature directory initialization, backup, and core utilities

# Load dependencies
if [ -z "$MODULE_LOADER_LOADED" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$script_dir/../lib/module_loader.sh"
fi

load_module "core/config.sh"
load_module "core/logging.sh"
load_module "core/validation.sh"
load_module "core/utils.sh"

# Initialize features directory
init_features_dir() {
    if [ ! -d "$features_dir" ]; then
        if ! mkdir -p "$features_dir"; then
            echo -e "${RED}Error: Failed to create features directory: $features_dir${NC}"
            log "ERROR" "Failed to create features directory: $features_dir"
            return 1
        fi
        echo -e "${GREEN}Initialized features directory at: $features_dir${NC}"
        log "INFO" "Initialized features directory: $features_dir"
    fi
    return 0
}

# Rollback function for failed operations
rollback_feature_creation() {
    local feature_name="$1"
    local feature_dir="$features_dir/$feature_name"
    
    log "INFO" "Rolling back feature creation: $feature_name"
    
    if [ -d "$feature_dir" ]; then
        echo -e "${YELLOW}Rolling back incomplete feature: $feature_name${NC}"
        rm -rf "$feature_dir"
        log "INFO" "Removed incomplete feature directory: $feature_dir"
    fi
}

# Backup feature metadata
backup_feature_metadata() {
    local feature_name="$1"
    local feature_dir="$features_dir/$feature_name"
    local backup_dir="$features_dir/.backups"
    local backup_file="$backup_dir/${feature_name}_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if [ ! -d "$feature_dir" ]; then
        return 0
    fi
    
    if ! mkdir -p "$backup_dir"; then
        log "WARN" "Failed to create backup directory: $backup_dir"
        return 1
    fi
    
    if tar -czf "$backup_file" -C "$features_dir" "$feature_name" 2>/dev/null; then
        log "INFO" "Created feature backup: $backup_file"
        return 0
    else
        log "WARN" "Failed to create feature backup for: $feature_name"
        return 1
    fi
}

# Validate feature name format
validate_feature_name() {
    local feature_name="$1"
    
    if [[ ! "$feature_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid feature name. Use only letters, numbers, underscores, and hyphens.${NC}"
        return 1
    fi
    return 0
}

# Get feature directory path
get_feature_dir() {
    local feature_name="$1"
    echo "$features_dir/$feature_name"
}

# Check if feature exists
feature_exists() {
    local feature_name="$1"
    local feature_dir="$features_dir/$feature_name"
    [ -d "$feature_dir" ]
}

# Get feature worktree
get_feature_worktree() {
    local feature_name="$1"
    local feature_dir="$features_dir/$feature_name"
    local worktree_override="$2"
    
    if [ -n "$worktree_override" ]; then
        echo "$worktree_override"
    elif [ -f "$feature_dir/worktree.txt" ]; then
        cat "$feature_dir/worktree.txt"
    elif [ -f "$feature_dir/detected_worktree.txt" ]; then
        cat "$feature_dir/detected_worktree.txt"
    fi
}

# Get feature repositories
get_feature_repos() {
    local feature_name="$1"
    local feature_dir="$features_dir/$feature_name"
    
    if [ -f "$feature_dir/repos.txt" ]; then
        cat "$feature_dir/repos.txt"
    fi
}

# Add repository to feature
add_repo_to_feature() {
    local feature_name="$1"
    local repo_name="$2"
    local feature_dir="$features_dir/$feature_name"
    
    # Check if repo already exists
    if [ -f "$feature_dir/repos.txt" ] && grep -q "^$repo_name$" "$feature_dir/repos.txt"; then
        return 1
    fi
    
    echo "$repo_name" >> "$feature_dir/repos.txt"
    return 0
}

echo "Feature core management module loaded"