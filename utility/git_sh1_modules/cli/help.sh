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
    repos                                      List all configured repositories
    test                                       Run system diagnostics (hidden)
    --help, -h [command]                       Show this help or help for specific command
    --install-completion                       Install bash completion system
    --clear-cache                              Clear completion cache
    --version                                  Show version information

${YELLOW}EXAMPLES:${NC}
    # Repository management
    git_sh1.sh repos                          # List repositories
    git_sh1.sh verify all                     # Check all repositories
    git_sh1.sh fetch controller               # Fetch specific repository

    # Worktree operations
    git_sh1.sh worktree add controller -lb local5 -rb origin/master
    git_sh1.sh worktree pull-rebase -repo controller -lb local5
    git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common -repo all -lb unleashed_200.19_openwrt_common

    # Feature workflows
    git_sh1.sh feature create my-feature
    git_sh1.sh feature add my-feature controller
    git_sh1.sh feature switch my-feature

    # Profile management
    git_sh1.sh profile create unleashed_200.19/openwrt_common manifest.xml
    git_sh1.sh profile list
    git_sh1.sh fetch all --profile unleashed_200.19/openwrt_common

${YELLOW}HELP SYSTEM:${NC}
    git_sh1.sh --help                         # General help (this screen)
    git_sh1.sh --help <command>               # Detailed help for specific command
    git_sh1.sh --help examples               # Common usage examples
    git_sh1.sh --help environment            # Environment variables and configuration
    git_sh1.sh --help configuration          # File system layout and storage
    git_sh1.sh --help autocomplete           # Tab completion setup and usage
    git_sh1.sh --help troubleshooting        # Troubleshooting guide

${YELLOW}ENVIRONMENT VARIABLES:${NC}
    DRY_RUN=true         Run in dry-run mode (show commands without executing)
    VERBOSE=true         Enable verbose logging output
    DEBUG=true           Enable debug mode with additional information
    GIT_SH1_DEBUG=1      Enable completion system debugging

${YELLOW}MORE INFORMATION:${NC}
    • Repository map: See 'git_sh1.sh repos' for configured repositories
    • Features: Stored in .git_sh1_features/ directory with metadata
    • Profiles: Stored in .git_sh1_profiles/ directory organized by release
    • Logs: Timestamped files git_sh1_YYYYMMDD_HHMMSS.log in script directory
    • Tab completion: Install with '--install-completion', see '--help autocomplete'
    
    For detailed documentation: git_sh1.sh --help <topic>

EOF
}

# Show help for specific command
show_command_help() {
    local command="$1"
    
    case "$command" in
        fetch|verify)
            cat << EOF
${CYAN}git_sh1.sh $command - Repository ${command} operations${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh $command <repo_name|all> [--profile <profile_name>]

${YELLOW}DESCRIPTION:${NC}
    $(if [[ "$command" == "fetch" ]]; then
        echo "Fetch repository metadata from remote git repositories. This updates"
        echo "    the local git repository information without modifying working files."
    else
        echo "Verify that repositories exist and are properly configured. This checks"
        echo "    local repository paths and basic git repository health."
    fi)

${YELLOW}ARGUMENTS:${NC}
    <repo_name>    Name of specific repository to $command
    all            Process all configured repositories

${YELLOW}OPTIONS:${NC}
    --profile <name>    Use specific profile configuration
    --dry-run          Show commands without executing
    --verbose          Enable verbose output

${YELLOW}EXAMPLES:${NC}
    git_sh1.sh $command all
    git_sh1.sh $command controller
    git_sh1.sh $command controller --profile release-200.17
    git_sh1.sh $command all --profile unleashed_200.19/openwrt_common
EOF
            ;;
        worktree)
            cat << EOF
