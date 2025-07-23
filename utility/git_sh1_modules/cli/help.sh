#!/bin/bash

# cli/help.sh - Help system for git_sh1_modules
# Depends on: core/config.sh (for colors)

# Display main help information
show_help() {
    cat << EOF
${CYAN}git_sh1.sh - Git Repository Management Tool${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh <command> [options] [arguments]

${YELLOW}AVAILABLE COMMANDS:${NC}

${GREEN}Repository Management:${NC}
    fetch <repo_name|all> [--profile <name>]   Fetch repository metadata
    verify <repo_name|all>                     Verify repositories exist

${GREEN}Worktree Operations:${NC}
    worktree add <repo_name> -lb <local_branch> -rb <remote_branch>
                                               Add worktree for repository
    worktree pull-rebase -repo <repo_name> -lb <local_branch>
                                               Pull and rebase worktree

${GREEN}Feature Management:${NC}
    feature create <feature_name>             Create new feature branch set
    feature list                              List all features
    feature show <feature_name>               Show feature details
    feature switch <feature_name>             Switch to feature branches
    feature switchback <feature_name>         Switch back to original branches
    feature add <feature_name> <repo_name>    Add repository to feature
    feature pick <feature_name> <commit_id>   Cherry-pick commits
    feature comment <feature_name> <comment>  Add comment to feature

${GREEN}Profile Management:${NC}
    profile create <profile_name> <manifest.xml>  Create profile from manifest
    profile list                                   List all profiles
    profile show <profile_name>                    Show profile details

${GREEN}Utility Commands:${NC}
    --help, -h                                 Show this help
    --install-completion                       Install bash completion
    --clear-cache                              Clear completion cache

${YELLOW}EXAMPLES:${NC}
    # Fetch all repositories
    git_sh1.sh fetch all

    # Add worktree for controller
    git_sh1.sh worktree add controller -lb local5 -rb origin/master

    # Create and work with features
    git_sh1.sh feature create my-feature
    git_sh1.sh feature add my-feature controller
    git_sh1.sh feature switch my-feature

    # Create profile from manifest
    git_sh1.sh profile create release-200.17 manifest.xml

${YELLOW}ENVIRONMENT VARIABLES:${NC}
    DRY_RUN=true      Run in dry-run mode (show commands without executing)
    VERBOSE=true      Enable verbose logging output

${YELLOW}MORE INFORMATION:${NC}
    Repository map configuration is stored in the script configuration.
    Features and profiles are stored in .git_sh1_features and .git_sh1_profiles
    directories respectively.

EOF
}

# Show help for specific command
show_command_help() {
    local command="$1"
    
    case "$command" in
        fetch)
            cat << EOF
${CYAN}git_sh1.sh fetch - Fetch repository metadata${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh fetch <repo_name|all> [--profile <profile_name>]

${YELLOW}DESCRIPTION:${NC}
    Fetch repository metadata from remote git repositories. This updates
    the local git repository information without modifying working files.

${YELLOW}ARGUMENTS:${NC}
    <repo_name>    Name of specific repository to fetch
    all            Fetch all configured repositories

${YELLOW}OPTIONS:${NC}
    --profile <name>    Use specific profile configuration

${YELLOW}EXAMPLES:${NC}
    git_sh1.sh fetch all
    git_sh1.sh fetch controller
    git_sh1.sh fetch controller --profile release-200.17
EOF
            ;;
        worktree)
            cat << EOF
${CYAN}git_sh1.sh worktree - Manage git worktrees${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh worktree add <repo_name> -lb <local_branch> -rb <remote_branch>
    git_sh1.sh worktree pull-rebase -repo <repo_name> -lb <local_branch>

${YELLOW}DESCRIPTION:${NC}
    Manage git worktrees for development workflows. Worktrees allow
    multiple working directories from the same git repository.

${YELLOW}COMMANDS:${NC}
    add             Create new worktree
    pull-rebase     Update and rebase existing worktree

${YELLOW}OPTIONS:${NC}
    -lb <branch>    Local branch name (directory name)
    -rb <branch>    Remote branch name
    -repo <name>    Repository name

${YELLOW}EXAMPLES:${NC}
    git_sh1.sh worktree add controller -lb local5 -rb origin/master
    git_sh1.sh worktree pull-rebase -repo controller -lb local5
EOF
            ;;
        feature)
            cat << EOF
${CYAN}git_sh1.sh feature - Manage feature branch workflows${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh feature <subcommand> [arguments]

${YELLOW}SUBCOMMANDS:${NC}
    create <name>              Create new feature
    list                       List all features
    show <name>                Show feature details
    switch <name>              Switch to feature branches
    switchback <name>          Switch back to original branches
    add <name> <repo>          Add repository to feature
    pick <name> <commit>       Cherry-pick commits
    comment <name> <text>      Add comment

${YELLOW}EXAMPLES:${NC}
    git_sh1.sh feature create my-feature
    git_sh1.sh feature add my-feature controller
    git_sh1.sh feature switch my-feature
EOF
            ;;
        profile)
            cat << EOF
${CYAN}git_sh1.sh profile - Manage deployment profiles${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh profile <subcommand> [arguments]

${YELLOW}SUBCOMMANDS:${NC}
    create <name> <manifest>   Create profile from Android manifest
    list                       List all profiles
    show <name>                Show profile details

${YELLOW}EXAMPLES:${NC}
    git_sh1.sh profile create release-200.17 manifest.xml
    git_sh1.sh profile list
    git_sh1.sh profile show release-200.17
EOF
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo "Use 'git_sh1.sh --help' for general help"
            return 1
            ;;
    esac
}

# Show version information
show_version() {
    echo -e "${CYAN}git_sh1.sh (modular version)${NC}"
    echo -e "Git repository management tool"
    echo -e "Refactored into modular components for better maintainability"
}