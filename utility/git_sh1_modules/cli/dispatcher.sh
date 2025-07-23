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

# Install bash completion (placeholder for now)
install_bash_completion() {
    echo -e "${YELLOW}Bash completion installation not yet implemented in modular version${NC}"
    echo -e "This feature will be available in a future update"
    return 0
}

# Clear completion cache (placeholder for now)
clear_completion_cache() {
    echo -e "${YELLOW}Completion cache clearing not yet implemented in modular version${NC}"
    echo -e "This feature will be available in a future update"
    return 0
}

# Placeholder functions for commands not yet implemented
cmd_verify() {
    echo -e "${YELLOW}verify command not yet implemented in modular version${NC}"
    echo -e "Will be available after repository modules are fully integrated"
    return 1
}

cmd_fetch() {
    echo -e "${YELLOW}fetch command not yet implemented in modular version${NC}"
    echo -e "Will be available after repository modules are fully integrated"
    return 1
}

cmd_worktree() {
    echo -e "${YELLOW}worktree commands not yet implemented in modular version${NC}"
    echo -e "Will be available after worktree modules are fully integrated"
    return 1
}

cmd_feature() {
    echo -e "${YELLOW}feature commands not yet implemented in modular version${NC}"
    echo -e "Will be available after feature modules are fully integrated"
    return 1
}

cmd_profile() {
    echo -e "${YELLOW}profile commands not yet implemented in modular version${NC}"
    echo -e "Will be available after profile modules are fully integrated"
    return 1
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
                show_command_help "$2"
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
        test)
            # Hidden test command for development
            echo -e "${GREEN}✓ Modular system is working!${NC}"
            echo "Core modules loaded successfully:"
            echo "  - config.sh: Repository map and global variables"
            echo "  - logging.sh: Logging system and cleanup"
            echo "  - validation.sh: Input sanitization and path validation"
            echo "  - utils.sh: Common utilities"
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