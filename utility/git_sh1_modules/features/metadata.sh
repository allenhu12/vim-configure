#!/bin/bash

# features/metadata.sh - Feature metadata and advanced operations for git_sh1_modules
# Handles feature show, add, switch, pick, switchback, and JSON branch management

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

# Show details of a specific feature
feature_show() {
    local feature_name=""
    local worktree_override=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w)
                shift
                worktree_override="$1"
                shift
                ;;
            *)
                if [ -z "$feature_name" ]; then
                    feature_name="$1"
                    shift
                else
                    echo -e "${RED}Unknown argument: $1${NC}"
                    return 1
                fi
                ;;
        esac
    done
    
    if [ -z "$feature_name" ]; then
        echo -e "${RED}Usage: $0 feature show [-w <worktree>] <feature_name>${NC}"
        return 1
    fi
    
    local feature_dir="$features_dir/$feature_name"
    if [ ! -d "$feature_dir" ]; then
        echo -e "${RED}Feature '$feature_name' not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Feature: $feature_name${NC}"
    
    if [ -f "$feature_dir/comment.txt" ]; then
        echo -e "${CYAN}Comment:${NC} $(cat "$feature_dir/comment.txt")"
    fi
    
    # Check if feature uses a worktree
    local worktree=""
    if [ -n "$worktree_override" ]; then
        worktree="$worktree_override"
        echo -e "${CYAN}Using override worktree:${NC} $worktree"
    elif [ -f "$feature_dir/worktree.txt" ]; then
        worktree=$(cat "$feature_dir/worktree.txt")
        echo -e "${CYAN}Worktree:${NC} $worktree"
    elif [ -f "$feature_dir/detected_worktree.txt" ]; then
        worktree=$(cat "$feature_dir/detected_worktree.txt")
        echo -e "${CYAN}Detected Worktree:${NC} $worktree"
    fi
    
    if [ -f "$feature_dir/repos.txt" ]; then
        echo -e "\n${CYAN}Repository Status:${NC}"
        while IFS= read -r repo; do
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
                echo -e "  ${YELLOW}$repo${NC}: ${RED}Not found in repo_map${NC}"
                continue
            fi
            
            # Determine the repository path based on worktree
            local repo_path
            if [ -n "$worktree" ]; then
                repo_path="$worktree_base_path/$worktree/$local_folder"
            else
                repo_path="$repo_base/$local_folder"
            fi
            
            if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
                echo -e "  ${YELLOW}$repo${NC}: ${RED}Repository not found${NC}"
                continue
            fi
            
            cd "$repo_path"
            local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            local feature_branch="feature/$feature_name"
            
            echo -e "  ${YELLOW}$repo${NC}:"
            echo -e "    Current branch: ${CYAN}$current_branch${NC}"
            echo -e "    Repository path: ${CYAN}$repo_path${NC}"
            
            if git show-ref --verify --quiet "refs/heads/$feature_branch"; then
                # Check if the feature branch is checked out in any worktree
                local worktree_info=$(git worktree list --porcelain | grep -B 2 "branch refs/heads/$feature_branch" | grep "worktree" | cut -d' ' -f2)
                
                if [ "$current_branch" == "$feature_branch" ]; then
                    # Get the default remote branch
                    local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
                    if [ -n "$default_branch" ]; then
                        # Calculate commits ahead of the default branch
                        local commit_count=$(git rev-list --count HEAD ^origin/$default_branch 2>/dev/null || echo "0")
                        echo -e "    Feature branch: ${GREEN}$feature_branch (active)${NC} ($commit_count commits ahead)"
                    else
                        echo -e "    Feature branch: ${GREEN}$feature_branch (active)${NC}"
                    fi
                elif [ -n "$worktree_info" ]; then
                    echo -e "    Feature branch: ${GREEN}$feature_branch exists${NC}"
                    echo -e "    ${CYAN}Checked out in: $worktree_info${NC}"
                else
                    echo -e "    Feature branch: ${GREEN}$feature_branch exists${NC} (not checked out)"
                fi
            else
                echo -e "    Feature branch: ${RED}$feature_branch does not exist${NC}"
            fi
        done < "$feature_dir/repos.txt"
    fi
}

