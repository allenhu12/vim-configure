#!/bin/bash

# git_sh3_fixed.sh - Fixed version for working area usage
# Place this script in your git-depot working area (/Volumes/BackupT7/workspace_t7/git-depot/)

# Path to the actual modular script
MODULAR_SCRIPT="/Users/hubo/workspace/git-depot/vim-configure/utility/git_sh1_modules/git_sh1_main.sh"

# Check if we're in a git-depot directory
CURRENT_DIR="$(pwd)"
if [[ ! "$(basename "$CURRENT_DIR")" == "git-depot" && ! -d "repo_base" ]]; then
    echo "Warning: This script should be run from a git-depot directory" >&2
    echo "Current directory: $CURRENT_DIR" >&2
fi

# Check if modular system is available
if [[ ! -f "$MODULAR_SCRIPT" ]]; then
    echo "Error: Modular git_sh1 system not found at: $MODULAR_SCRIPT" >&2
    echo "Please check the path to your modular system" >&2
    exit 1
fi

# Export the current directory as the working area override
export WORKING_AREA_OVERRIDE="$CURRENT_DIR"

# Execute the modular system with all arguments
exec "$MODULAR_SCRIPT" "$@"