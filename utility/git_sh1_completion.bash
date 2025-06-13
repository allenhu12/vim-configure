#!/bin/bash
# Bash completion for git_sh1.sh script
# 
# Installation:
#   1. Copy this file to your server alongside git_sh1.sh
#   2. Source it in your .bashrc: source /path/to/git_sh1_completion.bash
#   3. Or run: ./install_completion.sh
#
# Usage:
#   ./git_sh1.sh [TAB] - Shows available commands
#   ./git_sh1.sh fetch [TAB] - Shows repository names
#   ./git_sh1.sh feature create [TAB] - Shows flags and options

# Cache files for performance
COMPLETION_CACHE_DIR="${HOME}/.cache/git_sh1"
REPO_CACHE_FILE="${COMPLETION_CACHE_DIR}/repositories.cache"
FEATURE_CACHE_FILE="${COMPLETION_CACHE_DIR}/features.cache"
WORKTREE_CACHE_FILE="${COMPLETION_CACHE_DIR}/worktrees.cache"
BRANCH_CACHE_FILE="${COMPLETION_CACHE_DIR}/branches.cache"
CACHE_EXPIRY=300  # 5 minutes

# Ensure cache directory exists
mkdir -p "${COMPLETION_CACHE_DIR}"

# Utility functions
_git_sh1_debug() {
    if [[ "${GIT_SH1_DEBUG:-}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

_git_sh1_find_script() {
    local script_path=""
    
    # Try to find git_sh1.sh in common locations
    if [[ -x "./git_sh1.sh" ]]; then
        script_path="./git_sh1.sh"
    elif [[ -x "$(dirname "${BASH_SOURCE[0]}")/git_sh1.sh" ]]; then
        script_path="$(dirname "${BASH_SOURCE[0]}")/git_sh1.sh"
    elif command -v git_sh1.sh >/dev/null 2>&1; then
        script_path="git_sh1.sh"
    fi
    
    echo "$script_path"
}

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

# Get repository names from script's repo_map
_git_sh1_get_repositories() {
    if _git_sh1_is_cache_valid "$REPO_CACHE_FILE"; then
        cat "$REPO_CACHE_FILE" 2>/dev/null
        return 0
    fi
    
    local script_path=$(_git_sh1_find_script)
    if [[ -z "$script_path" ]]; then
        echo "all"
        return 0
    fi
    
    {
        echo "all"
        # Extract repository names from repo_map variable in the script
        grep -A 100 'repo_map=' "$script_path" | \
        grep -E '^\s*[a-zA-Z0-9_-]+:' | \
        sed 's/^[[:space:]]*//' | \
        cut -d':' -f1 | \
        grep -v '^$' | \
        head -50  # Limit to reasonable number
    } | sort -u > "$REPO_CACHE_FILE" 2>/dev/null
    
    cat "$REPO_CACHE_FILE" 2>/dev/null || echo "all"
}

# Get existing feature names
_git_sh1_get_features() {
    if _git_sh1_is_cache_valid "$FEATURE_CACHE_FILE"; then
        cat "$FEATURE_CACHE_FILE" 2>/dev/null
        return 0
    fi
    
    local script_path=$(_git_sh1_find_script)
    if [[ -z "$script_path" ]]; then
        return 0
    fi
    
    local script_dir=$(dirname "$script_path")
    local features_dir="${script_dir}/.git_sh1_features"
    
    if [[ -d "$features_dir" ]]; then
        find "$features_dir" -maxdepth 1 -type d ! -name ".*" -exec basename {} \; 2>/dev/null | \
        grep -v "^\\.$" | sort > "$FEATURE_CACHE_FILE" 2>/dev/null
    else
        touch "$FEATURE_CACHE_FILE"
    fi
    
    cat "$FEATURE_CACHE_FILE" 2>/dev/null
}

# Get existing worktree names
_git_sh1_get_worktrees() {
    if _git_sh1_is_cache_valid "$WORKTREE_CACHE_FILE"; then
        cat "$WORKTREE_CACHE_FILE" 2>/dev/null
        return 0
    fi
    
    local script_path=$(_git_sh1_find_script)
    if [[ -z "$script_path" ]]; then
        return 0
    fi
    
    local script_dir=$(dirname "$script_path")
    
    # Try to find worktree directories by looking for git-depot structure
    {
        # Look for directories that might be worktrees
        find "$script_dir/.." -maxdepth 2 -type d -name "*" 2>/dev/null | \
        while read -r dir; do
            if [[ -d "$dir" ]] && [[ "$(basename "$dir")" != ".*" ]] && [[ "$(basename "$dir")" != "git-depot" ]]; then
                # Check if it contains git worktrees
                if find "$dir" -maxdepth 2 -name ".git" -type f 2>/dev/null | head -1 | grep -q ".git"; then
                    basename "$dir"
                fi
            fi
        done
        
        # Also suggest common worktree names
        echo "master"
        echo "develop" 
        echo "main"
        echo "local"
    } | sort -u > "$WORKTREE_CACHE_FILE" 2>/dev/null
    
    cat "$WORKTREE_CACHE_FILE" 2>/dev/null
}

# Get git branches for a repository
_git_sh1_get_branches() {
    local repo_name="$1"
    local branch_type="${2:-remote}"  # remote or local
    
    if _git_sh1_is_cache_valid "$BRANCH_CACHE_FILE"; then
        grep "^${repo_name}:${branch_type}:" "$BRANCH_CACHE_FILE" 2>/dev/null | cut -d':' -f3-
        return 0
    fi
    
    local script_path=$(_git_sh1_find_script)
    if [[ -z "$script_path" ]]; then
        return 0
    fi
    
    # This is a placeholder - in practice, you'd need to access the actual git repo
    # For now, provide common branch names
    {
        if [[ "$branch_type" == "remote" ]]; then
            echo "${repo_name}:remote:origin/master"
            echo "${repo_name}:remote:origin/main" 
            echo "${repo_name}:remote:origin/develop"
            echo "${repo_name}:remote:origin/release/latest"
        else
            echo "${repo_name}:local:master"
            echo "${repo_name}:local:main"
            echo "${repo_name}:local:develop"
            echo "${repo_name}:local:local"
        fi
    } >> "$BRANCH_CACHE_FILE" 2>/dev/null
    
    grep "^${repo_name}:${branch_type}:" "$BRANCH_CACHE_FILE" 2>/dev/null | cut -d':' -f3-
}

# Clear completion cache
_git_sh1_clear_cache() {
    rm -f "$REPO_CACHE_FILE" "$FEATURE_CACHE_FILE" "$WORKTREE_CACHE_FILE" "$BRANCH_CACHE_FILE" 2>/dev/null
    echo "Git SH1 completion cache cleared"
}

# Main completion function
_git_sh1_completion() {
    local cur prev words cword
    
    # Initialize completion variables (compatible with both bash and zsh)
    if declare -F _init_completion >/dev/null 2>&1; then
        # Use bash-completion's _init_completion if available
        _init_completion || return
    else
        # Fallback for environments without bash-completion or zsh
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi
    
    _git_sh1_debug "COMP_WORDS: ${COMP_WORDS[*]}"
    _git_sh1_debug "COMP_CWORD: $COMP_CWORD"
    _git_sh1_debug "cur: '$cur', prev: '$prev'"
    
    # Handle completion cache refresh
    if [[ "$cur" == "--clear-cache" ]]; then
        _git_sh1_clear_cache
        return 0
    fi
    
    local script_name="${COMP_WORDS[0]}"
    
    # Main commands completion
    if [[ $COMP_CWORD -eq 1 ]]; then
        local commands="verify fetch worktree show_repos feature -h --help --clear-cache --install-completion"
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return 0
    fi
    
    local command="${COMP_WORDS[1]}"
    
    case "$command" in
        verify|fetch)
            if [[ $COMP_CWORD -eq 2 ]]; then
                local repos=$(_git_sh1_get_repositories)
                COMPREPLY=($(compgen -W "$repos" -- "$cur"))
            fi
            ;;
            
        worktree)
            if [[ $COMP_CWORD -eq 2 ]]; then
                COMPREPLY=($(compgen -W "add pull-rebase" -- "$cur"))
            elif [[ $COMP_CWORD -eq 3 ]] && [[ "${COMP_WORDS[2]}" == "add" || "${COMP_WORDS[2]}" == "pull-rebase" ]]; then
                local repos=$(_git_sh1_get_repositories)
                COMPREPLY=($(compgen -W "$repos" -- "$cur"))
            elif [[ "${COMP_WORDS[2]}" == "add" ]]; then
                case "$prev" in
                    -lb)
                        # Local branch name - let user type
                        COMPREPLY=()
                        ;;
                    -rb)
                        # Remote branch completion
                        local repo_name="${COMP_WORDS[3]}"
                        if [[ -n "$repo_name" ]]; then
                            local branches=$(_git_sh1_get_branches "$repo_name" "remote")
                            COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                        fi
                        ;;
                    *)
                        if [[ "$cur" != -* ]]; then
                            COMPREPLY=($(compgen -W "-lb -rb" -- "$cur"))
                        fi
                        ;;
                esac
            elif [[ "${COMP_WORDS[2]}" == "pull-rebase" ]] && [[ $COMP_CWORD -eq 4 ]]; then
                # Worktree name for pull-rebase
                local worktrees=$(_git_sh1_get_worktrees)
                COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
            fi
            ;;
            
        feature)
            if [[ $COMP_CWORD -eq 2 ]]; then
                COMPREPLY=($(compgen -W "create list show comment switch switchback pick" -- "$cur"))
            else
                local subcommand="${COMP_WORDS[2]}"
                case "$subcommand" in
                    create)
                        case "$prev" in
                            -w)
                                local worktrees=$(_git_sh1_get_worktrees)
                                COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
                                ;;
                            *)
                                if [[ "$cur" == -* ]]; then
                                    COMPREPLY=($(compgen -W "-w --force" -- "$cur"))
                                else
                                    # After feature name, suggest repositories
                                    local has_feature_name=false
                                    local has_w_flag=false
                                    for ((i=3; i<COMP_CWORD; i++)); do
                                        if [[ "${COMP_WORDS[i]}" != -* ]] && [[ "${COMP_WORDS[i-1]}" != "-w" ]]; then
                                            has_feature_name=true
                                            break
                                        fi
                                        if [[ "${COMP_WORDS[i]}" == "-w" ]]; then
                                            has_w_flag=true
                                        fi
                                    done
                                    
                                    if [[ "$has_feature_name" == true ]]; then
                                        local repos=$(_git_sh1_get_repositories)
                                        # Remove 'all' from suggestions for feature create
                                        repos=$(echo "$repos" | grep -v "^all$")
                                        COMPREPLY=($(compgen -W "$repos" -- "$cur"))
                                    fi
                                fi
                                ;;
                        esac
                        ;;
                        
                    show|switch|switchback|comment)
                        if [[ "$prev" == "-w" ]]; then
                            local worktrees=$(_git_sh1_get_worktrees)
                            COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
                        elif [[ "$cur" == -* ]]; then
                            COMPREPLY=($(compgen -W "-w" -- "$cur"))
                        else
                            # Complete with existing feature names
                            local need_feature_name=true
                            for ((i=3; i<COMP_CWORD; i++)); do
                                if [[ "${COMP_WORDS[i]}" != -* ]] && [[ "${COMP_WORDS[i-1]}" != "-w" ]]; then
                                    need_feature_name=false
                                    break
                                fi
                            done
                            
                            if [[ "$need_feature_name" == true ]]; then
                                local features=$(_git_sh1_get_features)
                                COMPREPLY=($(compgen -W "$features" -- "$cur"))
                            fi
                        fi
                        ;;
                        
                    pick)
                        case "$prev" in
                            -w)
                                local worktrees=$(_git_sh1_get_worktrees)
                                COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
                                ;;
                            *)
                                if [[ "$cur" == -* ]]; then
                                    COMPREPLY=($(compgen -W "-w --dry-run" -- "$cur"))
                                else
                                    # Need feature name first, then target branch
                                    local has_feature_name=false
                                    for ((i=3; i<COMP_CWORD; i++)); do
                                        if [[ "${COMP_WORDS[i]}" != -* ]] && [[ "${COMP_WORDS[i-1]}" != "-w" ]]; then
                                            if [[ "$has_feature_name" == false ]]; then
                                                has_feature_name=true
                                            else
                                                # Already have feature name, this should be target branch
                                                COMPREPLY=($(compgen -W "master main develop release" -- "$cur"))
                                                return 0
                                            fi
                                        fi
                                    done
                                    
                                    if [[ "$has_feature_name" == false ]]; then
                                        local features=$(_git_sh1_get_features)
                                        COMPREPLY=($(compgen -W "$features" -- "$cur"))
                                    fi
                                fi
                                ;;
                        esac
                        ;;
                esac
            fi
            ;;
            
        show_repos)
            # No additional completion needed
            COMPREPLY=()
            ;;
            
        -h|--help)
            # No additional completion needed
            COMPREPLY=()
            ;;
            
        *)
            # Unknown command
            COMPREPLY=()
            ;;
    esac
}