# Add a repository to an existing feature
feature_add() {
    local feature_name=""
    local repo_name=""
    local worktree=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w)
                shift
                worktree="$1"
                shift
                ;;
            *)
                if [ -z "$feature_name" ]; then
                    feature_name="$1"
                    shift
                elif [ -z "$repo_name" ]; then
                    repo_name="$1"
                    shift
                else
                    echo -e "${RED}Unknown argument: $1${NC}"
                    return 1
                fi
                ;;
        esac
    done
    
    # Input validation
    if [ -z "$feature_name" ] || [ -z "$repo_name" ]; then
        echo -e "${RED}Usage: $0 feature add [-w <worktree>] <feature_name> <repo_name>${NC}"
        echo -e "${YELLOW}  -w <worktree>: Optional. Specify which worktree to add the feature in${NC}"
        return 1
    fi
    
    # Sanitize inputs
    local original_feature_name="$feature_name"
    feature_name=$(sanitize_input "$feature_name")
    if [ "$feature_name" != "$original_feature_name" ]; then
        echo -e "${YELLOW}Feature name sanitized: $original_feature_name -> $feature_name${NC}"
    fi
    
    local original_repo_name="$repo_name"
    repo_name=$(sanitize_input "$repo_name")
    if [ "$repo_name" != "$original_repo_name" ]; then
        echo -e "${YELLOW}Repository name sanitized: $original_repo_name -> $repo_name${NC}"
    fi
    
    # Validate repository name
    if ! validate_repo_name "$repo_name"; then
        echo -e "${RED}Error: Invalid repository name: $repo_name${NC}"
        return 1
    fi
    
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
    
    # Check if feature exists
    if [ ! -d "$feature_dir" ]; then
        echo -e "${RED}Error: Feature '$feature_name' not found${NC}"
        echo -e "${YELLOW}Available features:${NC}"
        feature_list
        return 1
    fi
    
    # Check if feature already contains this repository
    if [ -f "$feature_dir/repos.txt" ] && grep -q "^$repo_name$" "$feature_dir/repos.txt"; then
        echo -e "${RED}Error: Repository '$repo_name' is already part of feature '$feature_name'${NC}"
        return 1
    fi
    
    log "INFO" "Adding repository $repo_name to feature: $feature_name"
    
    # Find the local folder for this repo
    local local_folder=""
    for pair in $repo_map; do
        IFS=':' read -r r f <<< "$pair"
        if [ "$r" == "$repo_name" ]; then
            local_folder="$f"
            break
        fi
    done
    
    if [ -z "$local_folder" ]; then
        echo -e "${RED}Repository $repo_name not found in repo_map${NC}"
        return 1
    fi
    
    # Use worktree from feature if not specified
    if [ -z "$worktree" ] && [ -f "$feature_dir/worktree.txt" ]; then
        worktree=$(cat "$feature_dir/worktree.txt")
        echo -e "${CYAN}Using feature's worktree: $worktree${NC}"
    fi
    
    # Determine the repository path based on worktree
    local repo_path
    if [ -n "$worktree" ]; then
        repo_path="$worktree_base_path/$worktree/$local_folder"
    else
        repo_path="$repo_base/$local_folder"
    fi
    
    if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
        echo -e "${RED}Repository not found: $repo_path${NC}"
        echo -e "${YELLOW}Make sure the repository is cloned and the worktree path is correct${NC}"
        return 1
    fi
    
    cd "$repo_path" || {
        echo -e "${RED}Failed to enter repository directory: $repo_path${NC}"
        return 1
    }
    
    # Validate git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}Invalid git repository: $repo_path${NC}"
        return 1
    fi
    
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local feature_branch="feature/$feature_name"
    
    echo -e "${CYAN}Processing repository: ${YELLOW}$repo_name${NC}"
    echo -e "${CYAN}Repository path: ${YELLOW}$repo_path${NC}"
    echo -e "${CYAN}Current branch: ${YELLOW}$current_branch${NC}"
    
    # Create or switch to feature branch
    if [ "$current_branch" == "$feature_branch" ]; then
        echo -e "${GREEN}Already on feature branch $feature_branch in $repo_name${NC}"
    elif git show-ref --verify --quiet "refs/heads/$feature_branch"; then
        echo -e "${YELLOW}Switching to existing feature branch $feature_branch in $repo_name${NC}"
        if ! git checkout "$feature_branch" 2>/dev/null; then
            # Check if it's due to branch being in use by another worktree
            local worktree_info=$(git worktree list --porcelain | grep -B 2 "branch refs/heads/$feature_branch" | grep "worktree" | cut -d' ' -f2)
            if [ -n "$worktree_info" ]; then
                echo -e "${CYAN}Feature branch $feature_branch is already checked out in worktree: $worktree_info${NC}"
                echo -e "${CYAN}Adding $repo_name to feature tracking without switching branches${NC}"
            else
                echo -e "${RED}Failed to checkout $feature_branch in $repo_name${NC}"
                return 1
            fi
        fi
    else
        echo -e "${GREEN}Creating new feature branch $feature_branch in $repo_name${NC}"
        if ! git checkout -b "$feature_branch"; then
            echo -e "${RED}Failed to create feature branch $feature_branch in $repo_name${NC}"
            return 1
        fi
    fi
    
    # Add repository to feature
    echo "$repo_name" >> "$feature_dir/repos.txt"
    
    # Update branches.json if it exists
    if [ -f "$feature_dir/branches.json" ]; then
        # For now, we'll regenerate the entire JSON - in a production system,
        # you might want to use jq to properly update the JSON
        echo -e "${YELLOW}Note: branches.json will need manual update for the new repository${NC}"
    fi
    
    echo -e "${GREEN}Successfully added repository '$repo_name' to feature '$feature_name'${NC}"
    log "INFO" "Repository $repo_name added to feature: $feature_name"
    return 0
}

