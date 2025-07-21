#!/bin/bash

# Usage:
# Step 1: Fetch repository metadata
#   ./git_sh1.sh fetch <repo_name>
#   Example: ./git_sh1.sh fetch all
#   Example: ./git_sh1.sh fetch controller

# Step 2: Add worktree
#   ./git_sh1.sh worktree add <repo_name> -lb <local_branch_name> -rb <remote_branch_name>
#   Example: ./git_sh1.sh worktree add all -lb local5 -rb origin/master
#   Example: ./git_sh1.sh worktree add ap_zd_controller -lb local5 -rb origin/master
#   Example: ./git_sh1.sh worktree add ap_zd_controller -lb local5 -rb origin/release/unleashed_200.17

# Step 3: Pull and rebase worktree
#   ./git_sh1.sh worktree pull-rebase <repo_name> <local_branch_name>
#   Example: ./git_sh1.sh worktree pull-rebase controller local5
#   Example: ./git_sh1.sh worktree pull-rebase all local5
#   Note : the parameter <local_branch_name> is only the designation of local path, not the branch name of local repository.

# Repository map (repository name:local folder):
repo_map="
    opensource:opensource
    rks_ap:rks_ap
    dl:dl
    linux_3_14:opensource/linux/kernels/linux-3.14.43
    linux_4_4:opensource/linux/kernels/linux-4.4.60
    linux_5_4:opensource/linux/kernels/linux-5.4
    linux_5_4_mtk:linux_5_4_mtk
    controller:rks_ap/controller
    ap_zd_controller:rks_ap/controller/common
    ruckus-spark:ruckus-spark
    ap_scg_common:rks_ap/ap_scg_common
    ap_scg_rcli:rks_ap/controller/rcli
    vendor_qca_11ac:rks_ap/platform_dp/linux/driver/vendor_qca_11ac
    vendor_qca_11ax:rks_ap/platform_dp/linux/driver/vendor_qca_11ax
    vendor_qca_11ax6e:rks_ap/platform_dp/linux/driver/vendor_qca_11ax6e
    vendor_qca_11be:rks_ap/platform_dp/linux/driver/vendor_qca_11be
    vendor_qca_ref:rks_ap/platform_dp/linux/driver/vendor_qca_ref
    vendor_qca_tools:vendor_qca_tools
    vendor_mtk_11be:vendor_mtk_11be
    rpoint_handler:rpoint_handler
    rtty:rtty
    rksiot:rksiot
    rksiot_hpkg:rksiot_hpkg
"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global configuration
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}
LOG_FILE=""
LOCK_FILE="/tmp/git_sh1_$$.lock"
TEMP_DIR=""

# Initialize logging
init_logging() {
    LOG_FILE="${script_dir}/git_sh1_$(date '+%Y%m%d_%H%M%S').log"
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${CYAN}Logging to: $LOG_FILE${NC}"
    fi
}

# Logging function
log() {
    local level=$1; shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    if [ "$VERBOSE" = "true" ] || [ "$level" = "ERROR" ]; then
        echo -e "${CYAN}[$level]${NC} $message"
    fi
}

# Cleanup function
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log "INFO" "Cleaned up temporary directory: $TEMP_DIR"
    fi
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log "INFO" "Removed lock file: $LOCK_FILE"
    fi
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Process locking
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            echo -e "${RED}Error: Another instance is running (PID: $lock_pid)${NC}"
            return 1
        else
            log "INFO" "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
    log "INFO" "Acquired lock with PID: $$"
    return 0
}

# Input sanitization
sanitize_input() {
    local input="$1"
    # Remove dangerous characters, keep alphanumeric, dots, dashes, underscores, slashes
    echo "$input" | sed 's/[^a-zA-Z0-9._/-]//g'
}

