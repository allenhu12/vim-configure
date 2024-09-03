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
    vendor_mtk_11be:rks_ap/platform_dp/linux/driver/vendor_mtk_11be
    vendor_qca_ref:rks_ap/platform_dp/linux/driver/vendor_qca_ref
    vendor_qca_tools:vendor_qca_tools
    vendor_mtk:vendor_mtk
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

worktree_base_path="$script_dir"
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

    if [ ! -d "$local_repo_path/.git" ]; then
        echo -e "${GREEN}Fetching metadata for repository: ${YELLOW}${repo}${NC}"

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

    else
        echo -e "${YELLOW}Repository already exists: ${local_repo_path} for ${repo}${NC}"
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

# Main script logic to handle arguments
case "$1" in
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
    *)
        echo -e "${RED}Invalid command. Usage: $0 {verify|fetch|worktree {add|pull-rebase}|show_repos}${NC}"
        ;;
esac