# Switch to feature branches for all repos in a feature
feature_switch() {
    local feature_name=""
    local worktree_override=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w)
                shift
                worktree_override="$1"
                shift
                ;;
            *)
                if [ -z "$feature_name" ]; then
                    feature_name="$1"
                    shift
                else
                    echo -e "${RED}Unknown argument: $1${NC}"
                    return 1
                fi
                ;;
        esac
    done
    
    if [ -z "$feature_name" ]; then
        echo -e "${RED}Usage: $0 feature switch [-w <worktree>] <feature_name>${NC}"
        return 1
    fi
    
    local feature_dir="$features_dir/$feature_name"
    if [ ! -d "$feature_dir" ]; then
        echo -e "${RED}Feature '$feature_name' not found${NC}"
        return 1
    fi
    
    if [ ! -f "$feature_dir/repos.txt" ]; then
        echo -e "${RED}No repositories found for feature '$feature_name'${NC}"
        return 1
    fi
    
    # Check if feature uses a worktree
    local worktree=""
    if [ -n "$worktree_override" ]; then
        worktree="$worktree_override"
        echo -e "${CYAN}Using override worktree: $worktree${NC}"
    elif [ -f "$feature_dir/worktree.txt" ]; then
        worktree=$(cat "$feature_dir/worktree.txt")
        echo -e "${CYAN}Using worktree: $worktree${NC}"
    elif [ -f "$feature_dir/detected_worktree.txt" ]; then
        worktree=$(cat "$feature_dir/detected_worktree.txt")
        echo -e "${CYAN}Using detected worktree: $worktree${NC}"
    fi
    
    echo -e "${CYAN}Switching to feature branches for '$feature_name'...${NC}"
    
    while IFS= read -r repo; do
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
        local repo_path
        if [ -n "$worktree" ]; then
            repo_path="$worktree_base_path/$worktree/$local_folder"
        else
            repo_path="$repo_base/$local_folder"
        fi
        
        if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
            echo -e "${RED}Repository not found: $repo_path${NC}"
            continue
        fi
        
        cd "$repo_path"
        local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        local feature_branch="feature/$feature_name"
        
        # Check if we're already on the feature branch
        if [ "$current_branch" == "$feature_branch" ]; then
            echo -e "${GREEN}Already on feature branch $feature_branch in $repo${NC}"
        elif git show-ref --verify --quiet "refs/heads/$feature_branch"; then
            echo -e "${GREEN}Switching $repo to $feature_branch${NC}"
            if ! git checkout "$feature_branch" 2>/dev/null; then
                # If checkout fails, check if it's due to branch being in use by another worktree
                local worktree_info=$(git worktree list --porcelain | grep -B 2 "branch refs/heads/$feature_branch" | grep "worktree" | cut -d' ' -f2)
                if [ -n "$worktree_info" ]; then
                    echo -e "${CYAN}Feature branch $feature_branch is already checked out in worktree: $worktree_info${NC}"
                    echo -e "${YELLOW}Cannot switch to this branch in the current worktree${NC}"
                else
                    echo -e "${RED}Failed to checkout $feature_branch in $repo${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}Feature branch $feature_branch does not exist in $repo${NC}"
        fi
    done < "$feature_dir/repos.txt"
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    # Add more dependency checks here if needed
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - ${YELLOW}$dep${NC}"
        done
        echo -e "\nPlease install the missing dependencies:"
        echo -e "  ${CYAN}sudo apt-get install ${missing_deps[*]}${NC}"
        return 1
    fi
    
    return 0
}

echo "Feature metadata and advanced operations module loaded"