#!/bin/bash

# profiles/manager.sh - Profile management for git_sh1_modules
# Handles profile creation, listing, showing, and management operations

# Load dependencies
if [ -z "$MODULE_LOADER_LOADED" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$script_dir/../lib/module_loader.sh"
fi

load_module "core/config.sh"
load_module "core/logging.sh"
load_module "core/validation.sh"
load_module "core/utils.sh"
load_module "repo/discovery.sh"
load_module "repo/operations.sh" 
load_module "repo/manager.sh"
load_module "profiles/parser.sh"

# Initialize profiles directory
init_profiles_dir() {
    # Initialize repository system to ensure paths are set
    if [ -z "$profiles_dir" ]; then
        if command -v init_repository_system > /dev/null 2>&1; then
            init_repository_system
        fi
    fi
    
    if [ ! -d "$profiles_dir" ]; then
        if ! mkdir -p "$profiles_dir"; then
            echo -e "${RED}Error: Failed to create profiles directory: $profiles_dir${NC}"
            log "ERROR" "Failed to create profiles directory: $profiles_dir"
            return 1
        fi
        echo -e "${GREEN}Initialized profiles directory at: $profiles_dir${NC}"
        log "INFO" "Initialized profiles directory: $profiles_dir"
    fi
    return 0
}

# Create profile from manifest
profile_create() {
    local profile_path="$1"
    
    if [ -z "$profile_path" ]; then
        echo -e "${RED}Usage: $0 profile create <release>/<name>${NC}"
        echo -e "${YELLOW}Example: $0 profile create unleashed_200.19/openwrt_common${NC}"
        return 1
    fi
    
    # Parse release and name from profile_path
    local release=$(dirname "$profile_path")
    local profile_name=$(basename "$profile_path")
    
    if [ "$release" = "." ] || [ -z "$profile_name" ]; then
        echo -e "${RED}Error: Invalid profile path. Use format: <release>/<name>${NC}"
        return 1
    fi
    
    if ! init_profiles_dir; then
        return 1
    fi
    
    local profile_dir="$profiles_dir/$profile_path"
    local manifest_file="$profile_dir/manifest.xml"
    local repo_map_file="$profile_dir/repo_map.txt"
    local metadata_file="$profile_dir/metadata.json"
    
    # Check if manifest.xml exists in the target directory
    if [ ! -f "$manifest_file" ]; then
        echo -e "${RED}Error: Manifest file not found: $manifest_file${NC}"
        echo -e "${YELLOW}Please copy your manifest.xml to: $profile_dir/${NC}"
        echo -e "${CYAN}mkdir -p $profile_dir${NC}"
        echo -e "${CYAN}cp your_manifest.xml $manifest_file${NC}"
        return 1
    fi
    
    # Check if profile already exists
    if [ -f "$repo_map_file" ]; then
        echo -e "${YELLOW}Profile '$profile_path' already exists${NC}"
        echo -e "${CYAN}Regenerating from manifest...${NC}"
    fi
    
    # Parse manifest and generate repo_map
    if ! parse_manifest_xml "$manifest_file" "$repo_map_file"; then
        return 1
    fi
    
    # Generate metadata
    if ! generate_profile_metadata "$profile_name" "$manifest_file" "$repo_map_file" "$metadata_file"; then
        return 1
    fi
    
    echo -e "${GREEN}Profile '$profile_path' created successfully${NC}"
    echo -e "${CYAN}Profile directory: $profile_dir${NC}"
    echo -e "${CYAN}Repository count: $(wc -l < "$repo_map_file")${NC}"
    
    return 0
}

# List available profiles
profile_list() {
    if ! init_profiles_dir; then
        return 1
    fi
    
    if [ ! -d "$profiles_dir" ] || [ -z "$(ls -A "$profiles_dir" 2>/dev/null)" ]; then
        echo -e "${YELLOW}No profiles found.${NC}"
        echo -e "${CYAN}Create a profile with: $0 profile create <release>/<name>${NC}"
        return 0
    fi
    
    echo -e "${CYAN}Available profiles:${NC}"
    
    # Group by release
    for release_dir in "$profiles_dir"/*; do
        if [ -d "$release_dir" ]; then
            local release_name=$(basename "$release_dir")
            echo -e "${GREEN}Release: $release_name${NC}"
            
            for profile_dir in "$release_dir"/*; do
                if [ -d "$profile_dir" ]; then
                    local profile_name=$(basename "$profile_dir")
                    local metadata_file="$profile_dir/metadata.json"
                    local repo_count="?"
                    
                    if [ -f "$metadata_file" ]; then
                        repo_count=$(grep '"repository_count"' "$metadata_file" | sed 's/.*: *\([0-9]*\).*/\1/')
                    fi
                    
                    echo -e "  - ${YELLOW}$profile_name${NC} ($repo_count repositories)"
                fi
            done
            echo
        fi
    done
}

# Show profile details
profile_show() {
    local profile_path="$1"
    
    if [ -z "$profile_path" ]; then
        echo -e "${RED}Usage: $0 profile show <release>/<name>${NC}"
        return 1
    fi
    
    # Initialize profiles directory to ensure paths are set
    if ! init_profiles_dir; then
        return 1
    fi
    
    local profile_dir="$profiles_dir/$profile_path"
    local manifest_file="$profile_dir/manifest.xml"
    local repo_map_file="$profile_dir/repo_map.txt"
    local metadata_file="$profile_dir/metadata.json"
    
    if [ ! -d "$profile_dir" ]; then
        echo -e "${RED}Error: Profile '$profile_path' not found${NC}"
        echo -e "${YELLOW}Available profiles:${NC}"
        profile_list
        return 1
    fi
    
    echo -e "${CYAN}Profile: $profile_path${NC}"
    echo
    
    # Show metadata if available
    if [ -f "$metadata_file" ]; then
        echo -e "${GREEN}Metadata:${NC}"
        if command -v jq >/dev/null 2>&1; then
            jq . "$metadata_file"
        else
            cat "$metadata_file"
        fi
        echo
    fi
    
    # Show repository mappings
    if [ -f "$repo_map_file" ]; then
        echo -e "${GREEN}Repository mappings:${NC}"
        cat "$repo_map_file"
        echo
    fi
    
    # Show files in profile directory
    echo -e "${GREEN}Profile files:${NC}"
    ls -la "$profile_dir"
}

# Load profile-specific repository mapping
load_profile_repo_map() {
    local profile_path="$1"
    
    if [ -z "$profile_path" ]; then
        echo -e "${RED}Error: Profile path required${NC}"
        log "ERROR" "load_profile_repo_map called without profile_path"
        return 1
    fi
    
    local profile_dir="$profiles_dir/$profile_path"
    local repo_map_file="$profile_dir/repo_map.txt"
    
    if [ ! -d "$profile_dir" ]; then
        echo -e "${RED}Error: Profile '$profile_path' not found${NC}"
        echo -e "${YELLOW}Available profiles:${NC}"
        if command -v profile_list > /dev/null 2>&1; then
            profile_list
        else
            echo -e "${YELLOW}Profile listing not yet implemented${NC}"
        fi
        log "ERROR" "Profile not found: $profile_path"
        return 1
    fi
    
    if [ ! -f "$repo_map_file" ]; then
        echo -e "${RED}Error: Profile repo_map not found: $repo_map_file${NC}"
        echo -e "${YELLOW}Try recreating the profile with: ./git_sh1.sh profile create $profile_path${NC}"
        log "ERROR" "Profile repo_map file not found: $repo_map_file"
        return 1
    fi
    
    # Load repo_map from file, filtering out empty lines and comments
    local profile_repo_map=""
    while IFS= read -r line; do
        # Skip empty lines and lines starting with #
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            if [ -n "$profile_repo_map" ]; then
                profile_repo_map="$profile_repo_map $line"
            else
                profile_repo_map="$line"
            fi
        fi
    done < "$repo_map_file"
    
    if [ -z "$profile_repo_map" ]; then
        echo -e "${RED}Error: Profile repo_map is empty: $repo_map_file${NC}"
        log "ERROR" "Profile repo_map is empty: $repo_map_file"
        return 1
    fi
    
    # Set the global repo_map to the profile's repo_map
    repo_map="$profile_repo_map"
    
    # Sort repo_map by depth to ensure correct processing order
    if command -v sort_repo_map_once > /dev/null 2>&1; then
        sort_repo_map_once
    fi
    
    log "INFO" "Loaded and sorted profile repo_map: $profile_path ($(echo $repo_map | wc -w) repositories)"
    return 0
}

# Get upstream branch for a repository from profile
get_upstream_from_profile() {
    local profile_path="$1"
    local repo_name="$2"
    
    if [ -z "$profile_path" ] || [ -z "$repo_name" ]; then
        log "ERROR" "get_upstream_from_profile called with missing parameters"
        return 1
    fi
    
    local profile_dir="$profiles_dir/$profile_path"
    local upstream_file="$profile_dir/repo_map_upstream.txt"
    
    if [ ! -f "$upstream_file" ]; then
        log "WARN" "No upstream file found for profile: $profile_path"
        return 1
    fi
    
    # Search for repository upstream mapping (head -1 to handle potential duplicates)
    local upstream=$(grep "^$repo_name:" "$upstream_file" | head -1 | cut -d':' -f2)
    
    if [ -n "$upstream" ]; then
        echo "$upstream"
        log "INFO" "Found upstream for $repo_name in profile $profile_path: $upstream"
        return 0
    else
        log "WARN" "No upstream found for repository $repo_name in profile $profile_path"
        return 1
    fi
}

log "INFO" "Profile management module loaded"