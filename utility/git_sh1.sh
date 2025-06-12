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

# Determine the script's directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate up the directory tree until we find the git-depot directory
repo_base="$script_dir"
while [[ "$repo_base" != "/" && "${repo_base##*/}" != "git-depot" ]]; do
    repo_base="$(dirname "$repo_base")"
done

if [[ "${repo_base##*/}" != "git-depot" ]]; then
    echo -e "${RED}Error: Could not find the git-depot directory${NC}"
    exit 1
fi

# Now that we've found git-depot, find a directory containing "repo_base" in its name
repo_base=$(find "$repo_base" -maxdepth 1 -type d -name "*repo_base*" -print -quit)

if [ -z "$repo_base" ]; then
    echo -e "${RED}Error: Could not find a directory containing 'repo_base' in its name${NC}"
    exit 1
fi

# Worktree base path should be the git-depot directory
worktree_base_path="$repo_base/.."
if [[ "${worktree_base_path##*/}" != "git-depot" ]]; then
    # If we're not in git-depot, try to find it
    temp_path="$script_dir"
    while [[ "$temp_path" != "/" && "${temp_path##*/}" != "git-depot" ]]; do
        temp_path="$(dirname "$temp_path")"
    done
    if [[ "${temp_path##*/}" == "git-depot" ]]; then
        worktree_base_path="$temp_path"
    fi
fi

ssh_base="ssh://tdc-mirror-git@ruckus-git.ruckuswireless.com:7999/wrls/"

# Verify if a specific repository or all repos are ready
verify_repos() {
    local existing_repos=0
    local missing_repos=0
    local total_repos=0

    echo -e "${CYAN}Verifying all repositories:${NC}"
    echo -e "${YELLOW}Script directory: $script_dir${NC}"
    echo -e "${YELLOW}Using repo_base: $repo_base${NC}"
    echo ""
    
    for pair in $repo_map; do
        IFS=':' read -r repo local_folder <<< "$pair"
        verify_single_repo "$repo" "$local_folder"
        ((total_repos++))
    done

    echo -e "\n${CYAN}Summary:${NC}"
    echo -e "Total repositories: $total_repos"
    echo -e "${GREEN}Existing repositories: $existing_repos${NC}"
    echo -e "${RED}Missing repositories: $missing_repos${NC}"

    if [ $missing_repos -gt 0 ]; then
        echo -e "\n${YELLOW}Note: To fetch missing repositories, use the following command:${NC}"
        echo -e "${CYAN}./git_sh1.sh fetch all${NC}"
    fi
}

verify_single_repo() {
    local repo=$1
    local local_folder=$2
    local repo_path="$repo_base/$local_folder"
    
    echo -e "${CYAN}Checking repo: $repo${NC}"
    echo -e "${CYAN}Repo path: $repo_path${NC}"
    
    if [ -d "$repo_path" ] && ([ -d "$repo_path/.git" ] || [ -f "$repo_path/.git" ]); then
        echo -e "${GREEN}Exists:  $repo${NC}"
        ((existing_repos++))
    else
        echo -e "${RED}Missing: $repo${NC}"
        ((missing_repos++))
    fi
    echo "" # Add a blank line for better readability
}

