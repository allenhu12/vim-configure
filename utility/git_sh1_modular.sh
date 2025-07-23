#!/bin/bash

# git_sh1_modular.sh - Compatibility wrapper for the modular git_sh1 system
# This provides backward compatibility while using the new modular architecture

# Determine script directory (handle symbolic links properly)
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # If this is a symbolic link, resolve to the actual script location
    WRAPPER_DIR="$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}")")" && pwd)"
else
    # If this is the actual script, use its directory
    WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
MODULAR_SCRIPT="${WRAPPER_DIR}/git_sh1_modules/git_sh1_main.sh"

# Check if modular system is available
if [[ ! -f "$MODULAR_SCRIPT" ]]; then
    echo "Error: Modular git_sh1 system not found at: $MODULAR_SCRIPT" >&2
    echo "Please ensure git_sh1_modules directory exists and is properly set up." >&2
    exit 1
fi

# Check if modular script is executable
if [[ ! -x "$MODULAR_SCRIPT" ]]; then
    echo "Error: Modular git_sh1 script is not executable: $MODULAR_SCRIPT" >&2
    echo "Run: chmod +x $MODULAR_SCRIPT" >&2
    exit 1
fi

# Execute the modular system with all arguments
exec "$MODULAR_SCRIPT" "$@"