#!/bin/bash

# features/operations.sh - Feature operations for git_sh1_modules
# Handles feature creation, listing, show, add, switch, pick, and comment operations

# Load dependencies
if [ -z "$MODULE_LOADER_LOADED" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$script_dir/../lib/module_loader.sh"
fi

load_module "core/config.sh"
load_module "core/logging.sh"
load_module "core/validation.sh"
load_module "core/utils.sh"
load_module "features/core.sh"
load_module "repo/manager.sh"

# Enhanced feature creation with better validation and error handling
feature_create() {
    local feature_name=""
    local worktree=""
    local repos=()
    local force=false
    
    # Validate configuration first
    if ! validate_configuration; then
        return 1
    fi
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w)
                shift
                worktree="$1"
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                if [ -z "$feature_name" ]; then
                    feature_name="$1"
                    shift
                else
                    repos+=("$1")
                    shift
                fi
                ;;
        esac
    done
    
    # Input validation
    if [ -z "$feature_name" ] || [ ${#repos[@]} -eq 0 ]; then
        echo -e "${RED}Usage: $0 feature create [-w <worktree>] [--force] <feature_name> <repo1> [repo2] ...${NC}"
        echo -e "${YELLOW}  -w <worktree>: Optional. Specify which worktree to create the feature in${NC}"
        echo -e "${YELLOW}  --force: Overwrite existing feature${NC}"
        return 1
    fi
    
    # Sanitize feature name
    local original_feature_name="$feature_name"
    feature_name=$(sanitize_input "$feature_name")
    if [ "$feature_name" != "$original_feature_name" ]; then
        echo -e "${YELLOW}Feature name sanitized: $original_feature_name -> $feature_name${NC}"
    fi
    
    # Validate feature name format
    if ! validate_feature_name "$feature_name"; then
        return 1
    fi

    # Validate repositories
    for repo in "${repos[@]}"; do
        if ! validate_repo_name "$repo"; then
            echo -e "${RED}Error: Invalid repository name: $repo${NC}"
            return 1
        fi
    done
    
    # Sanitize worktree if provided
    if [ -n "$worktree" ]; then
        local original_worktree="$worktree"
        worktree=$(sanitize_input "$worktree")
        if [ "$worktree" != "$original_worktree" ]; then
            echo -e "${YELLOW}Worktree name sanitized: $original_worktree -> $worktree${NC}"
        fi
    fi
    
    if ! init_features_dir; then
        return 1
    fi
    
    local feature_dir="$features_dir/$feature_name"
    
    # Check if feature already exists
    if [ -d "$feature_dir" ] && [ "$force" = "false" ]; then
        echo -e "${RED}Error: Feature '$feature_name' already exists${NC}"
        echo -e "${YELLOW}Use --force to overwrite or choose a different name${NC}"
        return 1
    fi
    
    # Backup existing feature if force is used
    if [ -d "$feature_dir" ] && [ "$force" = "true" ]; then
        backup_feature_metadata "$feature_name"
        echo -e "${YELLOW}Overwriting existing feature: $feature_name${NC}"
    fi
    
    # Create feature directory atomically
    local temp_feature_dir="$features_dir/.tmp_${feature_name}_$$"
    if ! mkdir -p "$temp_feature_dir"; then
        echo -e "${RED}Error: Failed to create temporary feature directory${NC}"
        log "ERROR" "Failed to create temporary feature directory: $temp_feature_dir"
        return 1
    fi
    
    log "INFO" "Creating feature: $feature_name with repositories: ${repos[*]}"
    
    # Save the repository list to temp directory
    if ! printf "%s\n" "${repos[@]}" > "$temp_feature_dir/repos.txt"; then
        echo -e "${RED}Error: Failed to save repository list${NC}"
        rm -rf "$temp_feature_dir"
        return 1
    fi
    
    # Save worktree info
    if [ -n "$worktree" ]; then
        if ! echo "$worktree" > "$temp_feature_dir/worktree.txt"; then
            echo -e "${RED}Error: Failed to save worktree information${NC}"
            rm -rf "$temp_feature_dir"
            return 1
        fi
        echo -e "${CYAN}Using worktree: $worktree${NC}"
    fi
    
    # Save current branches for each repo
    local branches_json="{"
    local first=true
    
    for repo in "${repos[@]}"; do
        # Find the local folder for this repo
        local local_folder=""
        for pair in $repo_map; do
            IFS=':' read -r r f <<< "$pair"
            if [ "$r" == "$repo" ]; then
                local_folder="$f"
                break
            fi
        done
        
        if [ -z "$local_folder" ]; then
            echo -e "${RED}Repository $repo not found in repo_map${NC}"
            continue
        fi
        
        # Determine the repository path based on worktree
        local repo_path="$worktree_base_path/$worktree/$local_folder"
        
        if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
            echo -e "${RED}Repository not found: $repo_path${NC}"
            continue
        fi
        
        cd "$repo_path"
        local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        
        if [ "$first" = true ]; then
            first=false
        else
            branches_json+=","
        fi
        
        # Save branch and location info
        branches_json+="\"$repo\":{\"branch\":\"$current_branch\",\"path\":\"$repo_path\"}"
        
        # Create or switch to feature branch
        local feature_branch="feature/$feature_name"
        
        # Check if we're already on the feature branch
        if [ "$current_branch" == "$feature_branch" ]; then
            echo -e "${GREEN}Already on feature branch $feature_branch in $repo${NC}"
        elif git show-ref --verify --quiet "refs/heads/$feature_branch"; then
            # Try to switch to existing feature branch
            echo -e "${YELLOW}Switching to existing feature branch $feature_branch in $repo${NC}"
            if ! git checkout "$feature_branch" 2>/dev/null; then
                # If checkout fails, check if it's due to branch being in use by another worktree
                local worktree_info=$(git worktree list --porcelain | grep -B 2 "branch refs/heads/$feature_branch" | grep "worktree" | cut -d' ' -f2)
                if [ -n "$worktree_info" ]; then
                    echo -e "${CYAN}Feature branch $feature_branch is already checked out in worktree: $worktree_info${NC}"
                    echo -e "${CYAN}Adding $repo to feature tracking without switching branches${NC}"
                else
                    echo -e "${RED}Failed to checkout $feature_branch in $repo${NC}"
                fi
            fi
        else
            echo -e "${GREEN}Creating new feature branch $feature_branch in $repo${NC}"
            git checkout -b "$feature_branch"
        fi
    done
    
    branches_json+="}"
    
    # Save branches info to temp directory
    if ! echo "$branches_json" > "$temp_feature_dir/branches.json"; then
        echo -e "${RED}Error: Failed to save branches information${NC}"
        rollback_feature_creation "$feature_name"
        rm -rf "$temp_feature_dir"
        return 1
    fi
    
    # Atomically move temp directory to final location
    if [ -d "$feature_dir" ]; then
        rm -rf "$feature_dir"
    fi
    
    if ! mv "$temp_feature_dir" "$feature_dir"; then
        echo -e "${RED}Error: Failed to create feature directory${NC}"
        rm -rf "$temp_feature_dir"
        return 1
    fi
    
    echo -e "${GREEN}Feature '$feature_name' created successfully with repositories: ${repos[*]}${NC}"
    log "INFO" "Feature created successfully: $feature_name"
    return 0
}

# List all features
feature_list() {
    # Ensure repository system is initialized (for features_dir)
    if [[ -z "$features_dir" ]]; then
        if command -v init_repository_system > /dev/null 2>&1; then
            init_repository_system
        fi
    fi
    
    init_features_dir
    
    if [ ! -d "$features_dir" ] || [ -z "$(ls -A "$features_dir" 2>/dev/null)" ]; then
        echo -e "${YELLOW}No features found.${NC}"
        return
    fi
    
    echo -e "${CYAN}Available features:${NC}"
    for feature_dir in "$features_dir"/*; do
        if [ -d "$feature_dir" ]; then
            local feature_name=$(basename "$feature_dir")
            echo -e "\n${GREEN}Feature: $feature_name${NC}"
            
            if [ -f "$feature_dir/repos.txt" ]; then
                echo -e "${CYAN}  Repositories:${NC}"
                while IFS= read -r repo; do
                    echo -e "    - ${YELLOW}$repo${NC}"
                done < "$feature_dir/repos.txt"
            fi
            
            if [ -f "$feature_dir/worktree.txt" ]; then
                echo -e "${CYAN}  Worktree:${NC} $(cat "$feature_dir/worktree.txt")"
            fi
            
            if [ -f "$feature_dir/comment.txt" ]; then
                echo -e "${CYAN}  Comment:${NC} $(cat "$feature_dir/comment.txt")"
            fi
        fi
    done
}

# Add or update comment for a feature
feature_comment() {
    local feature_name=$1
    shift
    local comment="$*"
    
    if [ -z "$feature_name" ] || [ -z "$comment" ]; then
        echo -e "${RED}Usage: $0 feature comment <feature_name> <comment>${NC}"
        return 1
    fi
    
    local feature_dir="$features_dir/$feature_name"
    if [ ! -d "$feature_dir" ]; then
        echo -e "${RED}Feature '$feature_name' not found${NC}"
        return 1
    fi
    
    echo "$comment" > "$feature_dir/comment.txt"
    echo -e "${GREEN}Comment added to feature '$feature_name'${NC}"
}

echo "Feature operations module loaded"