# Fetch metadata for a specific repository or all repositories
fetch_repos() {
    if [ "$1" == "all" ]; then
        for pair in $repo_map; do
            IFS=':' read -r repo local_folder <<< "$pair"
            fetch_repo "$repo" "$local_folder"
        done
    else
        repo_found=false
        for pair in $repo_map; do
            IFS=':' read -r repo local_folder <<< "$pair"
            if [ "$repo" == "$1" ]; then
                repo_found=true
                fetch_repo "$repo" "$local_folder"
                break
            fi
        done
        if ! $repo_found; then
            echo -e "${RED}Repository $1 not found in repo_map${NC}"
        fi
    fi
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
    repo=$1
    local_folder=$2
    local_branch=$3
    remote_branch=$4

    repo_dir="$repo_base/$local_folder"
    worktree_dir="$worktree_base_path/$local_branch/$local_folder"

    if [ ! -d "$repo_dir/.git" ]; then
        echo -e "${RED}Repository not found or not a Git repository: $repo_dir${NC}"
        return
    fi

    cd "$repo_dir"

    # Prune any stale worktree entries
    git worktree prune

    # Remove the worktree directory if it already exists
    if [ -d "$worktree_dir" ]; then
        echo -e "${YELLOW}Removing existing worktree directory: $worktree_dir${NC}"
        git worktree remove --force "$worktree_dir" || true
        rm -rf "$worktree_dir"
    fi

    echo -e "${CYAN}Processing repository: ${YELLOW}$repo${NC}"

    # Check if the local branch exists
    if git show-ref --verify --quiet "refs/heads/$local_branch"; then
        echo -e "${YELLOW}Branch $local_branch already exists, reusing it.${NC}"
        # If the branch exists, just add the worktree with the existing branch
        git worktree add -f "$worktree_dir" "$local_branch"
    else
        echo -e "${GREEN}Creating new branch $local_branch from $remote_branch.${NC}"
        # If the branch doesn't exist, create it and add it as a worktree
        git worktree add --checkout -b "$local_branch" "$worktree_dir" "$remote_branch"
    fi

    echo -e "${CYAN}Worktree added for $repo at $worktree_dir${NC}"
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

# Initialize features directory if it doesn't exist
init_features_dir() {
    if [ ! -d "$features_dir" ]; then
        mkdir -p "$features_dir"
        echo -e "${GREEN}Initialized features directory at: $features_dir${NC}"
    fi
}

# Create or switch to a feature branch
feature_create() {
    local feature_name=""
    local worktree=""
    local repos=()
    
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
                else
                    repos+=("$1")
                    shift
                fi
                ;;
        esac
    done
    
    if [ -z "$feature_name" ] || [ ${#repos[@]} -eq 0 ]; then
        echo -e "${RED}Usage: $0 feature create -w <worktree> <feature_name> <repo1> [repo2] ...${NC}"
        echo -e "${YELLOW}  -w <worktree>: Required. Specify which worktree to create the feature in${NC}"
        return 1
    fi

    if [ -z "$worktree" ]; then
        echo -e "${RED}Error: Worktree (-w) is required for feature creation${NC}"
        echo -e "${YELLOW}Usage: $0 feature create -w <worktree> <feature_name> <repo1> [repo2] ...${NC}"
        return 1
    fi
    
    init_features_dir
    
    local feature_dir="$features_dir/$feature_name"
    mkdir -p "$feature_dir"
    
    # Save the repository list
    printf "%s\n" "${repos[@]}" > "$feature_dir/repos.txt"
    
    # Save worktree info
    echo "$worktree" > "$feature_dir/worktree.txt"
    echo -e "${CYAN}Using worktree: $worktree${NC}"
    
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
    echo "$branches_json" > "$feature_dir/branches.json"
    
    echo -e "${GREEN}Feature '$feature_name' created/updated with repositories: ${repos[*]}${NC}"
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
        echo -e "${RED}Usage: $0 feature pick [-w <worktree>] <feature_name> <target_branch>${NC}"
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
    
    echo -e "${CYAN}Cherry-picking feature commits to $target_branch...${NC}"
    
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
        
        # Checkout target branch
        if ! git checkout "$target_branch"; then
            echo -e "${RED}Failed to checkout $target_branch in $repo${NC}"
            continue
        fi
        
        # Find commits that are only on the feature branch
        local merge_base=$(git merge-base "$target_branch" "$feature_branch")
        local commits=$(git rev-list --reverse "$merge_base".."$feature_branch")
        
        if [ -z "$commits" ]; then
            echo -e "${YELLOW}No commits to cherry-pick from $feature_branch in $repo${NC}"
            continue
        fi
        
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
    done < "$feature_dir/repos.txt"
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

  ./git_sh1.sh feature create [-w <worktree>] <feature_name> <repo1> [repo2] ...
      Create or switch to feature branches across multiple repositories.
      -w <worktree>: Optional. Specify which worktree to create the feature in.
      Examples:
        ./git_sh1.sh feature create dropbear_replacement controller openssh_rks
        ./git_sh1.sh feature create -w unleashed_200.18.7.101_r370 dropbear_replacement controller openssh_rks

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
EOF
}

# ------------------------------------------------------------------
# Main script logic to handle arguments
# ------------------------------------------------------------------
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
                echo -e "${RED}Invalid feature command. Usage: $0 feature {create|list|show|comment|switch|switchback|pick}${NC}"
                ;;
        esac
        ;;
    *)
        echo -e "${RED}Invalid command.${NC}"
        show_help
        ;;
esac

