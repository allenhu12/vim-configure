#!/bin/bash

# core/config.sh - Configuration management for git_sh1_modules
# Contains repository mapping, global variables, and configuration constants

# Repository map (repository name:local folder):
# This is the core mapping that defines which repositories map to which local folders
repo_map="
    opensource:opensource
    rks_ap:rks_ap
    dl:dl
    linux_3_14:opensource/linux/kernels/linux-3.14.43
    linux_4_4:opensource/linux/kernels/linux-4.4.60
    linux_5_4:opensource/linux/kernels/linux-5.4
    linux_5_4_mtk:linux_5_4_mtk
    controller:rks_ap/controller
    ap_zd_controller:rks_ap/controller/common
    ruckus-spark:ruckus-spark
    ap_scg_common:rks_ap/ap_scg_common
    ap_scg_rcli:rks_ap/controller/rcli
    vendor_qca_11ac:rks_ap/platform_dp/linux/driver/vendor_qca_11ac
    vendor_qca_11ax:rks_ap/platform_dp/linux/driver/vendor_qca_11ax
    vendor_qca_11ax6e:rks_ap/platform_dp/linux/driver/vendor_qca_11ax6e
    vendor_qca_11be:rks_ap/platform_dp/linux/driver/vendor_qca_11be
    vendor_qca_ref:rks_ap/platform_dp/linux/driver/vendor_qca_ref
    vendor_qca_tools:vendor_qca_tools
    vendor_mtk_11be:vendor_mtk_11be
    rpoint_handler:rpoint_handler
    rtty:rtty
    rksiot:rksiot
    rksiot_hpkg:rksiot_hpkg
"

# ANSI color codes for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global configuration variables
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}
LOG_FILE=""
LOCK_FILE="/tmp/git_sh1_$$.lock"
TEMP_DIR=""

# Path configuration variables (initialized by init_config)
script_dir=""
git_depot_dir=""
repo_base=""
worktree_base_path=""
features_dir=""
profiles_dir=""

# SSH configuration
ssh_base="ssh://tdc-mirror-git@ruckus-git.ruckuswireless.com:7999/wrls/"

# Initialize configuration paths
init_config() {
    # Set script directory (this should be set by the main script)
    if [[ -z "$script_dir" ]]; then
        # Try to determine from module location if not set
        local config_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        script_dir="$(dirname "$config_dir")"
    fi
    
    # Initialize features directory
    features_dir="$script_dir/.git_sh1_features"
    
    # Note: git_depot_dir, repo_base, worktree_base_path, and profiles_dir 
    # are initialized by repository discovery functions in repo/discovery.sh
    # This avoids circular dependencies
}

# Get repository local path from repository name
get_repo_local_path() {
    local repo_name="$1"
    
    if [[ -z "$repo_name" ]]; then
        echo "Error: Repository name is required" >&2
        return 1
    fi
    
    # Extract the local path from repo_map
    local repo_entry
    repo_entry=$(echo "$repo_map" | grep -E "^\s*${repo_name}:" | head -1)
    
    if [[ -n "$repo_entry" ]]; then
        echo "$repo_entry" | cut -d':' -f2 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
        return 0
    else
        return 1
    fi
}

# Get all repository names
get_all_repo_names() {
    echo "$repo_map" | grep -E '^\s*[^[:space:]]+:' | sed 's/^\s*//' | cut -d':' -f1 | sort
}

# Check if a repository name exists in the map
repo_exists() {
    local repo_name="$1"
    get_repo_local_path "$repo_name" > /dev/null 2>&1
}

# Get repository count
get_repo_count() {
    get_all_repo_names | wc -l
}

# Configuration validation
validate_config() {
    local errors=0
    
    # Check required variables
    if [[ -z "$script_dir" ]]; then
        echo "Error: script_dir not set" >&2
        ((errors++))
    fi
    
    # Validate repository map format
    if ! echo "$repo_map" | grep -qE '^\s*[^:]+:[^:]+\s*$'; then
        echo "Warning: repo_map may have formatting issues" >&2
    fi
    
    return $errors
}

# Initialize configuration when module is loaded
init_config