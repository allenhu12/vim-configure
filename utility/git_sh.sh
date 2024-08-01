#!/bin/bash

### chmod +x git_sh.sh
### ./git_sh.sh verify                            # To verify repositories
### ./git_sh.sh clone                             # To clone repositories
### ./git_sh.sh branch                            # To list branches
### ./git_sh.sh worktree add -lb <local-branch-name> -rb <remote-branch-name>  # To add a worktree
### ./git_sh.sh worktree pull-rebase <local-branch-name>  # To pull and rebase in worktree

# Define key-value pairs in a single string (repository name:local folder)
repo_map="wrls/opensource:opensource wrls/rks_ap:rks_ap wrls/dl:dl wrls/linux_3_14:opensource/linux/kernels/linux-3.14.43 wrls/linux_4_4:opensource/linux/kernels/linux-4.4.60 wrls/linux_5_4:opensource/linux/kernels/linux-5.4 wrls/linux_5_4_mtk:linux_5_4_mtk wrls/controller:rks_ap/controller wrls/ap_zd_controller:rks_ap/controller/common wrls/ruckus-spark:ruckus-spark wrls/ap_scg_common:rks_ap/ap_scg_common wrls/ap_scg_rcli:rks_ap/controller/rcli wrls/vendor_qca_11ac:rks_ap/platform_dp/linux/driver/vendor_qca_11ac wrls/vendor_qca_11ax:rks_ap/platform_dp/linux/driver/vendor_qca_11ax wrls/vendor_qca_11ax6e:rks_ap/platform_dp/linux/driver/vendor_qca_11ax6e wrls/vendor_qca_11be:rks_ap/platform_dp/linux/driver/vendor_qca_11be wrls/vendor_mtk_11be:rks_ap/platform_dp/linux/driver/vendor_mtk_11be wrls/vendor_qca_ref:rks_ap/platform_dp/linux/driver/vendor_qca_ref wrls/vendor_qca_tools:vendor_qca_tools wrls/vendor_mtk:vendor_mtk wrls/rpoint_handler:rpoint_handler wrls/rtty:rtty wrls/rksiot:rksiot wrls/rksiot_hpkg:rksiot_hpkg"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color



# Determine the script's directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the repository list
repo_list="dl rks_ap rks_ap/ap_scg_common rks_ap/controller rks_ap/controller/rcli rks_ap/controller/common rks_ap/platform_dp/linux/driver/vendor_qca_ref rks_ap/platform_dp/linux/driver/vendor_qca_11ac rks_ap/platform_dp/linux/driver/vendor_qca_11ax rks_ap/platform_dp/linux/driver/vendor_qca_11be rksiot vendor_qca_tools rpoint_handler rksiot_hpkg opensource opensource/linux/kernels/linux-4.4.60 opensource/linux/kernels/linux-5.4 rtty"



# Define base paths relative to the script's directory
base_path="$script_dir/repo_base"
worktree_base_path="$script_dir"
ssh_base="ssh://tdc-mirror-git@ruckus-git.ruckuswireless.com:7999/wrls/"

# Define color for highlighted output
highlight='\033[1;33m'  # Yellow color for highlight
normal='\033[0m'        # Reset color

# Verify if all the base Git repos are ready
verify_repos() {
    for repo in $repo_list; do
        if [ ! -d "$base_path/$repo/.git" ]; then
            echo "Repository missing or not a Git repository: $base_path/$repo"
        else
            echo "Repository exists: $base_path/$repo"
        fi
    done
}

# Clone all repositories from remote
clone_repos() {
    for repo in $repo_list; do
        repo_url="${ssh_base}${repo}.git"
        if [ ! -d "$base_path/$repo/.git" ]; then
            echo -e "${highlight}Cloning repository: $repo${normal}"
            git clone "$repo_url" "$base_path/$repo"
        else
            echo "Repository already exists: $base_path/$repo"
        fi
    done
}

