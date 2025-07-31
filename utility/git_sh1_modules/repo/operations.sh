#!/bin/bash

# repo/operations.sh - Repository operations for git_sh1_modules  
# Depends on: core/config.sh, core/logging.sh, core/validation.sh, core/utils.sh, repo/discovery.sh

# SSH connectivity check
check_ssh_connectivity() {
    local ssh_host="ruckus-git.ruckuswireless.com"
    local ssh_port="7999"
    
    log "INFO" "Checking SSH connectivity to $ssh_host:$ssh_port"
    
    if command -v nc >/dev/null 2>&1; then
        if ! nc -z "$ssh_host" "$ssh_port" 2>/dev/null; then
            log "ERROR" "Cannot connect to $ssh_host:$ssh_port"
            return 1
        fi
    elif command -v timeout >/dev/null 2>&1; then
        if ! timeout 5 bash -c "cat < /dev/null > /dev/tcp/$ssh_host/$ssh_port" 2>/dev/null; then
            log "ERROR" "Cannot connect to $ssh_host:$ssh_port"
            return 1
        fi
    else
        log "WARN" "Cannot check SSH connectivity - neither nc nor timeout available"
        return 0  # Don't fail if we can't check
    fi
    
    return 0
}

# Verify a single repository exists and is valid
verify_single_repo() {
    local repo="$1"
    local local_folder="$2"
    local repo_path
    
    if [[ -z "$repo" ]] || [[ -z "$local_folder" ]]; then
        log "ERROR" "verify_single_repo: repository name and local folder required"
        return 1
    fi
    
    # Ensure repo_base is initialized
    if [[ -z "$repo_base" ]]; then
        log "ERROR" "verify_single_repo: repo_base not initialized"
        return 1
    fi
    
    # Validate and construct repository path
    if ! repo_path=$(validate_path "$repo_base/$local_folder" "$repo_base"); then
        echo -e "${RED}Invalid path for repo: $repo${NC}"
        log "ERROR" "Invalid repository path for $repo: $repo_base/$local_folder"
        return 1
    fi
    
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${CYAN}Checking repo: $repo${NC}"
        echo -e "${CYAN}Repo path: $repo_path${NC}"
    fi
    
    # Check if directory exists and is a git repository
    if [ -d "$repo_path" ] && ([ -d "$repo_path/.git" ] || [ -f "$repo_path/.git" ]); then
        echo -e "${GREEN}✓ Exists:  $repo${NC}"
        log "INFO" "Repository exists: $repo at $repo_path"
        
        # Additional validation: check if it's a valid git repo
        if ! (cd "$repo_path" && git rev-parse --git-dir >/dev/null 2>&1); then
            echo -e "${YELLOW}  Warning: Directory exists but may not be a valid git repository${NC}"
            log "WARN" "Directory exists but not a valid git repo: $repo_path"
        fi
        
        return 0
    else
        echo -e "${RED}✗ Missing: $repo${NC}"
        log "INFO" "Repository missing: $repo at $repo_path"
        return 1
    fi
}

