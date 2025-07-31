#!/bin/bash

# =============================================================================
# Worktree Management Module
# Part of the modular git_sh1 system
# =============================================================================

# Validate worktree path against base directory
validate_worktree_path() {
    local path="$1"
    local base_path="$2"
    
    # Convert to absolute path
    if [[ "$path" != /* ]]; then
        path="$base_path/$path"
    fi
    
    # Normalize path manually (remove .. and . components)
    # Convert to canonical form without requiring directory to exist
    local normalized_path=""
    IFS='/' read -ra PATH_PARTS <<< "$path"
    local path_components=()
    
    for part in "${PATH_PARTS[@]}"; do
        if [[ "$part" == "." ]] || [[ -z "$part" ]]; then
            continue
        elif [[ "$part" == ".." ]]; then
            if [[ ${#path_components[@]} -gt 0 ]]; then
                unset 'path_components[-1]'
            fi
        else
            path_components+=("$part")
        fi
    done
    
    # Rebuild the path
    normalized_path="/"
    for component in "${path_components[@]}"; do
        normalized_path="$normalized_path$component/"
    done
    # Remove trailing slash except for root
    if [[ "$normalized_path" != "/" ]]; then
        normalized_path="${normalized_path%/}"
    fi
    
    # Check if path is within allowed boundaries
    if [[ "$normalized_path" != "$base_path"* ]]; then
        log "ERROR" "Worktree path outside allowed boundaries: $normalized_path"
        return 1
    fi
    
    echo "$normalized_path"
    return 0
}

# Main worktree addition function
add_worktree() {
    repo=$1
    local_branch=$2
    remote_branch=$3

    if [ "$repo" == "all" ]; then
        for pair in $(sort_repo_map_by_depth); do
            IFS=':' read -r repo_name local_folder <<< "$pair"
            add_worktree_for_repo "$repo_name" "$local_folder" "$local_branch" "$remote_branch"
        done
    else
        repo_found=false
        for pair in $repo_map; do
            IFS=':' read -r repo_name local_folder <<< "$pair"
            if [ "$repo" == "$repo_name" ]; then
                repo_found=true
                add_worktree_for_repo "$repo_name" "$local_folder" "$local_branch" "$remote_branch"
                break
            fi
        done
        if ! $repo_found; then
            echo -e "${RED}Repository $repo not found in repo_map${NC}"
        fi
    fi
}

# Enhanced add_worktree function with profile-aware upstream detection
add_worktree_with_profile() {
    local repo="$1"
    local local_branch="$2"
    local remote_branch="$3"
    local profile_name="$4"
    
    if [ "$repo" == "all" ]; then
        echo -e "${CYAN}Creating worktrees for all repositories...${NC}"
        
        # Count total repositories first
        local total_count=0
        for pair in $(sort_repo_map_by_depth); do
            total_count=$((total_count + 1))
        done
        
        local current=0
        for pair in $(sort_repo_map_by_depth); do
            IFS=':' read -r repo_name local_folder <<< "$pair"
            current=$((current + 1))
            local individual_remote_branch="$remote_branch"
            
            show_progress "$current" "$total_count" "Creating worktree for $repo_name"
            
            # Auto-detect upstream for this specific repository if profile specified and no explicit -rb
            if [ -n "$profile_name" ] && [ -z "$remote_branch" ]; then
                if upstream=$(get_upstream_from_profile "$profile_name" "$repo_name"); then
                    individual_remote_branch="origin/$upstream"
                    echo -e "${CYAN}Auto-detected upstream for $repo_name: $individual_remote_branch${NC}"
                else
                    echo -e "${YELLOW}Warning: No upstream found for $repo_name in profile $profile_name${NC}"
                    echo -e "${RED}Error: Cannot create worktree for $repo_name - upstream not available${NC}"
                    continue
                fi
            elif [ -z "$remote_branch" ]; then
                echo -e "${RED}Error: -rb parameter required for $repo_name when not using --profile${NC}"
                continue
            fi
            
            add_worktree_for_repo "$repo_name" "$local_folder" "$local_branch" "$individual_remote_branch"
        done
    else
        # Handle specific repository
        local specific_remote_branch="$remote_branch"
        
        # Auto-detect upstream for specific repository if profile specified and no explicit -rb
        if [ -n "$profile_name" ] && [ -z "$remote_branch" ]; then
            if upstream=$(get_upstream_from_profile "$profile_name" "$repo"); then
                specific_remote_branch="origin/$upstream"
                echo -e "${CYAN}Auto-detected upstream for $repo: $specific_remote_branch${NC}"
            else
                echo -e "${YELLOW}Warning: No upstream found for $repo in profile $profile_name${NC}"
                echo -e "${RED}Error: -rb parameter required when upstream not available in profile${NC}"
                return 1
            fi
        elif [ -z "$remote_branch" ]; then
            echo -e "${RED}Error: -rb parameter required when not using --profile${NC}"
            return 1
        fi
        
        # Use existing add_worktree function for specific repository
        add_worktree "$repo" "$local_branch" "$specific_remote_branch"
    fi
}

# Core worktree creation function for individual repository
add_worktree_for_repo() {
    local repo="$1"
    local local_folder="$2"
    local local_branch="$3"
    local remote_branch="$4"
    local repo_dir
    local worktree_dir
    
    # Validate inputs
    if [ -z "$repo" ] || [ -z "$local_folder" ] || [ -z "$local_branch" ] || [ -z "$remote_branch" ]; then
        echo -e "${RED}Error: Missing required parameters for worktree creation${NC}"
        log "ERROR" "Missing parameters: repo=$repo, folder=$local_folder, local_branch=$local_branch, remote_branch=$remote_branch"
        return 1
    fi
    
    # Sanitize inputs
    local_branch=$(sanitize_input "$local_branch")
    
    # Validate and construct paths
    if ! repo_dir=$(validate_path "$repo_base/$local_folder" "$repo_base"); then
        echo -e "${RED}Invalid repository path for: $repo${NC}"
        return 1
    fi
    
    if ! worktree_dir=$(validate_worktree_path "$worktree_base_path/$local_branch/$local_folder" "$worktree_base_path"); then
        echo -e "${RED}Invalid worktree path for: $repo${NC}"
        return 1
    fi

    if [ ! -d "$repo_dir/.git" ]; then
        echo -e "${RED}Repository not found or not a Git repository: $repo_dir${NC}"
        log "ERROR" "Repository not found: $repo_dir"
        return 1
    fi

    if ! cd "$repo_dir"; then
        echo -e "${RED}Failed to enter repository directory: $repo_dir${NC}"
        log "ERROR" "Failed to enter repository directory: $repo_dir for $repo"
        return 1
    fi

    # Validate git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}Invalid git repository: $repo_dir${NC}"
        log "ERROR" "Invalid git repository: $repo_dir"
        return 1
    fi

    # Prune any stale worktree entries
    log "INFO" "Pruning stale worktree entries for $repo"
    git worktree prune 2>/dev/null || true

    # Remove the worktree directory if it already exists
    if [ -d "$worktree_dir" ]; then
        echo -e "${YELLOW}Removing existing worktree directory: $worktree_dir${NC}"
        log "INFO" "Removing existing worktree: $worktree_dir"
        
        # Try to remove via git first, then force remove
        if ! git worktree remove --force "$worktree_dir" 2>/dev/null; then
            log "WARN" "Git worktree remove failed, force removing directory"
            if ! rm -rf "$worktree_dir"; then
                echo -e "${RED}Failed to remove existing worktree directory: $worktree_dir${NC}"
                log "ERROR" "Failed to remove worktree directory: $worktree_dir"
                return 1
            fi
        fi
    fi

    echo -e "${CYAN}Processing repository: ${YELLOW}$repo${NC}"
    log "INFO" "Creating worktree for $repo: $local_branch from $remote_branch"

    # Validate remote branch exists
    if ! git show-ref --verify --quiet "refs/remotes/$remote_branch" && 
       ! git ls-remote --heads origin "${remote_branch#origin/}" | grep -q .; then
        echo -e "${RED}Remote branch $remote_branch does not exist${NC}"
        log "ERROR" "Remote branch $remote_branch does not exist for $repo"
        return 1
    fi

    # Create parent directory for worktree
    local worktree_parent=$(dirname "$worktree_dir")
    if ! mkdir -p "$worktree_parent"; then
        echo -e "${RED}Failed to create worktree parent directory: $worktree_parent${NC}"
        log "ERROR" "Failed to create worktree parent directory: $worktree_parent"
        return 1
    fi

    # Check if the local branch exists
    if git show-ref --verify --quiet "refs/heads/$local_branch"; then
        echo -e "${YELLOW}Branch $local_branch already exists, reusing it.${NC}"
        log "INFO" "Reusing existing branch $local_branch for $repo"
        
        # If the branch exists, just add the worktree with the existing branch
        if ! git worktree add -f "$worktree_dir" "$local_branch"; then
            echo -e "${RED}Failed to add worktree for existing branch $local_branch${NC}"
            log "ERROR" "Failed to add worktree for existing branch $local_branch in $repo"
            return 1
        fi
    else
        echo -e "${GREEN}Creating new branch $local_branch from $remote_branch.${NC}"
        log "INFO" "Creating new branch $local_branch from $remote_branch for $repo"
        
        # If the branch doesn't exist, create it and add it as a worktree
        if ! git worktree add --checkout -b "$local_branch" "$worktree_dir" "$remote_branch"; then
            echo -e "${RED}Failed to create worktree with new branch $local_branch${NC}"
            log "ERROR" "Failed to create worktree with new branch $local_branch in $repo"
            return 1
        fi
    fi

    # Verify worktree was created successfully
    if [ ! -d "$worktree_dir/.git" ] && [ ! -f "$worktree_dir/.git" ]; then
        echo -e "${RED}Worktree creation failed - directory not found: $worktree_dir${NC}"
        log "ERROR" "Worktree creation failed for $repo"
        return 1
    fi

    echo -e "${GREEN}Successfully added worktree for $repo at $worktree_dir${NC}"
    log "INFO" "Successfully created worktree for $repo at $worktree_dir"
    echo -e "${CYAN}Completed processing repository: ${YELLOW}${repo}${NC}\n"
    return 0
}

# Pull and rebase each repository in the worktree
pull_rebase_worktree() {
    repo=$1
    local_branch=$2

    if [ "$repo" == "all" ]; then
        echo -e "${CYAN}Pull-rebasing all repositories...${NC}"
        
        # Count total repositories first
        local total_count=0
        for pair in $(sort_repo_map_by_depth); do
            total_count=$((total_count + 1))
        done
        
        local current=0
        for pair in $(sort_repo_map_by_depth); do
            IFS=':' read -r repo_name local_folder <<< "$pair"
            current=$((current + 1))
            show_progress "$current" "$total_count" "Pull-rebasing $repo_name"
            pull_rebase_repo "$repo_name" "$local_folder" "$local_branch"
        done
    else
        repo_found=false
        for pair in $repo_map; do
            IFS=':' read -r repo_name local_folder <<< "$pair"
            if [ "$repo" == "$repo_name" ]; then
                repo_found=true
                pull_rebase_repo "$repo_name" "$local_folder" "$local_branch"
                break
            fi
        done
        if ! $repo_found; then
            echo -e "${RED}Repository $repo not found in repo_map${NC}"
        fi
    fi
}

# Pull and rebase individual repository worktree
pull_rebase_repo() {
    repo=$1
    local_folder=$2
    local_branch=$3

    worktree_dir="$worktree_base_path/$local_branch/$local_folder"

    if [ ! -d "$worktree_dir/.git" ] && [ ! -f "$worktree_dir/.git" ]; then
        echo -e "${RED}Worktree directory not found or not a Git repository: $worktree_dir${NC}"
        return
    fi

    cd "$worktree_dir"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo -e "${CYAN}Pulling and rebasing $repo in $local_branch (current branch: $current_branch)${NC}"
    git pull --rebase --autostash
    echo -e "${GREEN}Completed pull-rebase for $repo in $local_branch (current branch: $current_branch)${NC}"
    echo -e "${CYAN}Completed processing repository: ${YELLOW}${repo}${NC}\n"
}

# Profile-aware worktree pull-rebase function
pull_rebase_worktree_with_profile() {
    local repo="$1"
    local local_branch="$2"
    local profile_name="$3"
    
    if [ "$repo" == "all" ]; then
        echo -e "${CYAN}Pull-rebasing all repositories with profile: $profile_name...${NC}"
        
        # Count total repositories first
        local total_count=0
        for pair in $(sort_repo_map_by_depth); do
            total_count=$((total_count + 1))
        done
        
        local current=0
        for pair in $(sort_repo_map_by_depth); do
            IFS=':' read -r repo_name local_folder <<< "$pair"
            current=$((current + 1))
            show_progress "$current" "$total_count" "Pull-rebasing $repo_name"
            pull_rebase_repo "$repo_name" "$local_folder" "$local_branch"
        done
    else
        # Handle specific repository with profile
        pull_rebase_worktree "$repo" "$local_branch"
    fi
}

log "INFO" "Worktree management module loaded"