fetch_repos() {
    IFS=' ' read -r -a repo_pairs <<< "$repo_map"

    for pair in "${repo_pairs[@]}"; do
        IFS=':' read -r repo local_folder <<< "$pair"
        repo_url="${ssh_base}${repo}.git"
        local_repo_path="$base_path/$local_folder"

        echo -e "${CYAN}Processing repository: ${YELLOW}${repo}${NC}"
        echo -e "${CYAN}Local folder: ${YELLOW}${local_repo_path}${NC}"
        echo -e "${CYAN}Remote URL: ${YELLOW}${repo_url}${NC}"

        if [ ! -d "$local_repo_path/.git" ]; then
            echo -e "${GREEN}Fetching metadata for repository: ${YELLOW}${repo}${NC}"

            mkdir -p "$local_repo_path" || {
                echo -e "${RED}Failed to create directory: ${local_repo_path} for ${repo}${NC}"
                continue
            }

            cd "$local_repo_path" || {
                echo -e "${RED}Failed to enter directory: ${local_repo_path} for ${repo}${NC}"
                continue
            }

            echo -e "${GREEN}Entering directory: ${YELLOW}$(pwd)${NC} for ${YELLOW}${repo}${NC}"

            git init || {
                echo -e "${RED}Failed to initialize bare repository at: ${local_repo_path} for ${repo_url}${NC}"
                continue
            }

            git remote add origin "$repo_url" || {
                echo -e "${RED}Failed to add remote for repository: ${repo_url} at ${local_repo_path}${NC}"
                continue
            }

            git fetch origin || {
                echo -e "${RED}Failed to fetch from repository: ${repo_url} into ${local_repo_path}${NC}"
                continue
            }
        else
            echo -e "${YELLOW}Repository already exists: ${local_repo_path} for ${repo}${NC}"
        fi

        echo -e "${CYAN}Completed processing repository: ${YELLOW}${repo}${NC}\n"
    done
}

# List all remote branch names
list_branches() {
    for repo in $repo_list; do
        repo_dir="$base_path/$repo"
        if [ -d "$repo_dir/.git" ]; then
            echo -e "${highlight}Branches for $repo:${normal}"
            (cd "$repo_dir" && git branch -r)
        else
            echo "Repository not found or not a Git repository: $repo_dir"
        fi
    done
}

# Add a worktree for a specific branch
add_worktree() {
    local_branch=$1
    remote_branch=$2
    worktree_path="$worktree_base_path/$local_branch"

    mkdir -p "$worktree_path"

    for repo in $repo_list; do
        repo_dir="$base_path/$repo"
        worktree_dir="$worktree_path/$repo"

        if [ ! -d "$repo_dir/.git" ]; then
            echo "Repository not found or not a Git repository: $repo_dir"
            continue
        fi

        cd "$repo_dir"

        # Prune any stale worktree entries
        git worktree prune

        # Remove the worktree directory if it already exists
        if [ -d "$worktree_dir" ]; then
            echo "Removing existing worktree directory: $worktree_dir"
            git worktree remove --force "$worktree_dir" || true
            rm -rf "$worktree_dir"
        fi

        echo -e "${highlight}Processing repository: $repo${normal}"

        # Check if the local branch exists
        if git show-ref --verify --quiet "refs/heads/$local_branch"; then
            echo "Branch $local_branch already exists, reusing it."
        else
            echo "Creating new branch $local_branch from $remote_branch."
            git checkout -b "$local_branch" "$remote_branch"
        fi

        # Add the worktree, forcing if necessary
        git worktree add -f "$worktree_dir" "$local_branch"
    done
}

# Pull and rebase each repository in the worktree
pull_rebase_worktree() {
    local_branch=$1
    worktree_path="$worktree_base_path/$local_branch"

    for repo in $repo_list; do
        worktree_dir="$worktree_path/$repo"

        if [ ! -d "$worktree_dir/.git" ] && [ ! -f "$worktree_dir/.git" ]; then
            echo "Worktree directory not found or not a Git repository: $worktree_dir"
            continue
        fi

        cd "$worktree_dir"
        echo -e "${highlight}Pulling and rebasing $repo in $local_branch${normal}"
        git pull --rebase --autostash
    done
}

# Main script logic to handle arguments
case "$1" in
    verify)
        verify_repos
        ;;
    clone)
        clone_repos
        ;;
    fetch)
        fetch_repos
        ;;
    branch)
        list_branches
        ;;
    worktree)
        case "$2" in
            add)
                if [ "$3" = "-lb" ] && [ "$5" = "-rb" ]; then
                    add_worktree "$4" "$6"
                else
                    echo "Invalid arguments for worktree add command"
                    echo "Usage: $0 worktree add -lb <local-branch-name> -rb <remote-branch-name>"
                fi
                ;;
            pull-rebase)
                if [ -n "$3" ]; then
                    pull_rebase_worktree "$3"
                else
                    echo "Invalid arguments for worktree pull-rebase command"
                    echo "Usage: $0 worktree pull-rebase <local-branch-name>"
                fi
                ;;
            *)
                echo "Invalid worktree command. Usage: $0 worktree {add|pull-rebase}"
                ;;
        esac
        ;;
    *)
        echo "Invalid command. Usage: $0 {verify|clone|branch|worktree {add|pull-rebase}}"
        ;;
esac