# Register the completion function
# Check if we're in bash or zsh and register appropriately
if [[ -n "$BASH_VERSION" ]]; then
    # Bash completion
    complete -F _git_sh1_completion git_sh1.sh
    complete -F _git_sh1_completion ./git_sh1.sh
    
    # If script is being sourced, also try to complete for the script in current directory
    if [[ -x "./git_sh1.sh" ]]; then
        complete -F _git_sh1_completion ./git_sh1.sh
    fi
elif [[ -n "$ZSH_VERSION" ]]; then
    # Zsh completion - ensure bashcompinit is loaded
    if ! command -v bashcompinit >/dev/null 2>&1; then
        autoload -U +X bashcompinit && bashcompinit 2>/dev/null
    fi
    
    # Register with bash-style completion in zsh
    complete -F _git_sh1_completion git_sh1.sh 2>/dev/null
    complete -F _git_sh1_completion ./git_sh1.sh 2>/dev/null
else
    echo "Warning: Unsupported shell. Completion may not work properly."
fi

# Export functions for debugging
if [[ "${GIT_SH1_DEBUG:-}" == "1" ]]; then
    export -f _git_sh1_debug _git_sh1_get_repositories _git_sh1_get_features _git_sh1_get_worktrees _git_sh1_clear_cache
fi

echo "Git SH1 bash completion loaded. Use 'GIT_SH1_DEBUG=1' for debug output."