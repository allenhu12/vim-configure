#!/bin/bash
# Final working Git SH1 completion for zsh with Oh My Zsh
# This version correctly handles bash completion variables in zsh

# Cache configuration
COMPLETION_CACHE_DIR="${HOME}/.cache/git_sh1"
REPO_CACHE_FILE="${COMPLETION_CACHE_DIR}/repositories.cache"
FEATURE_CACHE_FILE="${COMPLETION_CACHE_DIR}/features.cache"
WORKTREE_CACHE_FILE="${COMPLETION_CACHE_DIR}/worktrees.cache"
CACHE_EXPIRY=300

# Ensure cache directory exists
mkdir -p "${COMPLETION_CACHE_DIR}"

# Debug function
_git_sh1_debug() {
    if [[ "${GIT_SH1_DEBUG:-}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Find script
_git_sh1_find_script() {
    local script_path=""
    if [[ -x "./git_sh1.sh" ]]; then
        script_path="./git_sh1.sh"
    elif [[ -x "$(dirname "${BASH_SOURCE[0]}")/git_sh1.sh" ]]; then
        script_path="$(dirname "${BASH_SOURCE[0]}")/git_sh1.sh"
    elif command -v git_sh1.sh >/dev/null 2>&1; then
        script_path="git_sh1.sh"
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

# Get repositories
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
        grep -A 100 'repo_map=' "$script_path" 2>/dev/null | \
        grep -E '^\s*[a-zA-Z0-9_-]+:' | \
        sed 's/^[[:space:]]*//' | \
        cut -d':' -f1 | \
        grep -v '^$' | \
        head -50
    } | sort -u > "$REPO_CACHE_FILE" 2>/dev/null
    
    cat "$REPO_CACHE_FILE" 2>/dev/null || echo "all"
}

# Get features
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
        grep -v "^\\.\\$" | sort > "$FEATURE_CACHE_FILE" 2>/dev/null
    else
        touch "$FEATURE_CACHE_FILE" 2>/dev/null
    fi
    
    cat "$FEATURE_CACHE_FILE" 2>/dev/null
}

# Get worktrees
_git_sh1_get_worktrees() {
    if _git_sh1_is_cache_valid "$WORKTREE_CACHE_FILE"; then
        cat "$WORKTREE_CACHE_FILE" 2>/dev/null
        return 0
    fi
    
    {
        echo "master"
        echo "develop" 
        echo "main"
        echo "local"
        echo "local5"
    } | sort -u > "$WORKTREE_CACHE_FILE" 2>/dev/null
    
    cat "$WORKTREE_CACHE_FILE" 2>/dev/null
}

# Clear cache
_git_sh1_clear_cache() {
    rm -f "$REPO_CACHE_FILE" "$FEATURE_CACHE_FILE" "$WORKTREE_CACHE_FILE" 2>/dev/null
    echo "Git SH1 completion cache cleared"
}

# Main completion function (Fixed for bash completion in zsh)
_git_sh1_completion() {
    local cur prev words cword
    
    # Always use bash-style completion variables
    # (zsh with bashcompinit provides these)
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
        local commands="verify fetch worktree show_repos feature -h --help --clear-cache --install-completion"
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        _git_sh1_debug "Level 1 completion: ${COMPREPLY[*]}"
        return 0
    fi
    
    local command="${COMP_WORDS[1]}"
    _git_sh1_debug "Command: $command, Level: $cword"
    
    case "$command" in
        verify|fetch)
            if [[ $cword -eq 2 ]]; then
                local repos=$(_git_sh1_get_repositories)
                COMPREPLY=($(compgen -W "$repos" -- "$cur"))
                _git_sh1_debug "Repository completion: ${COMPREPLY[*]:0:5}..."
            fi
            ;;
            
        worktree)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "add pull-rebase" -- "$cur"))
                _git_sh1_debug "Worktree subcommands: ${COMPREPLY[*]}"
            elif [[ $cword -eq 3 ]]; then
                local subcommand="${COMP_WORDS[2]}"
                if [[ "$subcommand" == "add" || "$subcommand" == "pull-rebase" ]]; then
                    local repos=$(_git_sh1_get_repositories)
                    COMPREPLY=($(compgen -W "$repos" -- "$cur"))
                    _git_sh1_debug "Worktree repos: ${COMPREPLY[*]:0:5}..."
                fi
            fi
            ;;
            
        feature)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "create list show comment switch switchback pick" -- "$cur"))
                _git_sh1_debug "Feature subcommands: ${COMPREPLY[*]}"
            elif [[ $cword -ge 3 ]]; then
                local subcommand="${COMP_WORDS[2]}"
                _git_sh1_debug "Feature subcommand: $subcommand"
                
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
                                    local repos=$(_git_sh1_get_repositories)
                                    repos=$(echo "$repos" | grep -v "^all$")
                                    COMPREPLY=($(compgen -W "$repos" -- "$cur"))
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
                            local features=$(_git_sh1_get_features)
                            COMPREPLY=($(compgen -W "$features" -- "$cur"))
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
                                    local features=$(_git_sh1_get_features)
                                    local branches="master main develop release"
                                    COMPREPLY=($(compgen -W "$features $branches" -- "$cur"))
                                fi
                                ;;
                        esac
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

# Simple registration that works in zsh with bashcompinit
echo "🚀 Loading Git SH1 completion..."

# Ensure bashcompinit is available (for zsh)
if [[ -n "$ZSH_VERSION" ]]; then
    if ! command -v bashcompinit >/dev/null 2>&1; then
        autoload -U +X bashcompinit
        bashcompinit
    fi
fi

# Register completion
complete -F _git_sh1_completion git_sh1.sh 2>/dev/null
complete -F _git_sh1_completion ./git_sh1.sh 2>/dev/null

echo "✅ Git SH1 completion loaded successfully!"
echo "🧪 Try: ./git_sh1.sh [TAB] or ./git_sh1.sh fetch [TAB]"

# Export functions for debugging
if [[ "${GIT_SH1_DEBUG:-}" == "1" ]]; then
    export -f _git_sh1_debug _git_sh1_get_repositories _git_sh1_get_features _git_sh1_get_worktrees _git_sh1_clear_cache 2>/dev/null || true
fi