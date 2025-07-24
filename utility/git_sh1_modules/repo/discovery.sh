#!/bin/bash

# repo/discovery.sh - Repository discovery and path resolution for git_sh1_modules
# Depends on: core/config.sh (for script_dir), core/logging.sh (for log function), core/validation.sh (for validate_path)

# Find git-depot directory by traversing up the directory tree
find_git_depot() {
    local search_path="$1"
    local max_depth=10
    local current_depth=0
    
    if [[ -z "$search_path" ]]; then
        log "ERROR" "find_git_depot: search path is required"
        return 1
    fi
    
    while [[ "$search_path" != "/" && $current_depth -lt $max_depth ]]; do
        if [[ "${search_path##*/}" == "git-depot" ]]; then
            echo "$search_path"
            return 0
        fi
        search_path="$(dirname "$search_path")"
        ((current_depth++))
    done
    
    log "ERROR" "Could not find git-depot directory within $max_depth levels from $1"
    return 1
}

# Find repo_base directory with comprehensive error handling
find_repo_base() {
    local git_depot="$1"
    local repo_base_candidates=()
    
    if [[ -z "$git_depot" ]]; then
        log "ERROR" "find_repo_base: git_depot path is required"
        return 1
    fi
    
    if [[ ! -d "$git_depot" ]]; then
        log "ERROR" "find_repo_base: git_depot directory does not exist: $git_depot"
        return 1
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}DEBUG: Searching for repo_base directories in: $git_depot${NC}" >&2
    fi
    
    # Look for directories containing "repo_base" in their name
    while IFS= read -r -d '' dir; do
        repo_base_candidates+=("$dir")
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${CYAN}DEBUG: Found repo_base candidate: $dir${NC}" >&2
        fi
    done < <(find "$git_depot" -maxdepth 2 -type d -name "*repo_base*" -print0 2>/dev/null)
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}DEBUG: Total repo_base candidates found: ${#repo_base_candidates[@]}${NC}" >&2
    fi
    
    if [ ${#repo_base_candidates[@]} -eq 0 ]; then
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${RED}DEBUG: No repo_base directories found. Listing top-level directories:${NC}" >&2
            ls -la "$git_depot" 2>/dev/null >&2 || echo "Cannot list git_depot directory" >&2
        fi
        log "ERROR" "No directories containing 'repo_base' found in $git_depot"
        return 1
    elif [ ${#repo_base_candidates[@]} -eq 1 ]; then
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${GREEN}DEBUG: Using single repo_base candidate: ${repo_base_candidates[0]}${NC}" >&2
        fi
        echo "${repo_base_candidates[0]}"
        return 0
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${YELLOW}DEBUG: Multiple repo_base candidates found:${NC}" >&2
            for candidate in "${repo_base_candidates[@]}"; do
                echo -e "${YELLOW}  - $candidate${NC}" >&2
            done
        fi
        log "WARN" "Multiple repo_base candidates found, using first: ${repo_base_candidates[0]}"
        echo "${repo_base_candidates[0]}"
        return 0
    fi
}

# Initialize repository paths and validate configuration
init_repo_paths() {
    # Initialize global path variables used by other modules
    if [[ -z "$script_dir" ]]; then
        log "ERROR" "init_repo_paths: script_dir not set"
        return 1
    fi
    
    # Find git-depot directory starting from current working directory
    local current_dir="$(pwd)"
    
    # Check if working area override is set (for when script is run from different git-depot)
    if [[ -n "$WORKING_AREA_OVERRIDE" ]]; then
        current_dir="$WORKING_AREA_OVERRIDE"
        log "INFO" "Using working area override: $current_dir"
    fi
    
    # If current directory is named git-depot or contains repo_base, use it directly
    if [[ "$(basename "$current_dir")" == "git-depot" ]] || [[ -d "$current_dir/repo_base" ]]; then
        git_depot_dir="$current_dir"
        log "INFO" "Using current directory as git-depot: $git_depot_dir"
    else
        # Otherwise, search up the directory tree
        if ! git_depot_dir=$(find_git_depot "$current_dir"); then
            echo -e "${RED}Error: Could not find the git-depot directory${NC}"
            echo -e "${YELLOW}Please ensure this script is run from within a git-depot directory structure${NC}"
            echo -e "${YELLOW}Current directory: $current_dir${NC}"
            return 1
        fi
    fi
    
    log "INFO" "Found git-depot directory: $git_depot_dir"
    
    # Find repo_base directory
    if ! repo_base=$(find_repo_base "$git_depot_dir"); then
        echo -e "${RED}Error: Could not find a directory containing 'repo_base' in its name${NC}"
        echo -e "${YELLOW}Expected to find a directory like 'my_repo_base' or 'repo_base_main' in $git_depot_dir${NC}"
        return 1
    fi
    
    log "INFO" "Using repo_base directory: $repo_base"
    
    # Set worktree base path to git-depot directory
    worktree_base_path="$git_depot_dir"
    log "INFO" "Using worktree_base_path: $worktree_base_path"
    
    # Initialize profiles directory  
    profiles_dir="$git_depot_dir/.git_sh1_profiles"
    
    # Sort the default repo_map by depth to ensure correct processing order
    if command -v sort_repo_map_once > /dev/null 2>&1; then
        sort_repo_map_once
    fi
    
    return 0
}

# Validate repository name against the repo_map
validate_repo_name() {
    local repo_name="$1"
    
    if [[ -z "$repo_name" ]]; then
        log "ERROR" "validate_repo_name: repository name is required"
        return 1
    fi
    
    # Sanitize input
    local repo_name_clean
    if command -v sanitize_input > /dev/null 2>&1; then
        repo_name_clean=$(sanitize_input "$repo_name")
        if [ "$repo_name" != "$repo_name_clean" ]; then
            log "ERROR" "Invalid repository name: $repo_name"
            return 1
        fi
    fi
    
    # Check if repo exists in repo_map
    local found=false
    for pair in $repo_map; do
        IFS=':' read -r repo local_folder <<< "$pair"
        if [ "$repo" == "$repo_name" ]; then
            found=true
            break
        fi
    done
    
    if [ "$found" = "false" ] && [ "$repo_name" != "all" ]; then
        log "ERROR" "Repository '$repo_name' not found in configuration"
        return 1
    fi
    
    return 0
}

# Get repository local path from repository name
get_repo_path() {
    local repo_name="$1"
    
    if [[ -z "$repo_name" ]]; then
        log "ERROR" "get_repo_path: repository name is required"
        return 1
    fi
    
    # Find the repository in repo_map
    for pair in $repo_map; do
        IFS=':' read -r repo local_folder <<< "$pair"
        if [ "$repo" == "$repo_name" ]; then
            echo "$repo_base/$local_folder"
            return 0
        fi
    done
    
    log "ERROR" "Repository '$repo_name' not found in repo_map"
    return 1
}

# Check if a repository path exists and is a valid git repository
is_repo_valid() {
    local repo_path="$1"
    
    if [[ -z "$repo_path" ]]; then
        return 1
    fi
    
    # Check if directory exists and is a git repository
    if [[ -d "$repo_path" ]] && ([[ -d "$repo_path/.git" ]] || [[ -f "$repo_path/.git" ]]); then
        # Additional validation: check if it's a valid git repo
        if (cd "$repo_path" && git rev-parse --git-dir >/dev/null 2>&1); then
            return 0
        fi
    fi
    
    return 1
}

# Sort repo_map entries by path depth (shallowest first) to avoid directory conflicts
sort_repo_map_by_depth() {
    # Create temporary arrays to hold repo entries with their depths
    local entries=()
    local depths=()
    
    # Parse repo_map and calculate depth for each entry
    for pair in $repo_map; do
        IFS=':' read -r repo_name local_folder <<< "$pair"
        if [[ -n "$repo_name" && -n "$local_folder" ]]; then
            # Count the number of '/' characters to determine depth
            local depth=$(echo "$local_folder" | tr -cd '/' | wc -c)
            entries+=("$pair")
            depths+=("$depth")
        fi
    done
    
    # Sort entries by depth in ascending order (shallowest first)
    local n=${#entries[@]}
    for ((i = 0; i < n - 1; i++)); do
        for ((j = 0; j < n - i - 1; j++)); do
            if [[ ${depths[j]} -gt ${depths[j+1]} ]]; then
                # Swap entries
                local temp_entry="${entries[j]}"
                local temp_depth="${depths[j]}"
                entries[j]="${entries[j+1]}"
                depths[j]="${depths[j+1]}"
                entries[j+1]="$temp_entry"
                depths[j+1]="$temp_depth"
            fi
        done
    done
    
    # Output sorted entries
    for entry in "${entries[@]}"; do
        echo "$entry"
    done
}