${CYAN}git_sh1.sh worktree - Manage git worktrees${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh worktree <subcommand> [options] [arguments]

${YELLOW}DESCRIPTION:${NC}
    Manage git worktrees for development workflows. Worktrees allow
    multiple working directories from the same git repository, enabling
    parallel development on different branches.

${YELLOW}SUBCOMMANDS:${NC}
    add             Create new worktree
    pull-rebase     Update and rebase existing worktree
    list            List all worktrees (future implementation)  
    remove          Remove worktree (future implementation)

${YELLOW}ADD USAGE:${NC}
    git_sh1.sh worktree add <repo_name> -lb <local_branch> -rb <remote_branch> [--profile <name>]

${YELLOW}PULL-REBASE USAGE:${NC}
    git_sh1.sh worktree pull-rebase -repo <repo_name> -lb <local_branch> [--profile <name>]

${YELLOW}OPTIONS:${NC}
    -lb <branch>     Local branch name (also used as directory name)
    -rb <branch>     Remote branch name for tracking
    -repo <name>     Repository name (required for pull-rebase)
    --profile <name> Use specific profile configuration
    --dry-run        Show commands without executing
    --verbose        Enable verbose output

${YELLOW}EXAMPLES:${NC}
    # Create worktree for controller repository
    git_sh1.sh worktree add controller -lb local5 -rb origin/master
    
    # Create worktree using profile
    git_sh1.sh worktree add controller -lb unleashed_200.19 -rb origin/unleashed_200.19 --profile unleashed_200.19/openwrt_common
    
    # Update existing worktree
    git_sh1.sh worktree pull-rebase -repo controller -lb local5
    
    # Update with profile
    git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common -repo all -lb unleashed_200.19_openwrt_common

${YELLOW}NOTES:${NC}
    • Worktrees are created in parallel directories to the main repository
    • Profile-based operations process only repositories defined in the profile
    • Use 'repos' command to see available repository names
EOF
            ;;
        feature)
            cat << EOF
${CYAN}git_sh1.sh feature - Manage feature branch workflows${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh feature <subcommand> [arguments]

${YELLOW}DESCRIPTION:${NC}
    Manage feature branch workflows across multiple repositories. Features
    allow coordinated development across repository sets with branch tracking,
    metadata management, and workflow automation.

${YELLOW}SUBCOMMANDS:${NC}
    create <name> [repo...]    Create new feature with optional repositories
    list                       List all features with details
    show <name>                Show comprehensive feature details and status
    switch <name>              Switch all repositories to feature branches
    switchback <name>          Switch back to original branches
    add <name> <repo>          Add repository to existing feature
    pick <name> <commit>       Cherry-pick commits across feature repositories
    comment <name> <text>      Add descriptive comment to feature

${YELLOW}FEATURE LIFECYCLE:${NC}
    1. Create: git_sh1.sh feature create my-feature
    2. Add repositories: git_sh1.sh feature add my-feature controller
    3. Add description: git_sh1.sh feature comment my-feature "Fix authentication bug"
    4. Switch to work: git_sh1.sh feature switch my-feature
    5. View status: git_sh1.sh feature show my-feature

${YELLOW}EXAMPLES:${NC}
    # Create feature and add repository
    git_sh1.sh feature create auth-fix
    git_sh1.sh feature add auth-fix controller
    git_sh1.sh feature add auth-fix dl
    
    # Add description
    git_sh1.sh feature comment auth-fix "Implement OAuth2 authentication flow"
    
    # Switch to feature branches
    git_sh1.sh feature switch auth-fix
    
    # View feature details
    git_sh1.sh feature show auth-fix
    
    # List all features
    git_sh1.sh feature list

${YELLOW}NOTES:${NC}
    • Features are stored in .git_sh1_features directory
    • Each feature tracks repository assignments and branch metadata
    • Use 'show' command to see current branch status for feature repositories
EOF
            ;;
        profile)
            cat << EOF
${CYAN}git_sh1.sh profile - Manage deployment profiles${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh profile <subcommand> [arguments]

${YELLOW}DESCRIPTION:${NC}
    Manage deployment profiles for coordinated multi-repository operations.
    Profiles define repository sets and configurations for specific releases,
    builds, or deployment targets, typically generated from Android manifest files.

${YELLOW}SUBCOMMANDS:${NC}
    create <name> <manifest.xml>   Create profile from Android manifest
    list                           List all available profiles grouped by release
    show <name>                    Show detailed profile information and repositories

${YELLOW}PROFILE STRUCTURE:${NC}
    Profiles are organized as: <release>/<profile_name>
    Example: unleashed_200.19/openwrt_common

${YELLOW}EXAMPLES:${NC}
    # Create profile from manifest
    git_sh1.sh profile create unleashed_200.19/openwrt_common manifest.xml
    
    # List all profiles
    git_sh1.sh profile list
    
    # Show profile contents
    git_sh1.sh profile show unleashed_200.19/openwrt_common
    
    # Use profile in other commands
    git_sh1.sh fetch all --profile unleashed_200.19/openwrt_common
    git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common -repo all -lb unleashed_200.19_openwrt_common

${YELLOW}MANIFEST PARSING:${NC}
    • Extracts project definitions from Android-style manifest.xml
    • Creates repository mappings with remote URLs and branch information
    • Generates JSON metadata for profile operations
    • Supports xmllint parsing with graceful fallback

${YELLOW}INTEGRATION:${NC}
    Profiles integrate with:
    • Repository operations (fetch, verify)
    • Worktree management (profile-specific repository sets)
    • Feature workflows (profile-aware feature operations)

${YELLOW}NOTES:${NC}
    • Profiles are stored in .git_sh1_profiles directory
    • Use 'repos' command to see all available repository names
    • Profile names should follow release/configuration pattern
EOF
            ;;
        repos)
            cat << EOF
