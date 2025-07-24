#!/bin/bash

# repo/manager.sh - High-level repository management for git_sh1_modules
# Depends on: repo/discovery.sh, repo/operations.sh, and all core modules

# Initialize the repository management system
init_repository_system() {
    log "INFO" "Initializing repository management system"
    
    # Initialize repository paths and configuration
    if ! init_repo_paths; then
        log "ERROR" "Failed to initialize repository paths"
        return 1
    fi
    
    log "INFO" "Repository management system initialized successfully"
    log "INFO" "Git depot: $git_depot_dir"
    log "INFO" "Repo base: $repo_base"
    log "INFO" "Worktree base: $worktree_base_path"
    log "INFO" "Features directory: $features_dir"
    log "INFO" "Profiles directory: $profiles_dir"
    
    return 0
}

# High-level repository verification command
cmd_verify_repos() {
    local target_repo="$1"
    
    # Initialize repository system if not already done
    if [[ -z "$repo_base" ]]; then
        if ! init_repository_system; then
            return 1
        fi
    fi
    
    # Call the repository verification function
    verify_repos "$target_repo"
    return $?
}

# High-level repository fetch command
cmd_fetch_repos() {
    local target_repo="$1"
    local profile_name=""
    
    # Parse additional arguments for profile support
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                profile_name="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Usage: fetch <repo_name|all> [--profile <profile_name>]"
                return 1
                ;;
        esac
    done
    
    # Initialize repository system if not already done
    if [[ -z "$repo_base" ]]; then
        if ! init_repository_system; then
            return 1
        fi
    fi
    
    # Handle profile-based repository mapping if profile specified
    if [[ -n "$profile_name" ]]; then
        log "INFO" "Using profile: $profile_name"
        # TODO: Load profile-specific repo_map when profile module is implemented
        echo -e "${YELLOW}Profile support will be available after profile modules are implemented${NC}"
    fi
    
    # Call the repository fetch function
    fetch_repos "$target_repo"
    return $?
}

# List available repositories
cmd_show_repos() {
    # Initialize repository system if not already done
    if [[ -z "$repo_base" ]]; then
        if ! init_repository_system; then
            return 1
        fi
    fi
    
    show_repos
    return 0
}

# Get repository information
get_repo_info() {
    local repo_name="$1"
    
    if [[ -z "$repo_name" ]]; then
        log "ERROR" "get_repo_info: repository name required"
        return 1
    fi
    
    # Initialize repository system if not already done
    if [[ -z "$repo_base" ]]; then
        if ! init_repository_system; then
            return 1
        fi
    fi
    
    # Get repository path
    local repo_path
    if ! repo_path=$(get_repo_path "$repo_name"); then
        return 1
    fi
    
    echo "Repository: $repo_name"
    echo "Path: $repo_path"
    echo "SSH URL: ${ssh_base}${repo_name}.git"
    
    # Check if repository is valid
    if is_repo_valid "$repo_path"; then
        echo "Status: Valid git repository"
        
        # Get additional git information if available
        if cd "$repo_path" 2>/dev/null; then
            local current_branch
            current_branch=$(git branch --show-current 2>/dev/null)
            if [[ -n "$current_branch" ]]; then
                echo "Current branch: $current_branch"
            fi
            
            local remote_url
            remote_url=$(git remote get-url origin 2>/dev/null)
            if [[ -n "$remote_url" ]]; then
                echo "Remote URL: $remote_url"
            fi
        fi
    else
        echo "Status: Missing or invalid"
    fi
    
    return 0
}

# Check repository system health
check_repo_system_health() {
    local issues=0
    
    echo -e "${CYAN}Checking repository system health...${NC}\n"
    
    # Check if paths are initialized
    if [[ -z "$script_dir" ]]; then
        echo -e "${RED}✗ script_dir not initialized${NC}"
        ((issues++))
    else
        echo -e "${GREEN}✓ script_dir: $script_dir${NC}"
    fi
    
    if [[ -z "$git_depot_dir" ]]; then
        echo -e "${RED}✗ git_depot_dir not found${NC}"
        ((issues++))
    else
        echo -e "${GREEN}✓ git_depot_dir: $git_depot_dir${NC}"
    fi
    
    if [[ -z "$repo_base" ]]; then
        echo -e "${RED}✗ repo_base not found${NC}"
        ((issues++))
    else
        echo -e "${GREEN}✓ repo_base: $repo_base${NC}"
    fi
    
    # Check directory accessibility
    if [[ -n "$git_depot_dir" ]] && [[ ! -d "$git_depot_dir" ]]; then
        echo -e "${RED}✗ git_depot_dir directory not accessible${NC}"
        ((issues++))
    fi
    
    if [[ -n "$repo_base" ]] && [[ ! -d "$repo_base" ]]; then
        echo -e "${RED}✗ repo_base directory not accessible${NC}"
        ((issues++))
    fi
    
    # Check SSH connectivity
    echo -e "\n${CYAN}Checking SSH connectivity...${NC}"
    if check_ssh_connectivity; then
        echo -e "${GREEN}✓ SSH connectivity OK${NC}"
    else
        echo -e "${YELLOW}⚠ SSH connectivity check failed${NC}"
        ((issues++))
    fi
    
    # Check repository map
    echo -e "\n${CYAN}Checking repository configuration...${NC}"
    local repo_count=$(get_repo_count)
    echo -e "${GREEN}✓ Repository map loaded: $repo_count repositories${NC}"
    
    # Summary
    echo -e "\n${CYAN}Health Check Summary:${NC}"
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✓ Repository system is healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ Found $issues issues with repository system${NC}"
        return 1
    fi
}

# Validate repository configuration
validate_repo_config() {
    local errors=0
    
    echo -e "${CYAN}Validating repository configuration...${NC}\n"
    
    # Check for duplicate repository names
    local seen_repos=()
    local duplicates=()
    
    for pair in $repo_map; do
        IFS=':' read -r repo local_folder <<< "$pair"
        
        if [[ -n "$repo" ]]; then
            # Check for duplicates
            for seen in "${seen_repos[@]}"; do
                if [[ "$seen" == "$repo" ]]; then
                    duplicates+=("$repo")
                    break
                fi
            done
            seen_repos+=("$repo")
            
            # Validate repository name format
            if ! validate_repo_name_format "$repo"; then
                echo -e "${RED}✗ Invalid repository name format: $repo${NC}"
                ((errors++))
            fi
            
            # Check local folder path format
            if [[ -z "$local_folder" ]]; then
                echo -e "${RED}✗ Empty local folder for repository: $repo${NC}"
                ((errors++))
            fi
        fi
    done
    
    # Report duplicates
    if [[ ${#duplicates[@]} -gt 0 ]]; then
        echo -e "${RED}✗ Duplicate repository names found:${NC}"
        for dup in "${duplicates[@]}"; do
            echo -e "  - $dup"
        done
        ((errors++))
    fi
    
    # Summary
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✓ Repository configuration is valid${NC}"
        return 0
    else
        echo -e "${RED}✗ Found $errors configuration errors${NC}"
        return 1
    fi
}