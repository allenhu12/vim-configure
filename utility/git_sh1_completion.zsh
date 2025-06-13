#!/bin/zsh
# Zsh completion for git_sh1.sh script
# 
# Installation for zsh:
#   1. Copy this file to your server alongside git_sh1.sh
#   2. Add to your .zshrc: source /path/to/git_sh1_completion.zsh
#   3. Or run: autoload -U compinit && compinit
#
# This file provides native zsh completion and also loads bash completion as fallback

# Enable bash completion compatibility
autoload -U +X bashcompinit && bashcompinit

# Source the bash completion file if it exists
_git_sh1_script_dir="${0:A:h}"
_git_sh1_bash_completion="${_git_sh1_script_dir}/git_sh1_completion.bash"

if [[ -f "$_git_sh1_bash_completion" ]]; then
    source "$_git_sh1_bash_completion"
    echo "Git SH1 completion loaded (bash compatibility mode for zsh)"
else
    echo "Warning: git_sh1_completion.bash not found at $_git_sh1_bash_completion"
fi

# Zsh-specific enhancements
if [[ -n "$ZSH_VERSION" ]]; then
    # Enable completion menu
    zstyle ':completion:*' menu select
    
    # Enable case-insensitive completion
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    
    # Enable approximate completion
    zstyle ':completion:*' completer _complete _approximate
    zstyle ':completion:*:approximate:*' max-errors 2
    
    # Group completions by type
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*:descriptions' format '%B%d%b'
    
    # Enhanced completion for git_sh1.sh
    zstyle ':completion:*:*:git_sh1.sh:*' file-patterns '*:all-files'
    zstyle ':completion:*:*:./git_sh1.sh:*' file-patterns '*:all-files'
fi

# Additional zsh completion function (native zsh style)
_git_sh1_zsh() {
    local context state line
    local -a commands subcommands repos features
    
    # Get the script directory
    local script_dir="${words[1]:A:h}"
    local completion_script="$script_dir/git_sh1_completion.bash"
    
    # Load repository and feature data if bash completion is available
    if [[ -f "$completion_script" ]]; then
        source "$completion_script" 2>/dev/null
        repos=($(echo "$(_git_sh1_get_repositories 2>/dev/null)" | tr '\n' ' '))
        features=($(echo "$(_git_sh1_get_features 2>/dev/null)" | tr '\n' ' '))
    else
        repos=(all controller opensource rks_ap dl)
        features=()
    fi
    
    commands=(
        'verify:Verify repository existence'
        'fetch:Fetch repository metadata'
        'worktree:Manage git worktrees'
        'show_repos:List all configured repositories'
        'feature:Manage feature branches'
        '--help:Show help information'
        '--install-completion:Install bash completion'
        '--clear-cache:Clear completion cache'
    )
    
    _arguments -C \
        '1: :->command' \
        '*: :->args' && return 0
    
    case $state in
        command)
            _describe 'git_sh1 commands' commands
            ;;
        args)
            case ${words[2]} in
                verify|fetch)
                    _describe 'repositories' repos
                    ;;
                worktree)
                    subcommands=('add:Add a new worktree' 'pull-rebase:Pull and rebase worktree')
                    _describe 'worktree commands' subcommands
                    ;;
                feature)
                    case ${words[3]} in
                        create)
                            _arguments \
                                '-w[worktree]:worktree:' \
                                '--force[force overwrite]' \
                                '*:repository:($repos)'
                            ;;
                        show|switch|switchback|comment)
                            _arguments \
                                '-w[worktree]:worktree:' \
                                '*:feature:($features)'
                            ;;
                        pick)
                            _arguments \
                                '-w[worktree]:worktree:' \
                                '--dry-run[dry run mode]' \
                                '*:feature or branch:($features master main develop release)'
                            ;;
                        *)
                            subcommands=(
                                'create:Create a new feature'
                                'list:List all features'
                                'show:Show feature details'
                                'comment:Add comment to feature'
                                'switch:Switch to feature branches'
                                'switchback:Switch back to original branches'
                                'pick:Cherry-pick feature commits'
                            )
                            _describe 'feature commands' subcommands
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac
}

# Register the zsh completion function as a fallback
compdef _git_sh1_zsh git_sh1.sh
compdef _git_sh1_zsh ./git_sh1.sh

# Clean up variables
unset _git_sh1_script_dir _git_sh1_bash_completion

echo "Git SH1 zsh completion loaded with enhanced features"