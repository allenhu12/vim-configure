#!/bin/bash

# cli/completion.sh - Advanced bash completion system for git_sh1_modules
# Depends on: core/config.sh (for repo_map and colors)

# Cache configuration
COMPLETION_CACHE_DIR="${HOME}/.cache/git_sh1_modular"
REPO_CACHE_FILE="${COMPLETION_CACHE_DIR}/repositories.cache"
FEATURE_CACHE_FILE="${COMPLETION_CACHE_DIR}/features.cache"
PROFILE_CACHE_FILE="${COMPLETION_CACHE_DIR}/profiles.cache"
WORKTREE_CACHE_FILE="${COMPLETION_CACHE_DIR}/worktrees.cache"
CACHE_EXPIRY=300

# Ensure cache directory exists
create_completion_cache_dir() {
    mkdir -p "${COMPLETION_CACHE_DIR}"
}

# Debug function
_git_sh1_debug() {
    if [[ "${GIT_SH1_DEBUG:-}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Find modular script path
_git_sh1_find_script() {
    local script_path=""
    if [[ -x "./git_sh1_modular.sh" ]]; then
        script_path="./git_sh1_modular.sh"
    elif [[ -x "$(dirname "${BASH_SOURCE[0]}")/../git_sh1_modular.sh" ]]; then
        script_path="$(dirname "${BASH_SOURCE[0]}")/../git_sh1_modular.sh"
    elif command -v git_sh1_modular.sh >/dev/null 2>&1; then
        script_path="git_sh1_modular.sh"
    fi
    echo "$script_path"
}

# Cache validation
_git_sh1_is_cache_valid() {
    local cache_file="$1"
    local max_age="${2:-$CACHE_EXPIRY}"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local age=$((current_time - cache_time))
    
    [[ $age -lt $max_age ]]
}

# Get repository names from cache or generate fresh
_git_sh1_get_repos() {
    create_completion_cache_dir
    
    if _git_sh1_is_cache_valid "$REPO_CACHE_FILE"; then
        cat "$REPO_CACHE_FILE" 2>/dev/null
        return 0
    fi
    
    # Generate fresh repository list
    local script_path=$(_git_sh1_find_script)
    if [[ -n "$script_path" ]]; then
        # Extract repository names from the modular system
        "$script_path" repos 2>/dev/null | grep -E "^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*->" | \
        sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*->.*$//' > "$REPO_CACHE_FILE" 2>/dev/null
    fi
    
    # Fallback: common repository names
    if [[ ! -s "$REPO_CACHE_FILE" ]]; then
        echo -e "controller\ndl\nwl\nkernel\nbootloader\nall" > "$REPO_CACHE_FILE"
    fi
    
    cat "$REPO_CACHE_FILE" 2>/dev/null
}

# Get feature names from cache or generate fresh
_git_sh1_get_features() {
    create_completion_cache_dir
    
    if _git_sh1_is_cache_valid "$FEATURE_CACHE_FILE"; then
        cat "$FEATURE_CACHE_FILE" 2>/dev/null
        return 0
    fi
    
    # Generate fresh feature list from .git_sh1_features directory
    local features_dir=".git_sh1_features"
    if [[ -d "$features_dir" ]]; then
        find "$features_dir" -maxdepth 1 -type d -not -path "$features_dir" | \
        sed "s|^$features_dir/||" > "$FEATURE_CACHE_FILE" 2>/dev/null
    else
        touch "$FEATURE_CACHE_FILE"
    fi
    
    cat "$FEATURE_CACHE_FILE" 2>/dev/null
}

# Get profile names from cache or generate fresh  
_git_sh1_get_profiles() {
    create_completion_cache_dir
    
    if _git_sh1_is_cache_valid "$PROFILE_CACHE_FILE"; then
        cat "$PROFILE_CACHE_FILE" 2>/dev/null
        return 0
    fi
    
    # Generate fresh profile list
    local script_path=$(_git_sh1_find_script)
    if [[ -n "$script_path" ]]; then
        "$script_path" profile list 2>/dev/null | grep -E "^[[:space:]]*[a-zA-Z0-9_/-]+:" | \
        sed 's/^[[:space:]]*//' | sed 's/:.*$//' > "$PROFILE_CACHE_FILE" 2>/dev/null
    fi
    
    if [[ ! -s "$PROFILE_CACHE_FILE" ]]; then
        touch "$PROFILE_CACHE_FILE"
    fi
    
    cat "$PROFILE_CACHE_FILE" 2>/dev/null
}

# Clear completion cache
_git_sh1_clear_cache() {
    if [[ -d "$COMPLETION_CACHE_DIR" ]]; then
        rm -f "$REPO_CACHE_FILE" "$FEATURE_CACHE_FILE" "$PROFILE_CACHE_FILE" "$WORKTREE_CACHE_FILE"
        echo "Completion cache cleared"
    fi
}

# Install completion system
_git_sh1_install_completion() {
    local completion_file=""
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    # Function to test write permissions
    test_write_permission() {
        local test_file="$1/.git_sh1_test_$$"
        if touch "$test_file" 2>/dev/null; then
            rm -f "$test_file" 2>/dev/null
            return 0
        else
            return 1
        fi
    }
    
    # Determine completion installation location with permission checking
    if [[ -d ~/.bash_completion.d ]] && test_write_permission ~/.bash_completion.d; then
        completion_file=~/.bash_completion.d/git_sh1_modular
    elif [[ -d ~/.local/share/bash-completion/completions ]] && test_write_permission ~/.local/share/bash-completion/completions; then
        completion_file=~/.local/share/bash-completion/completions/git_sh1_modular
    elif [[ -d /usr/local/etc/bash_completion.d ]] && test_write_permission /usr/local/etc/bash_completion.d; then
        completion_file=/usr/local/etc/bash_completion.d/git_sh1_modular
    elif [[ -d /etc/bash_completion.d ]] && test_write_permission /etc/bash_completion.d; then
        completion_file=/etc/bash_completion.d/git_sh1_modular
    else
        # Fallback: create user-specific completion directory
        mkdir -p ~/.local/share/bash-completion/completions 2>/dev/null || mkdir -p ~/.bash_completion.d 2>/dev/null
        if [[ -d ~/.local/share/bash-completion/completions ]]; then
            completion_file=~/.local/share/bash-completion/completions/git_sh1_modular
        elif [[ -d ~/.bash_completion.d ]]; then
            completion_file=~/.bash_completion.d/git_sh1_modular
        else
            completion_file=~/.git_sh1_modular_completion
        fi
    fi
    
    # Create completion script with absolute path
    if cat > "$completion_file" << EOF
#!/bin/bash
# Auto-generated completion for git_sh1_modular.sh

# Source the modular completion system with absolute path
if [[ -f "${script_dir}/cli/completion.sh" ]]; then
    source "${script_dir}/cli/completion.sh"
    
    # Register completion for various script names  
    complete -F _git_sh1_modular_completion git_sh1_modular.sh 2>/dev/null
    complete -F _git_sh1_modular_completion ./git_sh1_modular.sh 2>/dev/null
    complete -F _git_sh1_modular_completion git_sh1_main.sh 2>/dev/null
    complete -F _git_sh1_modular_completion ./git_sh1_main.sh 2>/dev/null
    
    # Also register for git_sh1.sh if used as legacy
    complete -F _git_sh1_modular_completion git_sh1.sh 2>/dev/null
    complete -F _git_sh1_modular_completion ./git_sh1.sh 2>/dev/null
fi
EOF
    then
        echo -e "${GREEN}✓ Completion installed to: $completion_file${NC}"
        echo -e "Restart your shell or run: ${CYAN}source $completion_file${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to write completion file: $completion_file${NC}"
        echo -e "${YELLOW}Try running with sudo for system-wide installation, or check permissions${NC}"
        return 1
    fi
}

# Main completion function for modular system
_git_sh1_modular_completion() {
    local cur prev words cword
    
    # Always use bash-style completion variables
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cword=$COMP_CWORD
    
    _git_sh1_debug "COMP_WORDS: ${COMP_WORDS[*]}"
    _git_sh1_debug "COMP_CWORD: $COMP_CWORD"
    _git_sh1_debug "cur: '$cur', prev: '$prev'"
    
    # Handle cache clearing
    if [[ "$cur" == "--clear-cache" ]]; then
        _git_sh1_clear_cache
        return 0
    fi
    
    # Main commands completion
    if [[ $cword -eq 1 ]]; then
        local commands="verify fetch worktree repos feature profile test -h --help --clear-cache --install-completion --version"
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        _git_sh1_debug "Level 1 completion: ${COMPREPLY[*]}"
        return 0
    fi
    
    local command="${COMP_WORDS[1]}"
    _git_sh1_debug "Command: $command, Level: $cword"
    
    case "$command" in
        verify|fetch)
            if [[ $cword -eq 2 ]]; then
                # At position 2, offer both repositories and --profile option
                local repos=$(_git_sh1_get_repos)
                local options="--profile"
                COMPREPLY=($(compgen -W "$repos $options" -- "$cur"))
            elif [[ "$prev" == "--profile" ]]; then
                # After --profile, offer profile names
                local profiles=$(_git_sh1_get_profiles)
                COMPREPLY=($(compgen -W "$profiles" -- "$cur"))
            elif [[ $cword -eq 3 && "${COMP_WORDS[2]}" != "--profile" ]]; then
                # After repository name, offer --profile option
                COMPREPLY=($(compgen -W "--profile" -- "$cur"))
            elif [[ $cword -eq 4 && "${COMP_WORDS[2]}" == "--profile" ]]; then
                # After --profile <profile_name>, offer repositories
                local repos=$(_git_sh1_get_repos)
                COMPREPLY=($(compgen -W "$repos" -- "$cur"))
            fi
            ;;
            
        worktree)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "add pull-rebase list remove" -- "$cur"))
            elif [[ $cword -gt 2 ]]; then
                case "${COMP_WORDS[2]}" in
                    add)
                        if [[ "$prev" == "-lb" || "$prev" == "-rb" ]]; then
                            # Branch name completion (could be enhanced)
                            COMPREPLY=()
                        elif [[ "$prev" == "--profile" ]]; then
                            # After --profile, offer profile names
                            local profiles=$(_git_sh1_get_profiles)
                            COMPREPLY=($(compgen -W "$profiles" -- "$cur"))
                        elif [[ $cword -eq 3 ]]; then
                            # At position 3, offer repositories AND --profile option
                            local repos=$(_git_sh1_get_repos)
                            local options="--profile"
                            COMPREPLY=($(compgen -W "$repos $options" -- "$cur"))
                        else
                            # For other positions, offer all available options
                            COMPREPLY=($(compgen -W "-lb -rb --profile" -- "$cur"))
                        fi
                        ;;
                    pull-rebase)
                        if [[ "$prev" == "-repo" ]]; then
                            local repos=$(_git_sh1_get_repos)
                            COMPREPLY=($(compgen -W "$repos" -- "$cur"))
                        elif [[ "$prev" == "-lb" ]]; then
                            # Branch name completion
                            COMPREPLY=()
                        elif [[ "$prev" == "--profile" ]]; then
                            local profiles=$(_git_sh1_get_profiles)
                            COMPREPLY=($(compgen -W "$profiles" -- "$cur"))
                        else
                            COMPREPLY=($(compgen -W "-repo -lb --profile" -- "$cur"))
                        fi
                        ;;
                esac
            fi
            ;;
            
        feature)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "create list show switch switchback add pick comment" -- "$cur"))
            elif [[ $cword -gt 2 ]]; then
                case "${COMP_WORDS[2]}" in
                    create)
                        # Feature name completion - no suggestions
                        COMPREPLY=()
                        ;;
                    show|switch|switchback|comment)
                        if [[ $cword -eq 3 ]]; then
                            local features=$(_git_sh1_get_features)
                            COMPREPLY=($(compgen -W "$features" -- "$cur"))
                        fi
                        ;;
                    add)
                        if [[ $cword -eq 3 ]]; then
                            local features=$(_git_sh1_get_features)
                            COMPREPLY=($(compgen -W "$features" -- "$cur"))
                        elif [[ $cword -eq 4 ]]; then
                            local repos=$(_git_sh1_get_repos)
                            COMPREPLY=($(compgen -W "$repos" -- "$cur"))
                        fi
                        ;;
                esac
            fi
            ;;
            
        profile)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "create list show" -- "$cur"))
            elif [[ $cword -gt 2 ]]; then
                case "${COMP_WORDS[2]}" in
                    create)
                        if [[ $cword -eq 4 ]]; then
                            # Complete .xml files
                            COMPREPLY=($(compgen -f -X '!*.xml' -- "$cur"))
                        fi
                        ;;
                    show)
                        if [[ $cword -eq 3 ]]; then
                            local profiles=$(_git_sh1_get_profiles)
                            COMPREPLY=($(compgen -W "$profiles" -- "$cur"))
                        fi
                        ;;
                esac
            fi
            ;;
            
        *)
            COMPREPLY=()
            ;;
    esac
    
    _git_sh1_debug "Final COMPREPLY: ${COMPREPLY[*]:0:10}..."
}

# Completion system setup
setup_git_sh1_completion() {
    create_completion_cache_dir
    
    # Register completion for both script names
    complete -F _git_sh1_modular_completion git_sh1_modular.sh 2>/dev/null
    complete -F _git_sh1_modular_completion ./git_sh1_modular.sh 2>/dev/null
    
    # Also handle the main entry point if it exists
    if command -v git_sh1_main.sh >/dev/null 2>&1; then
        complete -F _git_sh1_modular_completion git_sh1_main.sh 2>/dev/null
        complete -F _git_sh1_modular_completion ./git_sh1_main.sh 2>/dev/null
    fi
}