# Path validation
validate_path() {
    local path="$1"
    local base_path="$2"
    
    # Convert to absolute path
    if [[ "$path" != /* ]]; then
        path="$base_path/$path"
    fi
    
    # Normalize path (remove .. and .)
    path=$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path") || {
        log "ERROR" "Invalid path: $1"
        return 1
    }
    
    # Check if path is within allowed boundaries
    if [[ "$path" != "$base_path"* ]]; then
        log "ERROR" "Path outside allowed boundaries: $path"
        return 1
    fi
    
    echo "$path"
    return 0
}

# Enhanced execute command with dry-run support
execute_command() {
    local cmd="$*"
    log "INFO" "Executing: $cmd"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}[DRY-RUN] Would execute: $cmd${NC}"
        return 0
    else
        eval "$cmd"
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then
            log "ERROR" "Command failed with exit code $exit_code: $cmd"
        fi
        return $exit_code
    fi
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local operation="$3"
    local percent=$((current * 100 / total))
    printf "\r${CYAN}[%d/%d] (%d%%) %s...${NC}" "$current" "$total" "$percent" "$operation"
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Determine the script's directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize logging and acquire lock
init_logging
log "INFO" "Starting git_sh1.sh from directory: $script_dir"

if ! acquire_lock; then
    exit 1
fi

# Improved path resolution with better error handling
find_git_depot() {
    local search_path="$1"
    local max_depth=10
    local current_depth=0
    
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

# Find git-depot directory
if ! git_depot_dir=$(find_git_depot "$script_dir"); then
    echo -e "${RED}Error: Could not find the git-depot directory${NC}"
    echo -e "${YELLOW}Please ensure this script is run from within a git-depot directory structure${NC}"
    exit 1
fi

log "INFO" "Found git-depot directory: $git_depot_dir"

# Find repo_base directory with better error handling
find_repo_base() {
    local git_depot="$1"
    local repo_base_candidates=()
    
    # Look for directories containing "repo_base" in their name
    while IFS= read -r -d '' dir; do
        repo_base_candidates+=("$dir")
    done < <(find "$git_depot" -maxdepth 2 -type d -name "*repo_base*" -print0 2>/dev/null)
    
    if [ ${#repo_base_candidates[@]} -eq 0 ]; then
        log "ERROR" "No directories containing 'repo_base' found in $git_depot"
        return 1
    elif [ ${#repo_base_candidates[@]} -eq 1 ]; then
        echo "${repo_base_candidates[0]}"
        return 0
    else
        log "WARN" "Multiple repo_base candidates found, using first: ${repo_base_candidates[0]}"
        echo "${repo_base_candidates[0]}"
        return 0
    fi
}

# Find repo_base directory
if ! repo_base=$(find_repo_base "$git_depot_dir"); then
    echo -e "${RED}Error: Could not find a directory containing 'repo_base' in its name${NC}"
    echo -e "${YELLOW}Expected to find a directory like 'my_repo_base' or 'repo_base_main' in $git_depot_dir${NC}"
    exit 1
fi

log "INFO" "Using repo_base directory: $repo_base"

# Set worktree base path to git-depot directory
worktree_base_path="$git_depot_dir"
log "INFO" "Using worktree_base_path: $worktree_base_path"

ssh_base="ssh://tdc-mirror-git@ruckus-git.ruckuswireless.com:7999/wrls/"

# Repository validation
validate_repo_name() {
    local repo_name="$1"
    local repo_name_clean=$(sanitize_input "$repo_name")
    
    if [ "$repo_name" != "$repo_name_clean" ]; then
        log "ERROR" "Invalid repository name: $repo_name"
        return 1
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
            ((existing_repos++))
        else
            ((missing_repos++))
            failed_repos+=("$repo")
        fi
        ((total_repos++))
        
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
        echo -e "\n${YELLOW}Note: To fetch missing repositories, use:${NC}"
        echo -e "${CYAN}./git_sh1.sh fetch all${NC}"
    fi
    
    log "INFO" "Repository verification completed: $existing_repos existing, $missing_repos missing"
    return $missing_repos
}

verify_single_repo() {
    local repo="$1"
    local local_folder="$2"
    local repo_path
    
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

# Enhanced repository fetching with better validation and error handling
fetch_repos() {
    local target_repo="$1"
    local success_count=0
    local fail_count=0
    local total_count=0
    
    if [ -z "$target_repo" ]; then
        echo -e "${RED}Error: Repository name required${NC}"
        echo "Usage: $0 fetch <repo_name|all>"
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
        for pair in $repo_map; do
            ((total_count++))
        done
        
        local current=0
        for pair in $repo_map; do
            IFS=':' read -r repo local_folder <<< "$pair"
            ((current++))
            show_progress "$current" "$total_count" "Fetching $repo"
            
            if fetch_repo "$repo" "$local_folder"; then
                ((success_count++))
            else
                ((fail_count++))
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
                    ((success_count++))
                else
                    ((fail_count++))
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
    fi
    
    return 0
}

fetch_repo() {
    repo=$1
    local_folder=$2
    repo_url="${ssh_base}${repo}.git"
    local_repo_path="$repo_base/$local_folder"

    echo -e "${CYAN}Processing repository: ${YELLOW}${repo}${NC}"
    echo -e "${CYAN}Local folder: ${YELLOW}${local_repo_path}${NC}"
    echo -e "${CYAN}Remote URL: ${YELLOW}${repo_url}${NC}"

    if [ -d "$local_repo_path/.git" ]; then
        echo -e "${YELLOW}Repository already exists. Fetching latest updates for: ${repo}${NC}"
        cd "$local_repo_path" || {
            echo -e "${RED}Failed to enter directory: ${local_repo_path} for ${repo}${NC}"
            return
        }

        git fetch --all --prune || {
            echo -e "${RED}Failed to fetch updates for repository: ${repo}${NC}"
            return
        }

        echo -e "${GREEN}Successfully fetched updates for: ${repo}${NC}"
    else
        echo -e "${GREEN}Fetching metadata for new repository: ${YELLOW}${repo}${NC}"

        mkdir -p "$local_repo_path" || {
            echo -e "${RED}Failed to create directory: ${local_repo_path} for ${repo}${NC}"
            return
        }

        cd "$local_repo_path" || {
            echo -e "${RED}Failed to enter directory: ${local_repo_path} for ${repo}${NC}"
            return
        }

        echo -e "${GREEN}Entering directory: ${YELLOW}$(pwd)${NC} for ${YELLOW}${repo}${NC}"

        git init || {
            echo -e "${RED}Failed to initialize bare repository at: ${local_repo_path} for ${repo_url}${NC}"
            return
        }

        git remote add origin "$repo_url" || {
            echo -e "${RED}Failed to add remote for repository: ${repo_url} at ${local_repo_path}${NC}"
            return
        }

        git fetch origin || {
            echo -e "${RED}Failed to fetch metadata from repository: ${repo_url} into ${local_repo_path}${NC}"
            return
        }

        echo -e "${GREEN}Successfully fetched metadata for new repository: ${repo}${NC}"
    fi

    echo -e "${CYAN}Completed processing repository: ${YELLOW}${repo}${NC}\n"
}

# Add a worktree for a specific branch
add_worktree() {
    repo=$1
    local_branch=$2
    remote_branch=$3

    if [ "$repo" == "all" ]; then
        for pair in $repo_map; do
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
    
    if ! worktree_dir=$(validate_path "$worktree_base_path/$local_branch/$local_folder" "$worktree_base_path"); then
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
        if ! git worktree add -f "$worktree_dir" "$local_branch" 2>/dev/null; then
            echo -e "${RED}Failed to add worktree for existing branch $local_branch${NC}"
            log "ERROR" "Failed to add worktree for existing branch $local_branch in $repo"
            return 1
        fi
    else
        echo -e "${GREEN}Creating new branch $local_branch from $remote_branch.${NC}"
        log "INFO" "Creating new branch $local_branch from $remote_branch for $repo"
        
        # If the branch doesn't exist, create it and add it as a worktree
        if ! git worktree add --checkout -b "$local_branch" "$worktree_dir" "$remote_branch" 2>/dev/null; then
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
    return 0
}

# Pull and rebase each repository in the worktree
pull_rebase_worktree() {
    repo=$1
    local_branch=$2

    if [ "$repo" == "all" ]; then
        for pair in $repo_map; do
            IFS=':' read -r repo_name local_folder <<< "$pair"
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
    echo -e "${CYAN}Completed pull-rebase for $repo in $local_branch (current branch: $current_branch)${NC}"
}

# Function to show all repository names
show_repos() {
    echo -e "${CYAN}Available repositories:${NC}"
    for pair in $repo_map; do
        IFS=':' read -r repo local_folder <<< "$pair"
        echo -e "${YELLOW}$repo${NC}"
    done
}

# ------------------------------------------------------------------
# FEATURE BRANCH MANAGEMENT FUNCTIONS
# ------------------------------------------------------------------

# Feature metadata directory
features_dir="$script_dir/.git_sh1_features"

# Profile management directory
profiles_dir="$git_depot_dir/.git_sh1_profiles"

# Configuration validation
validate_configuration() {
    log "INFO" "Validating configuration"
    
    # Check required tools
    local missing_tools=()
    for tool in git jq; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required tools:${NC}"
        for tool in "${missing_tools[@]}"; do
            echo -e "  - ${YELLOW}$tool${NC}"
        done
        echo -e "\nPlease install missing tools and try again."
        return 1
    fi
    
    # Validate repo_map format
    local repo_count=0
    for pair in $repo_map; do
        if [[ ! "$pair" =~ ^[^:]+:[^:]+$ ]]; then
            echo -e "${RED}Error: Invalid repo_map entry format: $pair${NC}"
            log "ERROR" "Invalid repo_map entry: $pair"
            return 1
        fi
        ((repo_count++))
    done
    
    if [ $repo_count -eq 0 ]; then
        echo -e "${RED}Error: No repositories configured in repo_map${NC}"
        return 1
    fi
    
    log "INFO" "Configuration validation completed: $repo_count repositories configured"
    return 0
}

# Initialize features directory if it doesn't exist
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
    if [[ ! "$feature_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid feature name. Use only letters, numbers, underscores, and hyphens.${NC}"
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
    
    # Add repository to repos.txt
    echo "$repo_name" >> "$feature_dir/repos.txt"
    echo -e "${GREEN}Added $repo_name to feature repositories list${NC}"
    
    # Update worktree.txt if worktree specified and doesn't exist
    if [ -n "$worktree" ] && [ ! -f "$feature_dir/worktree.txt" ]; then
        echo "$worktree" > "$feature_dir/worktree.txt"
        echo -e "${GREEN}Set feature worktree to: $worktree${NC}"
    fi
    
    # Update branches.json
    if [ -f "$feature_dir/branches.json" ]; then
        # Check dependencies first
        if ! check_dependencies; then
            echo -e "${YELLOW}Warning: Cannot update branches.json - jq not available${NC}"
        else
            # Read current branches.json and add new repository
            local branches_json
            if branches_json=$(cat "$feature_dir/branches.json"); then
                # Add the new repository to the JSON
                local updated_json
                if updated_json=$(echo "$branches_json" | jq --arg repo "$repo_name" \
                                                              --arg branch "$current_branch" \
                                                              --arg path "$repo_path" \
                                                              '.[$repo] = {"branch": $branch, "path": $path}'); then
                    echo "$updated_json" > "$feature_dir/branches.json"
                    echo -e "${GREEN}Updated branches.json with $repo_name${NC}"
                else
                    echo -e "${YELLOW}Warning: Failed to update branches.json${NC}"
                fi
            fi
        fi
    else
        # Create new branches.json if it doesn't exist
        if check_dependencies; then
            local branches_json="{\"$repo_name\":{\"branch\":\"$current_branch\",\"path\":\"$repo_path\"}}"
            echo "$branches_json" > "$feature_dir/branches.json"
            echo -e "${GREEN}Created branches.json with $repo_name${NC}"
        fi
    fi
    
    echo -e "${GREEN}Successfully added repository '$repo_name' to feature '$feature_name'${NC}"
    log "INFO" "Successfully added repository $repo_name to feature $feature_name"
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

# Repair malformed branches.json file
repair_branches_json() {
    local feature_dir="$1"
    local branches_file="$feature_dir/branches.json"
    local feature_name=$(basename "$feature_dir")
    
    echo -e "${YELLOW}Attempting to repair malformed branches.json...${NC}"
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Start with an empty JSON object
    echo "{}" > "$temp_file"
    
    # Determine the worktree to use
    local worktree=""
    if [ -f "$feature_dir/worktree.txt" ]; then
        worktree=$(cat "$feature_dir/worktree.txt")
    elif [ -f "$feature_dir/detected_worktree.txt" ]; then
        worktree=$(cat "$feature_dir/detected_worktree.txt")
    fi
    
    # Read repos.txt and add each repo with its original branch
    if [ -f "$feature_dir/repos.txt" ]; then
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
            
            if [ -n "$local_folder" ]; then
                # Determine the repository path
                local repo_path
                if [ -n "$worktree" ]; then
                    repo_path="$worktree_base_path/$worktree/$local_folder"
                else
                    repo_path="$repo_base/$local_folder"
                fi
                
                # Get the original branch from git reflog or default branches
                if [ -d "$repo_path/.git" ] || [ -f "$repo_path/.git" ]; then
                    cd "$repo_path"
                    
                    # Try multiple methods to find the original branch
                    local original_branch=""
                    
                    # Method 1: Check reflog for checkout operations before feature branch
                    original_branch=$(git reflog | grep "checkout: moving from" | grep -v "feature/$feature_name" | head -n 1 | awk '{print $NF}')
                    
                    # Method 2: If no reflog entry, try to find the default branch
                    if [ -z "$original_branch" ]; then
                        original_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
                    fi
                    
                    # Method 3: If still no branch, use common defaults based on repository
                    if [ -z "$original_branch" ]; then
                        case "$repo" in
                            controller)
                                if [ -n "$worktree" ]; then
                                    original_branch="$worktree"
                                else
                                    original_branch="master"
                                fi
                                ;;
                            opensource)
                                original_branch="master"
                                ;;
                            *)
                                original_branch="master"
                                ;;
                        esac
                    fi
                    
                    if [ -n "$original_branch" ]; then
                        # Verify the branch exists
                        if git show-ref --verify --quiet "refs/heads/$original_branch" || \
                           git show-ref --verify --quiet "refs/remotes/origin/$original_branch"; then
                            # Add to JSON
                            jq --arg repo "$repo" \
                               --arg branch "$original_branch" \
                               --arg path "$repo_path" \
                               '.[$repo] = {"branch": $branch, "path": $path}' "$temp_file" > "${temp_file}.new" && \
                            mv "${temp_file}.new" "$temp_file"
                            echo -e "${CYAN}Added $repo: $original_branch at $repo_path${NC}"
                        else
                            echo -e "${YELLOW}Warning: Branch $original_branch not found for $repo, skipping${NC}"
                        fi
                    else
                        echo -e "${YELLOW}Warning: Could not determine original branch for $repo${NC}"
                    fi
                else
                    echo -e "${YELLOW}Warning: Repository $repo_path not found${NC}"
                fi
            else
                echo -e "${YELLOW}Warning: Local folder not found for repo $repo${NC}"
            fi
        done < "$feature_dir/repos.txt"
    else
        echo -e "${RED}Error: repos.txt not found in feature directory${NC}"
        rm -f "$temp_file"
        return 1
    fi
    
    # Check if we have any repositories in the repaired file
    local repo_count=$(jq 'keys | length' "$temp_file")
    if [ "$repo_count" -eq 0 ]; then
        echo -e "${RED}Error: No repositories could be added to branches.json${NC}"
        rm -f "$temp_file"
        return 1
    fi
    
    # Replace the original file
    mv "$temp_file" "$branches_file"
    echo -e "${GREEN}Repaired branches.json file with $repo_count repositories${NC}"
}

# Switch back to original branches
feature_switchback() {
    local feature_name="$1"
    local feature_dir="$features_dir/$feature_name"
    
    # Check dependencies first
    if ! check_dependencies; then
        return 1
    fi
    
    if [ ! -d "$feature_dir" ]; then
        echo -e "${RED}Feature '$feature_name' not found${NC}"
        return 1
    fi
    
    # Check for detected worktree
    local detected_worktree=""
    if [ -f "$feature_dir/detected_worktree.txt" ]; then
        detected_worktree=$(cat "$feature_dir/detected_worktree.txt")
        echo -e "${CYAN}Using detected worktree: $detected_worktree${NC}"
    fi
    
    echo -e "${YELLOW}Switching back to original branches...${NC}"
    
    # Read the branches.json file
    if [ ! -f "$feature_dir/branches.json" ]; then
        echo -e "${RED}Error: branches.json not found in feature directory${NC}"
        return 1
    fi
    
    # Function to validate JSON structure
    validate_branches_json() {
        local json_file="$1"
        
        # Check if it's valid JSON
        if ! jq empty "$json_file" 2>/dev/null; then
            return 1
        fi
        
        # Check if it has any keys
        local repo_count=$(jq 'keys | length' "$json_file" 2>/dev/null)
        if [ "$repo_count" -eq 0 ]; then
            return 1
        fi
        
        # Check each repository entry
        local repos=$(jq -r 'keys[]' "$json_file" 2>/dev/null)
        for repo in $repos; do
            local entry=$(jq -r ".[\"$repo\"]" "$json_file" 2>/dev/null)
            # Check if entry is an object with both branch and path
            if ! echo "$entry" | jq -e 'type == "object" and has("branch") and has("path")' >/dev/null 2>&1; then
                return 1
            fi
        done
        
        return 0
    }
    
    # Validate the JSON file and repair if needed
    if ! validate_branches_json "$feature_dir/branches.json"; then
        echo -e "${YELLOW}branches.json needs repair${NC}"
        if ! repair_branches_json "$feature_dir"; then
            echo -e "${RED}Failed to repair branches.json${NC}"
            return 1
        fi
        
        # Validate again after repair
        if ! validate_branches_json "$feature_dir/branches.json"; then
            echo -e "${RED}branches.json is still invalid after repair${NC}"
            return 1
        fi
    fi
    
    local branches_json
    if ! branches_json=$(cat "$feature_dir/branches.json"); then
        echo -e "${RED}Error: Failed to read branches.json${NC}"
        return 1
    fi
    
    # Process each repository
    local switch_success=true
    
    # Use a different approach to handle the loop and success tracking
    local repo_list=$(echo "$branches_json" | jq -r 'keys[]' 2>/dev/null)
    if [ -z "$repo_list" ]; then
        echo -e "${RED}Error: No repositories found in branches.json${NC}"
        return 1
    fi
    
    for repo in $repo_list; do
        local branch_info
        if ! branch_info=$(echo "$branches_json" | jq -r ".[\"$repo\"]" 2>/dev/null); then
            echo -e "${RED}Error: Failed to parse branch info for $repo${NC}"
            switch_success=false
            continue
        fi
        
        local original_branch
        local repo_path
        if ! original_branch=$(echo "$branch_info" | jq -r '.branch' 2>/dev/null) || \
           ! repo_path=$(echo "$branch_info" | jq -r '.path' 2>/dev/null) || \
           [ "$original_branch" = "null" ] || [ "$repo_path" = "null" ]; then
            echo -e "${RED}Error: Failed to get branch or path info for $repo${NC}"
            switch_success=false
            continue
        fi
        
        echo -e "${CYAN}Processing $repo: switching to $original_branch${NC}"
        
        if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
            echo -e "${RED}Repository not found: $repo_path${NC}"
            switch_success=false
            continue
        fi
        
        cd "$repo_path" || {
            echo -e "${RED}Error: Failed to change to directory $repo_path${NC}"
            switch_success=false
            continue
        }
        
        local current_branch
        if ! current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
            echo -e "${RED}Error: Failed to get current branch in $repo${NC}"
            switch_success=false
            continue
        fi
        
        local feature_branch="feature/$feature_name"
        
        # Check for uncommitted changes
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo -e "${YELLOW}Found uncommitted changes in $repo. Creating temporary stash...${NC}"
            local stash_name="feature_${feature_name}_$(date +%Y%m%d_%H%M%S)"
            if ! git stash push -m "$stash_name"; then
                echo -e "${RED}Failed to stash changes in $repo. Aborting switchback.${NC}"
                echo -e "${YELLOW}Please commit or stash your changes manually and try again.${NC}"
                switch_success=false
                continue
            fi
            echo -e "${GREEN}Changes stashed as: $stash_name${NC}"
            echo -e "${YELLOW}To recover these changes later, use: git stash list | grep '$stash_name'${NC}"
        fi
        
        # Check if we're on the feature branch
        if [ "$current_branch" == "$feature_branch" ]; then
            echo -e "${YELLOW}Switching $repo back to $original_branch in $repo_path${NC}"
            if ! git checkout "$original_branch"; then
                echo -e "${RED}Failed to switch to $original_branch in $repo${NC}"
                switch_success=false
                continue
            fi
            echo -e "${GREEN}Successfully switched $repo to $original_branch${NC}"
        else
            # Check if the feature branch exists
            if git show-ref --verify --quiet "refs/heads/$feature_branch"; then
                local worktree_info
                if ! worktree_info=$(git worktree list --porcelain 2>/dev/null | grep -B 2 "branch refs/heads/$feature_branch" | grep "worktree" | cut -d' ' -f2); then
                    echo -e "${CYAN}Feature branch $feature_branch exists but is not checked out in any worktree${NC}"
                else
                    if [ -n "$worktree_info" ]; then
                        echo -e "${CYAN}Feature branch $feature_branch is checked out in: $worktree_info${NC}"
                        if [ "$worktree_info" = "$repo_path" ]; then
                            echo -e "${YELLOW}Switching $repo back to $original_branch in $repo_path${NC}"
                            if ! git checkout "$original_branch"; then
                                echo -e "${RED}Failed to switch to $original_branch in $repo${NC}"
                                switch_success=false
                                continue
                            fi
                            echo -e "${GREEN}Successfully switched $repo to $original_branch${NC}"
                        fi
                    fi
                fi
            else
                echo -e "${CYAN}Feature branch $feature_branch does not exist in $repo (already on $current_branch)${NC}"
            fi
        fi
    done
    
    if [ "$switch_success" = true ]; then
        echo -e "${GREEN}Successfully switched back to original branches for feature '$feature_name'${NC}"
        echo -e "${YELLOW}Note: If you had any uncommitted changes, they were stashed.${NC}"
        echo -e "${YELLOW}Use 'git stash list' to see your stashed changes.${NC}"
    else
        echo -e "${RED}Some repositories failed to switch back. Please check the errors above.${NC}"
        return 1
    fi
}

# Cherry-pick feature commits to target branch
feature_pick() {
    local feature_name=""
    local target_branch=""
    local worktree_override=""
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w)
                shift
                worktree_override="$1"
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                if [ -z "$feature_name" ]; then
                    feature_name="$1"
                    shift
                elif [ -z "$target_branch" ]; then
                    target_branch="$1"
                    shift
                else
                    echo -e "${RED}Unknown argument: $1${NC}"
                    return 1
                fi
                ;;
        esac
    done
    
    if [ -z "$feature_name" ] || [ -z "$target_branch" ]; then
        echo -e "${RED}Usage: $0 feature pick [-w <worktree>] [--dry-run] <feature_name> <target_branch>${NC}"
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
    
    if [ "$dry_run" = true ]; then
        echo -e "${CYAN}DRY RUN: Would cherry-pick feature commits to $target_branch...${NC}"
    else
        echo -e "${CYAN}Cherry-picking feature commits to $target_branch...${NC}"
    fi
    
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
        local feature_branch="feature/$feature_name"
        
        if ! git show-ref --verify --quiet "refs/heads/$feature_branch"; then
            echo -e "${YELLOW}Feature branch $feature_branch does not exist in $repo, skipping${NC}"
            continue
        fi
        
        echo -e "${GREEN}Processing $repo...${NC}"
        
        # Store current branch for dry run
        local current_branch=""
        if [ "$dry_run" = true ]; then
            current_branch=$(git symbolic-ref --short HEAD)
            echo -e "${CYAN}Current branch: $current_branch${NC}"
        else
            # Checkout target branch
            if ! git checkout "$target_branch"; then
                echo -e "${RED}Failed to checkout $target_branch in $repo${NC}"
                continue
            fi
        fi
        
        # Find commits that are only on the feature branch
        local merge_base=$(git merge-base "$target_branch" "$feature_branch")
        local commits=$(git rev-list --reverse "$merge_base".."$feature_branch")
        
        if [ -z "$commits" ]; then
            echo -e "${YELLOW}No commits to cherry-pick from $feature_branch in $repo${NC}"
            continue
        fi
        
        if [ "$dry_run" = true ]; then
            echo -e "${CYAN}Would cherry-pick the following commits in $repo:${NC}"
            for commit in $commits; do
                echo -e "  $(git log --oneline -1 $commit)"
            done
            echo -e "${CYAN}Would switch to branch: $target_branch${NC}"
        else
            echo -e "${CYAN}Cherry-picking commits...${NC}"
            for commit in $commits; do
                echo -e "  Picking: $(git log --oneline -1 $commit)"
                if ! git cherry-pick "$commit"; then
                    echo -e "${RED}Cherry-pick failed for commit $commit${NC}"
                    echo -e "${YELLOW}Resolve conflicts manually and run 'git cherry-pick --continue'${NC}"
                    return 1
                fi
            done
            
            echo -e "${GREEN}Successfully cherry-picked feature commits to $target_branch in $repo${NC}"
        fi
    done < "$feature_dir/repos.txt"
    
    if [ "$dry_run" = true ]; then
        echo -e "${GREEN}Dry run completed. No changes were made.${NC}"
    fi
}

# ------------------------------------------------------------------
# PROFILE MANAGEMENT FUNCTIONS
# ------------------------------------------------------------------

# Initialize profiles directory
init_profiles_dir() {
    if [ ! -d "$profiles_dir" ]; then
        if ! mkdir -p "$profiles_dir"; then
            echo -e "${RED}Error: Failed to create profiles directory: $profiles_dir${NC}"
            log "ERROR" "Failed to create profiles directory: $profiles_dir"
            return 1
        fi
        echo -e "${GREEN}Initialized profiles directory at: $profiles_dir${NC}"
        log "INFO" "Initialized profiles directory: $profiles_dir"
    fi
    return 0
}

# Parse manifest.xml and generate repo_map.txt
parse_manifest_xml() {
    local manifest_file="$1"
    local output_file="$2"
    
    if [ ! -f "$manifest_file" ]; then
        echo -e "${RED}Error: Manifest file not found: $manifest_file${NC}"
        return 1
    fi
    
    log "INFO" "Parsing manifest file: $manifest_file"
    
    # Use xmllint if available, otherwise fall back to grep/sed
    if command -v xmllint >/dev/null 2>&1; then
        # Extract project elements using xmllint
        xmllint --format "$manifest_file" | grep '<project ' | while IFS= read -r line; do
            # Extract name and path attributes
            local name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
            local path=$(echo "$line" | sed -n 's/.*path="\([^"]*\)".*/\1/p')
            
            # If path is empty, use name as path (e.g., opensource:opensource)
            if [ -n "$name" ]; then
                if [ -z "$path" ]; then
                    path="$name"
                fi
                echo "$name:$path"
            fi
        done > "$output_file"
    else
        # Fallback to grep/sed for systems without xmllint
        grep '<project ' "$manifest_file" | while IFS= read -r line; do
            # Extract name and path attributes using sed
            local name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
            local path=$(echo "$line" | sed -n 's/.*path="\([^"]*\)".*/\1/p')
            
            # If path is empty, use name as path (e.g., opensource:opensource)
            if [ -n "$name" ]; then
                if [ -z "$path" ]; then
                    path="$name"
                fi
                echo "$name:$path"
            fi
        done > "$output_file"
    fi
    
    if [ ! -s "$output_file" ]; then
        echo -e "${RED}Error: Failed to parse manifest or no projects found${NC}"
        log "ERROR" "Failed to parse manifest: $manifest_file"
        return 1
    fi
    
    local repo_count=$(wc -l < "$output_file")
    echo -e "${GREEN}Generated repo_map with $repo_count repositories${NC}"
    log "INFO" "Generated repo_map: $output_file ($repo_count repositories)"
    return 0
}

# Generate profile metadata
generate_profile_metadata() {
    local profile_name="$1"
    local manifest_file="$2"
    local repo_map_file="$3"
    local metadata_file="$4"
    
    local repo_count=$(wc -l < "$repo_map_file" 2>/dev/null || echo "0")
    local creation_date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    
    # Extract common upstream branch from manifest if available
    local upstream_branch=""
    if [ -f "$manifest_file" ]; then
        upstream_branch=$(grep 'upstream=' "$manifest_file" | head -1 | sed -n 's/.*upstream="\([^"]*\)".*/\1/p')
    fi
    
    # Generate metadata JSON
    cat > "$metadata_file" << EOF
{
  "profile_name": "$profile_name",
  "created_date": "$creation_date",
  "source_manifest": "$(basename "$manifest_file")",
  "repository_count": $repo_count,
  "upstream_branch": "$upstream_branch"
}
EOF
    
    log "INFO" "Generated profile metadata: $metadata_file"
    return 0
}

# Create profile from manifest
profile_create() {
    local profile_path="$1"
    
    if [ -z "$profile_path" ]; then
        echo -e "${RED}Usage: $0 profile create <release>/<name>${NC}"
        echo -e "${YELLOW}Example: $0 profile create unleashed_200.19/openwrt_common${NC}"
        return 1
    fi
    
    # Parse release and name from profile_path
    local release=$(dirname "$profile_path")
    local profile_name=$(basename "$profile_path")
    
    if [ "$release" = "." ] || [ -z "$profile_name" ]; then
        echo -e "${RED}Error: Invalid profile path. Use format: <release>/<name>${NC}"
        return 1
    fi
    
    if ! init_profiles_dir; then
        return 1
    fi
    
    local profile_dir="$profiles_dir/$profile_path"
    local manifest_file="$profile_dir/manifest.xml"
    local repo_map_file="$profile_dir/repo_map.txt"
    local metadata_file="$profile_dir/metadata.json"
    
    # Check if manifest.xml exists in the target directory
    if [ ! -f "$manifest_file" ]; then
        echo -e "${RED}Error: Manifest file not found: $manifest_file${NC}"
        echo -e "${YELLOW}Please copy your manifest.xml to: $profile_dir/${NC}"
        echo -e "${CYAN}mkdir -p $profile_dir${NC}"
        echo -e "${CYAN}cp your_manifest.xml $manifest_file${NC}"
        return 1
    fi
    
    # Check if profile already exists
    if [ -f "$repo_map_file" ]; then
        echo -e "${YELLOW}Profile '$profile_path' already exists${NC}"
        echo -e "${CYAN}Regenerating from manifest...${NC}"
    fi
    
    # Parse manifest and generate repo_map
    if ! parse_manifest_xml "$manifest_file" "$repo_map_file"; then
        return 1
    fi
    
    # Generate metadata
    if ! generate_profile_metadata "$profile_name" "$manifest_file" "$repo_map_file" "$metadata_file"; then
        return 1
    fi
    
    echo -e "${GREEN}Profile '$profile_path' created successfully${NC}"
    echo -e "${CYAN}Profile directory: $profile_dir${NC}"
    echo -e "${CYAN}Repository count: $(wc -l < "$repo_map_file")${NC}"
    
    return 0
}

# List available profiles
profile_list() {
    if ! init_profiles_dir; then
        return 1
    fi
    
    if [ ! -d "$profiles_dir" ] || [ -z "$(ls -A "$profiles_dir" 2>/dev/null)" ]; then
        echo -e "${YELLOW}No profiles found.${NC}"
        echo -e "${CYAN}Create a profile with: $0 profile create <release>/<name>${NC}"
        return 0
    fi
    
    echo -e "${CYAN}Available profiles:${NC}"
    
    # Group by release
    for release_dir in "$profiles_dir"/*; do
        if [ -d "$release_dir" ]; then
            local release_name=$(basename "$release_dir")
            echo -e "${GREEN}Release: $release_name${NC}"
            
            for profile_dir in "$release_dir"/*; do
                if [ -d "$profile_dir" ]; then
                    local profile_name=$(basename "$profile_dir")
                    local metadata_file="$profile_dir/metadata.json"
                    local repo_count="?"
                    
                    if [ -f "$metadata_file" ]; then
                        repo_count=$(grep '"repository_count"' "$metadata_file" | sed 's/.*: *\([0-9]*\).*/\1/')
                    fi
                    
                    echo -e "  - ${YELLOW}$profile_name${NC} ($repo_count repositories)"
                fi
            done
            echo
        fi
    done
}

# Show profile details
profile_show() {
    local profile_path="$1"
    
    if [ -z "$profile_path" ]; then
        echo -e "${RED}Usage: $0 profile show <release>/<name>${NC}"
        return 1
    fi
    
    local profile_dir="$profiles_dir/$profile_path"
    local manifest_file="$profile_dir/manifest.xml"
    local repo_map_file="$profile_dir/repo_map.txt"
    local metadata_file="$profile_dir/metadata.json"
    
    if [ ! -d "$profile_dir" ]; then
        echo -e "${RED}Error: Profile '$profile_path' not found${NC}"
        echo -e "${YELLOW}Available profiles:${NC}"
        profile_list
        return 1
    fi
    
    echo -e "${CYAN}Profile: $profile_path${NC}"
    echo
    
    # Show metadata if available
    if [ -f "$metadata_file" ]; then
        echo -e "${GREEN}Metadata:${NC}"
        if command -v jq >/dev/null 2>&1; then
            jq . "$metadata_file"
        else
            cat "$metadata_file"
        fi
        echo
    fi
    
    # Show repository mappings
    if [ -f "$repo_map_file" ]; then
        echo -e "${GREEN}Repository mappings:${NC}"
        cat "$repo_map_file"
        echo
    fi
    
    # Show files in profile directory
    echo -e "${GREEN}Profile files:${NC}"
    ls -la "$profile_dir"
}

# ------------------------------------------------------------------
# NEW: Show help / usage information
# ------------------------------------------------------------------
show_help() {
    cat <<'EOF'
Usage:
  ./git_sh1.sh verify
      Verify that all local repositories exist.

  ./git_sh1.sh fetch <repo_name|all>
      Fetch repository metadata.
      Examples:
        ./git_sh1.sh fetch all
        ./git_sh1.sh fetch controller

  ./git_sh1.sh worktree add <repo_name|all> -lb <local_branch_name> -rb <remote_branch_name>
      Add a git worktree for the specified repository and branch.
      Examples:
        ./git_sh1.sh worktree add all -lb local5 -rb origin/master
        ./git_sh1.sh worktree add ap_zd_controller -lb local5 -rb origin/release/unleashed_200.17

  ./git_sh1.sh worktree pull-rebase <repo_name|all> <local_branch_name>
      Pull and rebase the given worktree branch.
      Examples:
        ./git_sh1.sh worktree pull-rebase controller local5
        ./git_sh1.sh worktree pull-rebase all local5

  ./git_sh1.sh show_repos
      List every repository key configured in this script.

  ./git_sh1.sh profile create <release>/<name>
      Create a profile from a manifest.xml file. The manifest.xml must already exist in the profile directory.
      Examples:
        ./git_sh1.sh profile create unleashed_200.19/openwrt_common
        ./git_sh1.sh profile create unleashed_200.19/openwrt_r370

  ./git_sh1.sh profile list
      List all available profiles grouped by release.

  ./git_sh1.sh profile show <release>/<name>
      Show detailed information about a specific profile.
      Examples:
        ./git_sh1.sh profile show unleashed_200.19/openwrt_common
        ./git_sh1.sh profile show unleashed_200.19/openwrt_r370

  ./git_sh1.sh feature create [-w <worktree>] <feature_name> <repo1> [repo2] ...
      Create or switch to feature branches across multiple repositories.
      -w <worktree>: Optional. Specify which worktree to create the feature in.
      Examples:
        ./git_sh1.sh feature create dropbear_replacement controller openssh_rks
        ./git_sh1.sh feature create -w unleashed_200.18.7.101_r370 dropbear_replacement controller openssh_rks

  ./git_sh1.sh feature add [-w <worktree>] <feature_name> <repo_name>
      Add a repository to an existing feature.
      -w <worktree>: Optional. Specify which worktree to add the repository in.
      Examples:
        ./git_sh1.sh feature add dropbear_replacement opensource
        ./git_sh1.sh feature add -w unleashed_200.18.7.101_r370 dropbear_replacement opensource

  ./git_sh1.sh feature list
      List all features with their associated repositories and comments.

  ./git_sh1.sh feature show [-w <worktree>] <feature_name>
      Show detailed status of a specific feature across all its repositories.
      -w <worktree>: Optional. Override the worktree to check status in.
      Examples:
        ./git_sh1.sh feature show dropbear_replacement
        ./git_sh1.sh feature show -w unleashed_200.18.7.101_r370 dropbear_replacement

  ./git_sh1.sh feature comment <feature_name> <comment>
      Add or update a comment for a feature.
      Example:
        ./git_sh1.sh feature comment dropbear_replacement "Replacing dropbear with openssh for enhanced security"

  ./git_sh1.sh feature switch [-w <worktree>] <feature_name>
      Switch to feature branches for all repositories in a feature.
      -w <worktree>: Optional. Override the worktree to switch branches in.
      Examples:
        ./git_sh1.sh feature switch dropbear_replacement
        ./git_sh1.sh feature switch -w unleashed_200.18.7.101_r370 dropbear_replacement

  ./git_sh1.sh feature switchback [-w <worktree>] <feature_name>
      Switch back to original branches that were active before creating the feature.
      -w <worktree>: Optional. Override the worktree to switch branches in.
      Examples:
        ./git_sh1.sh feature switchback dropbear_replacement
        ./git_sh1.sh feature switchback -w unleashed_200.18.7.101_r370 dropbear_replacement

  ./git_sh1.sh feature pick [-w <worktree>] <feature_name> <target_branch>
      Cherry-pick all feature commits to a target branch across all repositories.
      -w <worktree>: Optional. Override the worktree to perform cherry-pick in.
      Examples:
        ./git_sh1.sh feature pick dropbear_replacement main
        ./git_sh1.sh feature pick -w unleashed_200.18.7.101_r370 dropbear_replacement main

  ./git_sh1.sh -h | ./git_sh1.sh --help
      Display this help and exit.

  ./git_sh1.sh --install-completion
      Install bash tab completion for this script.
      This enables auto-completion when you press [TAB].
      Example: ./git_sh1.sh fetch [TAB] shows repository names

  ./git_sh1.sh --clear-cache
      Clear the completion cache.
      Use this if repository or feature names are not showing correctly.

COMPLETION USAGE:
  After installing completion, you can use [TAB] to auto-complete:
    ./git_sh1.sh [TAB]                    # Shows available commands
    ./git_sh1.sh fetch [TAB]              # Shows repository names
    ./git_sh1.sh feature create [TAB]     # Shows flags and options
    ./git_sh1.sh feature show [TAB]       # Shows existing features

EOF
}

# Usage validation
check_usage() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: No command specified${NC}"
        show_help
        return 1
    fi
    return 0
}

# Install bash completion
install_bash_completion() {
    local completion_script="${script_dir}/git_sh1_completion.bash"
    local install_script="${script_dir}/install_completion.sh"
    
    echo -e "${CYAN}Installing git_sh1.sh bash completion...${NC}"
    
    # Check if completion script exists
    if [ ! -f "$completion_script" ]; then
        echo -e "${RED}Error: Completion script not found: $completion_script${NC}"
        echo -e "${YELLOW}Please ensure git_sh1_completion.bash is in the same directory as this script${NC}"
        return 1
    fi
    
    # Check if install script exists and is executable
    if [ -f "$install_script" ] && [ -x "$install_script" ]; then
        echo -e "${CYAN}Running installation script...${NC}"
        "$install_script" "$@"
        return $?
    else
        # Fallback: simple installation
        echo -e "${CYAN}Using simple installation method...${NC}"
        
        local bashrc="$HOME/.bashrc"
        local source_line="source \"$completion_script\""
        
        if [ -f "$bashrc" ] && ! grep -q "$completion_script" "$bashrc"; then
            echo "" >> "$bashrc"
            echo "# Git SH1 completion" >> "$bashrc"
            echo "$source_line" >> "$bashrc"
            echo -e "${GREEN}✓ Added completion to $bashrc${NC}"
            echo -e "${YELLOW}Note: Run 'source ~/.bashrc' or restart your shell to enable completion${NC}"
            return 0
        elif grep -q "$completion_script" "$bashrc"; then
            echo -e "${YELLOW}Completion already installed in $bashrc${NC}"
            return 0
        else
            echo -e "${RED}Error: Could not install completion${NC}"
            return 1
        fi
    fi
}

# Clear completion cache
clear_completion_cache() {
    local cache_dir="$HOME/.cache/git_sh1"
    if [ -d "$cache_dir" ]; then
        rm -rf "$cache_dir"
        echo -e "${GREEN}Completion cache cleared: $cache_dir${NC}"
    else
        echo -e "${YELLOW}No completion cache found${NC}"
    fi
    return 0
}

# Main execution wrapper with error handling
main() {
    local exit_code=0
    
    # Check basic usage
    if ! check_usage "$@"; then
        return 1
    fi
    
    # Set up dry-run and verbose modes from environment
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}Running in DRY-RUN mode - no changes will be made${NC}"
    fi
    
    case "$1" in
        -h|--help)
            show_help
            return 0
            ;;
        --install-completion)
            install_bash_completion
            return $?
            ;;
        --clear-cache)
            clear_completion_cache
            return $?
            ;;
        verify)
            if ! verify_repos "$2"; then
                exit_code=$?
            fi
            ;;
        fetch)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Repository name required for fetch command${NC}"
                echo "Usage: $0 fetch <repo_name|all>"
                return 1
            fi
            if ! fetch_repos "$2"; then
                exit_code=$?
            fi
            ;;
        worktree)
            case "$2" in
                add)
                    if [ "$4" == "-lb" ] && [ "$6" == "-rb" ] && [ -n "$3" ] && [ -n "$5" ] && [ -n "$7" ]; then
                        if ! add_worktree "$3" "$5" "$7"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for worktree add command${NC}"
                        echo "Usage: $0 worktree add <repo_name> -lb <local-branch-name> -rb <remote-branch-name>"
                        return 1
                    fi
                    ;;
                pull-rebase)
                    if [ -n "$3" ] && [ -n "$4" ]; then
                        if ! pull_rebase_worktree "$3" "$4"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for worktree pull-rebase command${NC}"
                        echo "Usage: $0 worktree pull-rebase <repo_name> <local-branch-name>"
                        return 1
                    fi
                    ;;
                *)
                    echo -e "${RED}Invalid worktree command. Usage: $0 worktree {add|pull-rebase}${NC}"
                    return 1
                    ;;
            esac
            ;;
        show_repos)
            show_repos
            ;;
        profile)
            case "$2" in
                create)
                    if [ -n "$3" ]; then
                        if ! profile_create "$3"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for profile create command${NC}"
                        echo "Usage: $0 profile create <release>/<name>"
                        return 1
                    fi
                    ;;
                list)
                    if ! profile_list; then
                        exit_code=$?
                    fi
                    ;;
                show)
                    if [ -n "$3" ]; then
                        if ! profile_show "$3"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for profile show command${NC}"
                        echo "Usage: $0 profile show <release>/<name>"
                        return 1
                    fi
                    ;;
                *)
                    echo -e "${RED}Invalid profile command. Usage: $0 profile {create|list|show}${NC}"
                    return 1
                    ;;
            esac
            ;;
        feature)
            case "$2" in
                create)
                    if [ -n "$3" ]; then
                        if ! feature_create "${@:3}"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for feature create command${NC}"
                        echo "Usage: $0 feature create [-w <worktree>] [--force] <feature_name> <repo1> [repo2] ..."
                        return 1
                    fi
                    ;;
                add)
                    if [ -n "$3" ] && [ -n "$4" ]; then
                        if ! feature_add "${@:3}"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for feature add command${NC}"
                        echo "Usage: $0 feature add [-w <worktree>] <feature_name> <repo_name>"
                        return 1
                    fi
                    ;;
                list)
                    feature_list
                    ;;
                show)
                    if [ -n "$3" ]; then
                        if ! feature_show "${@:3}"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for feature show command${NC}"
                        echo "Usage: $0 feature show [-w <worktree>] <feature_name>"
                        return 1
                    fi
                    ;;
                comment)
                    if [ -n "$3" ] && [ -n "$4" ]; then
                        if ! feature_comment "$3" "${@:4}"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for feature comment command${NC}"
                        echo "Usage: $0 feature comment <feature_name> <comment>"
                        return 1
                    fi
                    ;;
                switch)
                    if [ -n "$3" ]; then
                        if ! feature_switch "${@:3}"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for feature switch command${NC}"
                        echo "Usage: $0 feature switch [-w <worktree>] <feature_name>"
                        return 1
                    fi
                    ;;
                switchback)
                    if [ -n "$3" ]; then
                        if ! feature_switchback "$3"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for feature switchback command${NC}"
                        echo "Usage: $0 feature switchback <feature_name>"
                        return 1
                    fi
                    ;;
                pick)
                    if [ -n "$3" ] && [ -n "$4" ]; then
                        if ! feature_pick "${@:3}"; then
                            exit_code=$?
                        fi
                    else
                        echo -e "${RED}Invalid arguments for feature pick command${NC}"
                        echo "Usage: $0 feature pick [-w <worktree>] [--dry-run] <feature_name> <target_branch>"
                        return 1
                    fi
                    ;;
                *)
                    echo -e "${RED}Invalid feature command. Usage: $0 feature {create|add|list|show|comment|switch|switchback|pick}${NC}"
                    return 1
                    ;;
            esac
            ;;
        *)
            echo -e "${RED}Invalid command: $1${NC}"
            show_help
            return 1
            ;;
    esac
    
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Command failed with exit code: $exit_code"
        echo -e "${RED}Command completed with errors. Check the log for details.${NC}"
    else
        log "INFO" "Command completed successfully"
    fi
    
    return $exit_code
}