${CYAN}git_sh1.sh repos - List configured repositories${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh repos

${YELLOW}DESCRIPTION:${NC}
    Display all configured repositories with their local directory mappings.
    This shows the complete repository map used by the git_sh1 system.

${YELLOW}OUTPUT FORMAT:${NC}
    Each line shows: <repository_name> -> <local_directory_path>

${YELLOW}EXAMPLES:${NC}
    git_sh1.sh repos
    
    # Typical output:
    controller -> controller
    dl -> dl  
    wl -> wl
    kernel -> kernel
    bootloader -> bootloader

${YELLOW}USAGE WITH OTHER COMMANDS:${NC}
    Repository names from this list can be used with:
    • fetch <repo_name>
    • verify <repo_name>  
    • worktree add <repo_name> ...
    • feature add <feature> <repo_name>
EOF
            ;;
        test)
            cat << EOF
${CYAN}git_sh1.sh test - System diagnostic and testing${NC}

${YELLOW}USAGE:${NC}
    git_sh1.sh test

${YELLOW}DESCRIPTION:${NC}
    Run comprehensive system diagnostics to verify the modular git_sh1
    system is working correctly. This includes module loading, configuration
    validation, and system health checks.

${YELLOW}DIAGNOSTIC AREAS:${NC}
    • Module loading verification
    • Color and formatting system  
    • Configuration validation
    • Repository system health
    • File permissions and paths
    • Environment variable status

${YELLOW}EXAMPLE OUTPUT:${NC}
    ✓ Modular system is working!
    
    Core modules loaded successfully:
      - config.sh: Repository map and global variables
      - logging.sh: Logging system and cleanup
      - validation.sh: Input sanitization and path validation
      - utils.sh: Common utilities
    
    Configuration test:
      Repository count: 23
      Script directory: /path/to/utility
      Log file: /path/to/git_sh1_20250724_143022.log

${YELLOW}NOTES:${NC}
    • Use this command to troubleshoot system issues
    • Hidden command - not shown in main help
    • Provides detailed system status information
EOF
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo "Use 'git_sh1.sh --help' for general help"
            return 1
            ;;
    esac
}

# Show usage examples and common workflows
show_usage_examples() {
    cat << EOF
${CYAN}git_sh1.sh - Common Usage Examples${NC}

${YELLOW}REPOSITORY MANAGEMENT:${NC}
    # Verify all repositories exist
    git_sh1.sh verify all
    
    # Fetch metadata for specific repository
    git_sh1.sh fetch controller
    
    # Use profile for targeted operations
    git_sh1.sh fetch all --profile unleashed_200.19/openwrt_common

${YELLOW}WORKTREE WORKFLOWS:${NC}
    # Create development worktree
    git_sh1.sh worktree add controller -lb feature-branch -rb origin/master
    
    # Update existing worktree
    git_sh1.sh worktree pull-rebase -repo controller -lb feature-branch
    
    # Profile-based worktree operations
    git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common -repo all -lb unleashed_200.19_openwrt_common

${YELLOW}FEATURE DEVELOPMENT:${NC}
    # Create and setup feature
    git_sh1.sh feature create auth-improvements
    git_sh1.sh feature add auth-improvements controller
    git_sh1.sh feature add auth-improvements dl
    git_sh1.sh feature comment auth-improvements "OAuth2 implementation"
    
    # Work with feature
    git_sh1.sh feature switch auth-improvements
    # ... do development work ...
    git_sh1.sh feature show auth-improvements
    git_sh1.sh feature switchback auth-improvements

${YELLOW}PROFILE MANAGEMENT:${NC}
    # Create profile from manifest
    git_sh1.sh profile create release-200.20/minimal manifest-minimal.xml
    
    # View profile information
    git_sh1.sh profile list
    git_sh1.sh profile show release-200.20/minimal
    
    # Use profile in workflows
    git_sh1.sh verify all --profile release-200.20/minimal

${YELLOW}SYSTEM UTILITIES:${NC}
    # List all configured repositories
    git_sh1.sh repos
    
    # Install bash completion
    git_sh1.sh --install-completion
    
    # Clear completion cache
    git_sh1.sh --clear-cache
    
    # Test system health
    git_sh1.sh test

${YELLOW}COMMON PATTERNS:${NC}
    # Daily development workflow
    git_sh1.sh verify all                    # Check system health
    git_sh1.sh feature create daily-fixes    # Create work feature
    git_sh1.sh feature add daily-fixes controller dl
    git_sh1.sh feature switch daily-fixes    # Start working
    
    # Release preparation workflow  
    git_sh1.sh profile create release-X.Y manifest.xml
    git_sh1.sh fetch all --profile release-X.Y
    git_sh1.sh worktree add controller -lb release-X.Y -rb origin/release-X.Y --profile release-X.Y

EOF
}

