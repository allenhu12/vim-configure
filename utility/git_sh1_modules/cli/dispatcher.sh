#!/bin/bash

# cli/dispatcher.sh - Command dispatcher for git_sh1_modules
# Routes commands to appropriate modules and functions

# Basic usage check
check_usage() {
    if [[ $# -eq 0 ]]; then
        echo -e "${RED}Error: No command specified${NC}"
        show_help
        return 1
    fi
    return 0
}

# Install bash completion
install_bash_completion() {
    load_module "cli/completion.sh"
    _git_sh1_install_completion
    return $?
}

# Clear completion cache
clear_completion_cache() {
    load_module "cli/completion.sh"
    _git_sh1_clear_cache
    return $?
}

# Repository command implementations
cmd_verify() {
    # Delegate to repository manager
    cmd_verify_repos "$@"
    return $?
}

cmd_fetch() {
    # Delegate to repository manager
    cmd_fetch_repos "$@"
    return $?
}

cmd_worktree() {
    # Delegate to worktree operations module
    handle_worktree_command "$@"
    return $?
}

cmd_feature() {
    load_module "features/operations.sh"
    load_module "features/metadata.sh"
    
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: No feature subcommand specified${NC}"
        echo "Usage: $0 feature <subcommand> [options]"
        echo "Subcommands:"
        echo "  create    - Create a new feature"
        echo "  list      - List all features"
        echo "  show      - Show feature details"
        echo "  add       - Add repository to feature"
        echo "  switch    - Switch to feature branches"
        echo "  comment   - Add comment to feature"
        return 1
    fi
    
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        create)
            feature_create "$@"
            ;;
        list)
            feature_list "$@"
            ;;
        show)
            feature_show "$@"
            ;;
        add)
            feature_add "$@"
            ;;
        switch)
            feature_switch "$@"
            ;;
        comment)
            feature_comment "$@"
            ;;
        *)
            echo -e "${RED}Error: Unknown feature subcommand '$subcommand'${NC}"
            echo "Use 'git_sh1.sh feature' to see available subcommands"
            return 1
            ;;
    esac
}

cmd_profile() {
    load_module "profiles/manager.sh"
    
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: No profile subcommand specified${NC}"
        echo "Usage: $0 profile <subcommand> [options]"
        echo "Subcommands:"
        echo "  create    - Create a new profile from manifest.xml"
        echo "  list      - List all available profiles"
        echo "  show      - Show profile details"
        return 1
    fi
    
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        create)
            profile_create "$@"
            ;;
        list)
            profile_list "$@"
            ;;
        show)
            profile_show "$@"
            ;;
        *)
            echo -e "${RED}Error: Unknown profile subcommand '$subcommand'${NC}"
            echo "Use 'git_sh1.sh profile' to see available subcommands"
            return 1
            ;;
    esac
}

# Main command dispatcher
dispatch_command() {
    local exit_code=0
    
    # Check basic usage
    if ! check_usage "$@"; then
        return 1
    fi
    
    # Parse and route commands
    case "$1" in
        -h|--help)
            if [[ -n "$2" ]]; then
                case "$2" in
                    examples)
                        show_usage_examples
                        ;;
                    environment|configuration|troubleshooting)
                        show_advanced_help "$2"
                        ;;
                    *)
                        show_command_help "$2"
                        ;;
                esac
            else
                show_help
            fi
            return 0
            ;;
        --version)
            show_version
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
            cmd_verify "${@:2}"
            exit_code=$?
            ;;
        fetch)
            cmd_fetch "${@:2}"
            exit_code=$?
            ;;
        worktree)
            cmd_worktree "${@:2}"
            exit_code=$?
            ;;
        feature)
            cmd_feature "${@:2}"
            exit_code=$?
            ;;
        profile)
            cmd_profile "${@:2}"
            exit_code=$?
            ;;
        repos)
            # List available repositories
            cmd_show_repos
            exit_code=$?
            ;;
        test)
            # Hidden test command for development
            echo -e "${GREEN}✓ Modular system is working!${NC}"
            echo ""
            echo "Core modules loaded successfully:"
            echo "  - config.sh: Repository map and global variables"
            echo "  - logging.sh: Logging system and cleanup"
            echo "  - validation.sh: Input sanitization and path validation"
            echo "  - utils.sh: Common utilities"
            echo ""
            echo "Repository modules loaded successfully:"
            echo "  - repo/discovery.sh: Repository discovery and path resolution"
            echo "  - repo/operations.sh: Repository operations and SSH connectivity"
            echo "  - repo/manager.sh: High-level repository management"
            echo ""
            echo "Available colors:"
            echo -e "  ${RED}RED${NC}, ${GREEN}GREEN${NC}, ${YELLOW}YELLOW${NC}, ${CYAN}CYAN${NC}"
            echo ""
            echo "Configuration test:"
            echo "  Repository count: $(get_repo_count)"
            echo "  Script directory: $script_dir"
            echo "  Log file: $LOG_FILE"
            echo "  DRY_RUN mode: $DRY_RUN"
            echo "  VERBOSE mode: $VERBOSE"
            echo ""
            echo "Repository system test:"
            if check_repo_system_health > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓ Repository system ready${NC}"
            else
                echo -e "  ${YELLOW}⚠ Repository system needs initialization${NC}"
            fi
            return 0
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$1'${NC}"
            echo "Use 'git_sh1.sh --help' to see available commands"
            return 1
            ;;
    esac
    
    return $exit_code
}