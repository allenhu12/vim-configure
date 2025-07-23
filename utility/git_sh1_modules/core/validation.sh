#!/bin/bash

# core/validation.sh - Input sanitization and path validation for git_sh1_modules
# Depends on: core/logging.sh (for log function)

# Input sanitization - removes dangerous characters
sanitize_input() {
    local input="$1"
    
    if [[ -z "$input" ]]; then
        return 1
    fi
    
    # Remove dangerous characters, keep alphanumeric, dots, dashes, underscores, slashes
    echo "$input" | sed 's/[^a-zA-Z0-9._/-]//g'
}

# Sanitize repository name specifically
sanitize_repo_name() {
    local repo_name="$1"
    
    if [[ -z "$repo_name" ]]; then
        return 1
    fi
    
    # Repository names should only contain alphanumeric, underscores, and dashes
    echo "$repo_name" | sed 's/[^a-zA-Z0-9._-]//g'
}

# Sanitize branch name
sanitize_branch_name() {
    local branch_name="$1"
    
    if [[ -z "$branch_name" ]]; then
        return 1
    fi
    
    # Branch names can contain alphanumeric, slashes, dashes, underscores, dots
    echo "$branch_name" | sed 's/[^a-zA-Z0-9._/-]//g'
}

# Path normalization helper - converts path to canonical form
normalize_path() {
    local path="$1"
    
    if [[ -z "$path" ]]; then
        return 1
    fi
    
    # Normalize path manually (remove .. and . components)
    local normalized_path=""
    IFS='/' read -ra PATH_PARTS <<< "$path"
    local path_components=()
    
    for part in "${PATH_PARTS[@]}"; do
        if [[ "$part" == "." ]] || [[ -z "$part" ]]; then
            continue
        elif [[ "$part" == ".." ]]; then
            if [[ ${#path_components[@]} -gt 0 ]]; then
                unset 'path_components[-1]'
            fi
        else
            path_components+=("$part")
        fi
    done
    
    # Rebuild the path
    normalized_path="/"
    for component in "${path_components[@]}"; do
        normalized_path="$normalized_path$component/"
    done
    
    # Remove trailing slash except for root
    if [[ "$normalized_path" != "/" ]]; then
        normalized_path="${normalized_path%/}"
    fi
    
    echo "$normalized_path"
    return 0
}

# General path validation with boundary checking
validate_path() {
    local path="$1"
    local base_path="$2"
    
    if [[ -z "$path" ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Path validation failed: path is empty"
        fi
        return 1
    fi
    
    if [[ -z "$base_path" ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Path validation failed: base_path is empty"
        fi
        return 1
    fi
    
    # Convert to absolute path
    if [[ "$path" != /* ]]; then
        path="$base_path/$path"
    fi
    
    # Normalize the path
    local normalized_path
    normalized_path=$(normalize_path "$path")
    local normalize_result=$?
    
    if [ $normalize_result -ne 0 ]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Path normalization failed: $path"
        fi
        return 1
    fi
    
    # Check if path is within allowed boundaries
    if [[ "$normalized_path" != "$base_path"* ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Path outside allowed boundaries: $normalized_path (base: $base_path)"
        fi
        return 1
    fi
    
    echo "$normalized_path"
    return 0
}

# Worktree-specific path validation - doesn't require path to exist
validate_worktree_path() {
    local path="$1"
    local base_path="$2"
    
    if [[ -z "$path" ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Worktree path validation failed: path is empty"
        fi
        return 1
    fi
    
    if [[ -z "$base_path" ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Worktree path validation failed: base_path is empty"
        fi
        return 1
    fi
    
    # Convert to absolute path
    if [[ "$path" != /* ]]; then
        path="$base_path/$path"
    fi
    
    # Normalize the path
    local normalized_path
    normalized_path=$(normalize_path "$path")
    local normalize_result=$?
    
    if [ $normalize_result -ne 0 ]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Worktree path normalization failed: $path"
        fi
        return 1
    fi
    
    # Check if path is within allowed boundaries
    if [[ "$normalized_path" != "$base_path"* ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Worktree path outside allowed boundaries: $normalized_path"
        fi
        return 1
    fi
    
    echo "$normalized_path"
    return 0
}

# Validate repository name format
validate_repo_name_format() {
    local repo_name="$1"
    
    if [[ -z "$repo_name" ]]; then
        return 1
    fi
    
    # Repository names should start with alphanumeric and contain only safe characters
    if [[ "$repo_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate branch name format
validate_branch_name_format() {
    local branch_name="$1"
    
    if [[ -z "$branch_name" ]]; then
        return 1
    fi
    
    # Basic Git branch name validation
    # - No leading/trailing slashes
    # - No double slashes
    # - No spaces or special characters except allowed ones
    if [[ "$branch_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._/-]*[a-zA-Z0-9]$ ]] && 
       [[ ! "$branch_name" =~ // ]] && 
       [[ ! "$branch_name" =~ ^/ ]] && 
       [[ ! "$branch_name" =~ /$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate URL format (basic check)
validate_url_format() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        return 1
    fi
    
    # Basic URL validation for git URLs
    if [[ "$url" =~ ^(https?|ssh|git)://[a-zA-Z0-9.-]+.*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate file path exists and is readable
validate_file_readable() {
    local file_path="$1"
    
    if [[ -z "$file_path" ]]; then
        return 1
    fi
    
    if [[ -f "$file_path" && -r "$file_path" ]]; then
        return 0
    else
        return 1
    fi
}

# Validate directory exists and is accessible
validate_directory_accessible() {
    local dir_path="$1"
    
    if [[ -z "$dir_path" ]]; then
        return 1
    fi
    
    if [[ -d "$dir_path" && -x "$dir_path" ]]; then
        return 0
    else
        return 1
    fi
}