# Show advanced help topics
show_advanced_help() {
    local topic="$1"
    
    case "$topic" in
        environment)
            cat << EOF
${CYAN}git_sh1.sh - Environment Variables${NC}

${YELLOW}RUNTIME CONTROL:${NC}
    DRY_RUN=true        Show commands without executing them
    VERBOSE=true        Enable detailed logging output
    DEBUG=true          Enable debug mode with additional information

${YELLOW}COMPLETION SYSTEM:${NC}
    GIT_SH1_DEBUG=1     Enable completion debugging output
    
${YELLOW}CACHE CONFIGURATION:${NC}
    Cache directory: ~/.cache/git_sh1_modular/
    Cache expiry: 300 seconds (5 minutes)
    
    Files:
    • repositories.cache - Repository name completions
    • features.cache - Feature name completions  
    • profiles.cache - Profile name completions

${YELLOW}USAGE EXAMPLES:${NC}
    # Dry run mode
    DRY_RUN=true git_sh1.sh fetch all
    
    # Verbose logging
    VERBOSE=true git_sh1.sh worktree pull-rebase -repo controller -lb test
    
    # Debug completion issues
    GIT_SH1_DEBUG=1 git_sh1.sh worktree <TAB><TAB>

EOF
            ;;
        configuration)
            cat << EOF
${CYAN}git_sh1.sh - Configuration and Storage${NC}

${YELLOW}DIRECTORY STRUCTURE:${NC}
    .git_sh1_features/          Feature definitions and metadata
    .git_sh1_profiles/          Profile configurations and repository maps
    ~/.cache/git_sh1_modular/   Completion cache files
    
${YELLOW}FEATURE STORAGE:${NC}
    .git_sh1_features/<feature>/
    ├── repos.txt              Repository list for feature
    ├── comment.txt            Feature description
    └── branches.json          Branch metadata and original states

${YELLOW}PROFILE STORAGE:${NC}
    .git_sh1_profiles/<release>/<profile>/
    ├── repo_map.txt           Repository mappings
    ├── metadata.json          Profile configuration
    └── manifest.xml           Original manifest file

${YELLOW}LOGGING:${NC}
    Log files: git_sh1_YYYYMMDD_HHMMSS.log
    Location: Same directory as script
    Content: Timestamped operation log with success/failure status

${YELLOW}REPOSITORY MAP:${NC}
    Configured in: utility/git_sh1_modules/core/config.sh
    Format: repo_map["name"]="local_directory"
    Accessed via: git_sh1.sh repos

EOF
            ;;
        troubleshooting)
            cat << EOF
${CYAN}git_sh1.sh - Troubleshooting Guide${NC}

${YELLOW}COMMON ISSUES:${NC}

${GREEN}1. "Command not found" errors:${NC}
    • Ensure script is executable: chmod +x git_sh1_modular.sh
    • Check script path in PATH or use ./git_sh1_modular.sh
    • Verify all module files exist in git_sh1_modules/

${GREEN}2. "Module loading failed" errors:${NC}
    • Run: git_sh1.sh test
    • Check file permissions on module directories
    • Verify module files are not corrupted

${GREEN}3. Repository operations fail:${NC}
    • Run: git_sh1.sh verify all
    • Check repository paths exist
    • Verify git repositories are properly initialized
    • Ensure SSH keys are configured for remote access

${GREEN}4. Worktree operations fail:${NC}
    • Verify base repository exists
    • Check disk space for worktree creation
    • Ensure branch names are valid
    • Run with VERBOSE=true for detailed output

