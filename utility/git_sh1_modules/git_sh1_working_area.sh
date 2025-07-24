#!/bin/bash

# git_sh1_working_area.sh - Working area entry point for the modular git_sh1 system
# This script should be run from the git-depot working area (e.g., /Volumes/BackupT7/workspace_t7/git-depot)
# It will properly initialize the system to use the current working area as the git-depot

# Determine where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULAR_MAIN="${SCRIPT_DIR}/git_sh1_main.sh"

# Override git-depot discovery by setting it explicitly to current working directory
export WORKING_AREA_OVERRIDE="$(pwd)"

# Check if we're in a directory that looks like git-depot
if [[ ! "$(basename "$(pwd)")" == "git-depot" && ! -d "repo_base" ]]; then
    echo "Warning: This script is designed to be run from a git-depot directory" >&2
    echo "Current directory: $(pwd)" >&2
    echo "Expected: A directory named 'git-depot' or containing 'repo_base'" >&2
fi

# Check if modular system is available
if [[ ! -f "$MODULAR_MAIN" ]]; then
    echo "Error: Modular git_sh1 system not found at: $MODULAR_MAIN" >&2
    exit 1
fi

# Execute the modular system with all arguments, forcing it to use current directory as git-depot
exec "$MODULAR_MAIN" "$@"