# Enhanced repository verification with better error handling
verify_repos() {
    local target_repo="$1"
    local existing_repos=0
    local missing_repos=0
    local total_repos=0
    local failed_repos=()

    log "INFO" "Starting repository verification"
    echo -e "${CYAN}Verifying repositories:${NC}"
    echo -e "${YELLOW}Script directory: $script_dir${NC}"
    echo -e "${YELLOW}Using repo_base: $repo_base${NC}"
    echo ""
    
    # Validate target repository if specified
    if [ -n "$target_repo" ] && [ "$target_repo" != "all" ]; then
        if ! validate_repo_name "$target_repo"; then
            return 1
        fi
    fi
    
    for pair in $repo_map; do
        IFS=':' read -r repo local_folder <<< "$pair"
        
        # Skip if specific repo requested and this isn't it
        if [ -n "$target_repo" ] && [ "$target_repo" != "all" ] && [ "$target_repo" != "$repo" ]; then
            continue
        fi
        
        if verify_single_repo "$repo" "$local_folder"; then
            existing_repos=$((existing_repos + 1))
        else
            missing_repos=$((missing_repos + 1))
            failed_repos+=("$repo")
        fi
        total_repos=$((total_repos + 1))
        
        show_progress $((existing_repos + missing_repos)) "$total_repos" "Verifying $repo"
    done

    echo -e "\n${CYAN}Summary:${NC}"
    echo -e "Total repositories checked: $total_repos"
    echo -e "${GREEN}Existing repositories: $existing_repos${NC}"
    echo -e "${RED}Missing repositories: $missing_repos${NC}"
    
    if [ ${#failed_repos[@]} -gt 0 ]; then
        echo -e "\n${RED}Missing repositories:${NC}"
        for repo in "${failed_repos[@]}"; do
            echo -e "  - ${YELLOW}$repo${NC}"
        done
    fi

    if [ $missing_repos -gt 0 ]; then
        echo -e "\n${YELLOW}Note: Use 'fetch' command to download missing repositories${NC}"
        return 1
    fi
    
    return 0
}

# Fetch a single repository
fetch_repo() {
    local repo="$1"
    local local_folder="$2"
    local repo_url="${ssh_base}${repo}.git"
    local local_repo_path="$repo_base/$local_folder"

    if [[ -z "$repo" ]] || [[ -z "$local_folder" ]]; then
        log "ERROR" "fetch_repo: repository name and local folder required"
        return 1
    fi

    echo -e "${CYAN}Processing repository: ${YELLOW}${repo}${NC}"
    echo -e "${CYAN}Local folder: ${YELLOW}${local_repo_path}${NC}"
    echo -e "${CYAN}Remote URL: ${YELLOW}${repo_url}${NC}"

    if [ -d "$local_repo_path/.git" ]; then
        echo -e "${YELLOW}Repository already exists. Fetching latest updates for: ${repo}${NC}"
        
        if ! cd "$local_repo_path"; then
            echo -e "${RED}Failed to enter directory: ${local_repo_path} for ${repo}${NC}"
            log "ERROR" "Failed to change directory to: $local_repo_path"
            return 1
        fi

        if ! execute_command "git fetch --all --prune"; then
            echo -e "${RED}Failed to fetch updates for repository: ${repo}${NC}"
            return 1
        fi

        echo -e "${GREEN}Successfully fetched updates for: ${repo}${NC}"
    else
        echo -e "${GREEN}Fetching metadata for new repository: ${YELLOW}${repo}${NC}"

        if ! execute_command "mkdir -p \"$local_repo_path\""; then
            echo -e "${RED}Failed to create directory: ${local_repo_path} for ${repo}${NC}"
            return 1
        fi

        if ! cd "$local_repo_path"; then
            echo -e "${RED}Failed to enter directory: ${local_repo_path} for ${repo}${NC}"
            log "ERROR" "Failed to change directory to: $local_repo_path"
            return 1
        fi

        echo -e "${GREEN}Entering directory: ${YELLOW}$(pwd)${NC} for ${YELLOW}${repo}${NC}"

        if ! execute_command "git init"; then
            echo -e "${RED}Failed to initialize bare repository at: ${local_repo_path} for ${repo_url}${NC}"
            return 1
        fi

        if ! execute_command "git remote add origin \"$repo_url\""; then
            echo -e "${RED}Failed to add remote for repository: ${repo_url} at ${local_repo_path}${NC}"
            return 1
        fi

        if ! execute_command "git fetch origin"; then
            echo -e "${RED}Failed to fetch metadata from repository: ${repo_url} into ${local_repo_path}${NC}"
            return 1
        fi

        echo -e "${GREEN}Successfully fetched metadata for new repository: ${repo}${NC}"
    fi

    echo -e "${CYAN}Completed processing repository: ${YELLOW}${repo}${NC}\n"
    return 0
}

# Enhanced repository fetching with better validation and error handling
fetch_repos() {
    local target_repo="$1"
    local success_count=0
    local fail_count=0
    local total_count=0
    
    if [ -z "$target_repo" ]; then
        echo -e "${RED}Error: Repository name required${NC}"
        echo "Usage: fetch <repo_name|all> [--profile <profile_name>]"
        return 1
    fi
    
    # Validate repository name
    if ! validate_repo_name "$target_repo"; then
        return 1
    fi
    
    log "INFO" "Starting repository fetch for: $target_repo"
    
    # Check SSH connectivity before proceeding
    if ! check_ssh_connectivity; then
        echo -e "${RED}Error: SSH connectivity check failed${NC}"
        return 1
    fi
    
    if [ "$target_repo" == "all" ]; then
        echo -e "${CYAN}Fetching all repositories...${NC}"
        
        # Count total repositories first
        for pair in $(sort_repo_map_by_depth); do
            total_count=$((total_count + 1))
        done
        
        local current=0
        for pair in $(sort_repo_map_by_depth); do
            IFS=':' read -r repo local_folder <<< "$pair"
            current=$((current + 1))
            show_progress "$current" "$total_count" "Fetching $repo"
            
            if fetch_repo "$repo" "$local_folder"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
                log "ERROR" "Failed to fetch repository: $repo"
            fi
        done
        
        echo -e "\n${CYAN}Fetch Summary:${NC}"
        echo -e "${GREEN}Success: $success_count${NC}"
        echo -e "${RED}Failed: $fail_count${NC}"
        
    else
        local repo_found=false
        for pair in $repo_map; do
            IFS=':' read -r repo local_folder <<< "$pair"
            if [ "$repo" == "$target_repo" ]; then
                repo_found=true
                if fetch_repo "$repo" "$local_folder"; then
                    success_count=$((success_count + 1))
                else
                    fail_count=$((fail_count + 1))
                fi
                break
            fi
        done
        
        if [ "$repo_found" = "false" ]; then
            echo -e "${RED}Repository '$target_repo' not found in configuration${NC}"
            log "ERROR" "Repository not found in repo_map: $target_repo"
            return 1
        fi
    fi
    
    log "INFO" "Repository fetch completed: $success_count success, $fail_count failed"
    return $fail_count
}

# List available repositories
show_repos() {
    echo -e "${CYAN}Available repositories:${NC}"
    for pair in $repo_map; do
        IFS=':' read -r repo local_folder <<< "$pair"
        echo -e "  ${GREEN}$repo${NC} -> $local_folder"
    done
}