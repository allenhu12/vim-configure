#!/bin/bash

# profiles/parser.sh - Profile parsing for git_sh1_modules
# Handles manifest.xml parsing and repository map generation

# Load dependencies
if [ -z "$MODULE_LOADER_LOADED" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$script_dir/../lib/module_loader.sh"
fi

load_module "core/config.sh"
load_module "core/logging.sh"
load_module "core/validation.sh"
load_module "core/utils.sh"

# Parse manifest.xml and generate repo_map.txt
parse_manifest_xml() {
    local manifest_file="$1"
    local output_file="$2"
    local upstream_file="${output_file%.*}_upstream.txt"  # Create upstream file alongside repo_map
    
    if [ ! -f "$manifest_file" ]; then
        echo -e "${RED}Error: Manifest file not found: $manifest_file${NC}"
        return 1
    fi
    
    log "INFO" "Parsing manifest file: $manifest_file"
    
    # Clear the upstream file before regenerating
    > "$upstream_file"
    
    # Use xmllint if available, otherwise fall back to grep/sed
    if command -v xmllint >/dev/null 2>&1; then
        # Extract project elements using xmllint
        xmllint --format "$manifest_file" | grep '<project ' | while IFS= read -r line; do
            # Extract name, path, and upstream attributes
            local name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
            local path=$(echo "$line" | sed -n 's/.*path="\([^"]*\)".*/\1/p')
            local upstream=$(echo "$line" | sed -n 's/.*upstream="\([^"]*\)".*/\1/p')
            
            # If path is empty, use name as path (e.g., opensource:opensource)
            if [ -n "$name" ]; then
                if [ -z "$path" ]; then
                    path="$name"
                fi
                echo "$name:$path"
                
                # Store upstream information if available
                if [ -n "$upstream" ]; then
                    echo "$name:$upstream" >> "$upstream_file"
                fi
            fi
        done > "$output_file"
    else
        # Fallback to grep/sed for systems without xmllint
        grep '<project ' "$manifest_file" | while IFS= read -r line; do
            # Extract name, path, and upstream attributes using sed
            local name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
            local path=$(echo "$line" | sed -n 's/.*path="\([^"]*\)".*/\1/p')
            local upstream=$(echo "$line" | sed -n 's/.*upstream="\([^"]*\)".*/\1/p')
            
            # If path is empty, use name as path (e.g., opensource:opensource)
            if [ -n "$name" ]; then
                if [ -z "$path" ]; then
                    path="$name"
                fi
                echo "$name:$path"
                
                # Store upstream information if available
                if [ -n "$upstream" ]; then
                    echo "$name:$upstream" >> "$upstream_file"
                fi
            fi
        done > "$output_file"
    fi
    
    if [ ! -s "$output_file" ]; then
        echo -e "${RED}Error: Failed to parse manifest or no projects found${NC}"
        log "ERROR" "Failed to parse manifest: $manifest_file"
        return 1
    fi
    
    local repo_count=$(wc -l < "$output_file")
    local upstream_count=0
    if [ -f "$upstream_file" ]; then
        upstream_count=$(wc -l < "$upstream_file")
    fi
    
    echo -e "${GREEN}Generated repo_map with $repo_count repositories${NC}"
    if [ $upstream_count -gt 0 ]; then
        echo -e "${GREEN}Generated upstream mappings for $upstream_count repositories${NC}"
        log "INFO" "Generated upstream_map: $upstream_file ($upstream_count repositories)"
    fi
    log "INFO" "Generated repo_map: $output_file ($repo_count repositories)"
    return 0
}

# Generate profile metadata
generate_profile_metadata() {
    local profile_name="$1"
    local manifest_file="$2"
    local repo_map_file="$3"
    local metadata_file="$4"
    
    local repo_count=$(wc -l < "$repo_map_file" 2>/dev/null || echo "0")
    local creation_date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    
    # Extract common upstream branch from manifest if available
    local upstream_branch=""
    if [ -f "$manifest_file" ]; then
        upstream_branch=$(grep 'upstream=' "$manifest_file" | head -1 | sed -n 's/.*upstream="\([^"]*\)".*/\1/p')
    fi
    
    # Generate metadata JSON
    cat > "$metadata_file" << EOF
{
  "profile_name": "$profile_name",
  "created_date": "$creation_date",
  "source_manifest": "$(basename "$manifest_file")",
  "repository_count": $repo_count,
  "upstream_branch": "$upstream_branch"
}
EOF
    
    log "INFO" "Generated profile metadata: $metadata_file"
    return 0
}

# Validate manifest.xml format
validate_manifest_xml() {
    local manifest_file="$1"
    
    if [ ! -f "$manifest_file" ]; then
        echo -e "${RED}Error: Manifest file not found: $manifest_file${NC}"
        return 1
    fi
    
    # Check if file contains XML and has project elements
    if ! grep -q '<manifest' "$manifest_file" || ! grep -q '<project' "$manifest_file"; then
        echo -e "${RED}Error: Invalid manifest.xml format${NC}"
        echo -e "${YELLOW}Expected format: Android repo-style manifest with <project> elements${NC}"
        return 1
    fi
    
    # Basic XML syntax check if xmllint is available
    if command -v xmllint >/dev/null 2>&1; then
        if ! xmllint --noout "$manifest_file" 2>/dev/null; then
            echo -e "${RED}Error: Manifest XML syntax is invalid${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Extract profile information from manifest
extract_manifest_info() {
    local manifest_file="$1"
    
    if [ ! -f "$manifest_file" ]; then
        return 1
    fi
    
    # Extract default remote and revision
    local default_remote=$(grep '<default ' "$manifest_file" | sed -n 's/.*remote="\([^"]*\)".*/\1/p')
    local default_revision=$(grep '<default ' "$manifest_file" | sed -n 's/.*revision="\([^"]*\)".*/\1/p')
    
    # Count project elements
    local project_count=$(grep -c '<project ' "$manifest_file")
    
    echo "default_remote:$default_remote"
    echo "default_revision:$default_revision"
    echo "project_count:$project_count"
    
    return 0
}

echo "Profile parser module loaded"