# ------------------------------------------------------------------
# Legacy main script logic (preserved for compatibility)
# ------------------------------------------------------------------
legacy_main() {
case "$1" in
    -h|--help)
        show_help
        ;;
    verify)
        verify_repos "$2"
        ;;
    fetch)
        fetch_repos "$2"
        ;;
    worktree)
        case "$2" in
            add)
                if [ "$4" == "-lb" ] && [ "$6" == "-rb" ]; then
                    add_worktree "$3" "$5" "$7"
                else
                    echo -e "${RED}Invalid arguments for worktree add command${NC}"
                    echo "Usage: $0 worktree add <repo_name> -lb <local-branch-name> -rb <remote-branch-name>"
                fi
                ;;
            pull-rebase)
                if [ -n "$3" ]; then
                    pull_rebase_worktree "$3" "$4"
                else
                    echo -e "${RED}Invalid arguments for worktree pull-rebase command${NC}"
                    echo "Usage: $0 worktree pull-rebase <repo_name> <local-branch-name>"
                fi
                ;;
            *)
                echo -e "${RED}Invalid worktree command. Usage: $0 worktree {add|pull-rebase}${NC}"
                ;;
        esac
        ;;
    show_repos)
        show_repos
        ;;
    profile)
        case "$2" in
            create)
                if [ -n "$3" ]; then
                    profile_create "$3"
                else
                    echo -e "${RED}Invalid arguments for profile create command${NC}"
                    echo "Usage: $0 profile create <release>/<name>"
                fi
                ;;
            list)
                profile_list
                ;;
            show)
                if [ -n "$3" ]; then
                    profile_show "$3"
                else
                    echo -e "${RED}Invalid arguments for profile show command${NC}"
                    echo "Usage: $0 profile show <release>/<name>"
                fi
                ;;
            *)
                echo -e "${RED}Invalid profile command. Usage: $0 profile {create|list|show}${NC}"
                ;;
        esac
        ;;
    feature)
        case "$2" in
                         create)
                 if [ -n "$3" ]; then
                     feature_create "${@:3}"
                 else
                     echo -e "${RED}Invalid arguments for feature create command${NC}"
                     echo "Usage: $0 feature create [-w <worktree>] <feature_name> <repo1> [repo2] ..."
                 fi
                 ;;
            add)
                if [ -n "$3" ] && [ -n "$4" ]; then
                    feature_add "${@:3}"
                else
                    echo -e "${RED}Invalid arguments for feature add command${NC}"
                    echo "Usage: $0 feature add [-w <worktree>] <feature_name> <repo_name>"
                fi
                ;;
            list)
                feature_list
                ;;
            show)
                if [ -n "$3" ]; then
                    feature_show "${@:3}"
                else
                    echo -e "${RED}Invalid arguments for feature show command${NC}"
                    echo "Usage: $0 feature show [-w <worktree>] <feature_name>"
                fi
                ;;
                         comment)
                 if [ -n "$3" ] && [ -n "$4" ]; then
                     feature_comment "$3" "${@:4}"
                 else
                     echo -e "${RED}Invalid arguments for feature comment command${NC}"
                     echo "Usage: $0 feature comment <feature_name> <comment>"
                 fi
                 ;;
            switch)
                if [ -n "$3" ]; then
                    feature_switch "${@:3}"
                else
                    echo -e "${RED}Invalid arguments for feature switch command${NC}"
                    echo "Usage: $0 feature switch [-w <worktree>] <feature_name>"
                fi
                ;;
            switchback)
                if [ -n "$3" ]; then
                    feature_switchback "$3"
                else
                    echo -e "${RED}Invalid arguments for feature switchback command${NC}"
                    echo "Usage: $0 feature switchback [-w <worktree>] <feature_name>"
                fi
                ;;
            pick)
                if [ -n "$3" ] && [ -n "$4" ]; then
                    feature_pick "${@:3}"
                else
                    echo -e "${RED}Invalid arguments for feature pick command${NC}"
                    echo "Usage: $0 feature pick [-w <worktree>] <feature_name> <target_branch>"
                fi
                ;;
            *)
                echo -e "${RED}Invalid feature command. Usage: $0 feature {create|add|list|show|comment|switch|switchback|pick}${NC}"
                ;;
        esac
        ;;
    *)
        echo -e "${RED}Invalid command.${NC}"
        show_help
        ;;
esac
}

# Execute main function with all arguments
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
    exit $?
fi