${GREEN}5. Completion not working:${NC}
    • Install: git_sh1.sh --install-completion
    • Restart shell or source completion file
    • Clear cache: git_sh1.sh --clear-cache
    • Enable debug: GIT_SH1_DEBUG=1

${YELLOW}DIAGNOSTIC COMMANDS:${NC}
    git_sh1.sh test                 # System health check
    git_sh1.sh repos                # List configured repositories
    git_sh1.sh --clear-cache        # Clear completion cache
    VERBOSE=true git_sh1.sh <cmd>   # Detailed operation logging
    DRY_RUN=true git_sh1.sh <cmd>   # Show commands without execution

${YELLOW}LOG ANALYSIS:${NC}
    • Check latest log file: git_sh1_YYYYMMDD_HHMMSS.log
    • Look for ERROR or WARN messages
    • Verify timestamps align with operation attempts
    • Check for permission or path issues

EOF
            ;;
        autocomplete)
            cat << EOF
${CYAN}git_sh1.sh - Tab Completion Setup and Usage${NC}

${YELLOW}INSTALLATION:${NC}

${GREEN}1. Install the completion system:${NC}
    ./git_sh1_main.sh --install-completion
    
    This installs completion files to:
    • /etc/bash_completion.d/ (system-wide)
    • ~/.local/share/bash-completion/completions/ (user-specific)

${GREEN}2. Reload your shell:${NC}
    # Option 1: Restart terminal
    # Option 2: Source completion manually
    source ~/.local/share/bash-completion/completions/git_sh1_main.sh
    # Option 3: Reload bash completion system
    source /etc/bash_completion

${GREEN}3. Test autocomplete:${NC}
    ./git_sh1_main.sh <TAB><TAB>

${YELLOW}AUTOCOMPLETE FEATURES:${NC}

${GREEN}Command Completion:${NC}
    ./git_sh1_main.sh <TAB><TAB>
    Shows: feature, fetch, profile, repos, verify, worktree

${GREEN}Subcommand Completion:${NC}
    ./git_sh1_main.sh feature <TAB><TAB>
    Shows: add, comment, create, list, pick, show, switch

${GREEN}Repository Name Completion:${NC}
    ./git_sh1_main.sh fetch <TAB><TAB>
    Shows: all, controller, dl, opensource, rks_ap, etc.

${GREEN}Feature Name Completion:${NC}
    ./git_sh1_main.sh feature show <TAB><TAB>
    Shows: Available feature names (dynamically loaded)

${GREEN}Profile Completion:${NC}
    ./git_sh1_main.sh --profile <TAB><TAB>
    Shows: Available profile names

${GREEN}Option Completion:${NC}
    ./git_sh1_main.sh feature pick --<TAB><TAB>
    Shows: --dry-run, --profile, -w

${YELLOW}SETUP ALIAS (OPTIONAL):${NC}
    # Add to ~/.bashrc or ~/.bash_profile:
    alias git_sh1='./git_sh1_main.sh'
    
    # Reload shell, then use:
    git_sh1 <TAB><TAB>
    git_sh1 feature <TAB><TAB>

${YELLOW}TROUBLESHOOTING:${NC}

${GREEN}Check Installation:${NC}
    ./git_sh1_main.sh --install-completion
    # Should show: "Completion already installed"

${GREEN}Clear Cache:${NC}
    ./git_sh1_main.sh --clear-cache
    # Refreshes completion cache (5-minute expiry)

${GREEN}Debug Mode:${NC}
    GIT_SH1_DEBUG=1 ./git_sh1_main.sh feature <TAB><TAB>
    # Shows debug output for completion system

${GREEN}Manual Source:${NC}
    # Find completion file:
    find ~/.local/share/bash-completion/completions/ -name "*git_sh1*"
    find /etc/bash_completion.d/ -name "*git_sh1*"
    
    # Source manually:
    source [path_to_completion_file]

${YELLOW}CACHE SYSTEM:${NC}
    • Location: ~/.cache/git_sh1_modular/
    • Duration: 5 minutes auto-refresh
    • Cached items: Repository names, feature names, profile names
    • Performance: Fast completion with intelligent caching

${YELLOW}COMPLETION CONTEXTS:${NC}
    The system provides context-aware completion:
    • Commands show subcommands and global options
    • Repository operations show repository names
    • Feature operations show feature names
    • Profile operations show profile names
    • Worktree operations show branch-specific options

EOF
            ;;
        *)
            echo -e "${RED}Unknown help topic: $topic${NC}"
            echo "Available topics: environment, configuration, autocomplete, troubleshooting"
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