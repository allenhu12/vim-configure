#!/bin/bash

# =============================================================================
# Worktree Operations Module
# Part of the modular git_sh1 system - CLI interface for worktree commands
# =============================================================================

# Handle worktree add command
handle_worktree_add() {
    local repo=""
    local local_branch=""
    local remote_branch=""
    local profile=""
    
    # Initialize repository system if not already done
    if [[ -z "$repo_base" ]]; then
        if ! init_repository_system; then
            echo -e "${RED}Error: Failed to initialize repository system${NC}"
            return 1
        fi
    fi
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -repo)
                repo="$2"
                shift 2
                ;;
            -lb)
                local_branch="$2"
                shift 2
                ;;
            -rb)
                remote_branch="$2"
                shift 2
                ;;
            --profile)
                profile="$2"
                shift 2
                ;;
            *)
                # Positional argument handling for backward compatibility
                if [ -z "$repo" ]; then
                    repo="$1"
                elif [ -z "$local_branch" ]; then
                    local_branch="$1"
                elif [ -z "$remote_branch" ]; then
                    remote_branch="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Validate required parameters
    if [ -z "$repo" ] || [ -z "$local_branch" ]; then
        echo -e "${RED}Error: Missing required parameters${NC}"
        echo "Usage: worktree add -repo {all|repo_name} -lb {local_branch} [-rb {remote_branch}] [--profile {profile_name}]"
        return 1
    fi
    
    log "INFO" "Worktree add: repo=$repo, local_branch=$local_branch, remote_branch=$remote_branch, profile=$profile"
    
    # Call appropriate function based on whether profile is specified
    if [ -n "$profile" ]; then
        add_worktree_with_profile "$repo" "$local_branch" "$remote_branch" "$profile"
    else
        if [ -z "$remote_branch" ]; then
            echo -e "${RED}Error: -rb parameter required when not using --profile${NC}"
            return 1
        fi
        add_worktree "$repo" "$local_branch" "$remote_branch"
    fi
}

# Handle worktree pull-rebase command
handle_worktree_pull_rebase() {
    local repo=""
    local local_branch=""
    local profile=""
    
    # Initialize repository system if not already done
    if [[ -z "$repo_base" ]]; then
        if ! init_repository_system; then
            echo -e "${RED}Error: Failed to initialize repository system${NC}"
            return 1
        fi
    fi
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -repo)
                repo="$2"
                shift 2
                ;;
            -lb)
                local_branch="$2"
                shift 2
                ;;
            --profile)
                profile="$2"
                shift 2
                ;;
            *)
                # Positional argument handling for backward compatibility
                if [ -z "$repo" ]; then
                    repo="$1"
                elif [ -z "$local_branch" ]; then
                    local_branch="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Validate required parameters
    if [ -z "$repo" ] || [ -z "$local_branch" ]; then
        echo -e "${RED}Error: Missing required parameters${NC}"
        echo "Usage: worktree pull-rebase -repo {all|repo_name} -lb {local_branch} [--profile {profile_name}]"
        return 1
    fi
    
    log "INFO" "Worktree pull-rebase: repo=$repo, local_branch=$local_branch, profile=$profile"
    
    # Call appropriate function based on whether profile is specified
    if [ -n "$profile" ]; then
        pull_rebase_worktree_with_profile "$repo" "$local_branch" "$profile"
    else
        pull_rebase_worktree "$repo" "$local_branch"
    fi
}

# Handle worktree list command (future enhancement)
handle_worktree_list() {
    local local_branch="$1"
    
    if [ -z "$local_branch" ]; then
        echo -e "${CYAN}Available worktree branches:${NC}"
        if [ -d "$worktree_base_path" ]; then
            find "$worktree_base_path" -maxdepth 1 -type d ! -path "$worktree_base_path" -exec basename {} \; | sort
        else
            echo -e "${YELLOW}No worktree base directory found${NC}"
        fi
    else
        echo -e "${CYAN}Repository worktrees in branch: $local_branch${NC}"
        local branch_dir="$worktree_base_path/$local_branch"
        if [ -d "$branch_dir" ]; then
            find "$branch_dir" -maxdepth 1 -type d ! -path "$branch_dir" -exec basename {} \; | sort
        else
            echo -e "${YELLOW}No worktrees found for branch: $local_branch${NC}"
        fi
    fi
}

# Handle worktree remove command (future enhancement)
handle_worktree_remove() {
    local repo="$1"
    local local_branch="$2"
    
    if [ -z "$repo" ] || [ -z "$local_branch" ]; then
        echo -e "${RED}Error: Missing required parameters${NC}"
        echo "Usage: worktree remove {repo_name} {local_branch}"
        return 1
    fi
    
    echo -e "${YELLOW}Worktree remove functionality not yet implemented${NC}"
    echo "This will be implemented in a future phase"
    return 1
}

# Main worktree command dispatcher
handle_worktree_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        add)
            handle_worktree_add "$@"
            ;;
        pull-rebase)
            handle_worktree_pull_rebase "$@"
            ;;
        list)
            handle_worktree_list "$@"
            ;;
        remove)
            handle_worktree_remove "$@"
            ;;
        *)
            echo -e "${RED}Error: Unknown worktree subcommand: $subcommand${NC}"
            echo "Available subcommands:"
            echo "  add         - Create new worktree"
            echo "  pull-rebase - Pull and rebase worktree"  
            echo "  list        - List available worktrees"
            echo "  remove      - Remove worktree (not implemented)"
            return 1
            ;;
    esac
}

log "INFO" "Worktree operations module loaded"