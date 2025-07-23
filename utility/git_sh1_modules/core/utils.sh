#!/bin/bash

# core/utils.sh - Common utilities for git_sh1_modules
# Depends on: core/config.sh (for colors and DRY_RUN), core/logging.sh (for log function)

# Enhanced execute command with dry-run support
execute_command() {
    local cmd="$*"
    
    if command -v log > /dev/null 2>&1; then
        log "INFO" "Executing: $cmd"
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}[DRY-RUN] Would execute: $cmd${NC}"
        return 0
    else
        eval "$cmd"
        local exit_code=$?
        
        if [ $exit_code -ne 0 ]; then
            if command -v log > /dev/null 2>&1; then
                log "ERROR" "Command failed with exit code $exit_code: $cmd"
            fi
        fi
        
        return $exit_code
    fi
}

# Progress indicator for long-running operations
show_progress() {
    local current=$1
    local total=$2
    local operation="$3"
    
    if [[ -z "$current" ]] || [[ -z "$total" ]] || [[ "$total" -eq 0 ]]; then
        return 1
    fi
    
    local percent=$((current * 100 / total))
    printf "\r${CYAN}[%d/%d] (%d%%) %s...${NC}" "$current" "$total" "$percent" "$operation"
    
    # Add newline when operation is complete
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Check system dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for jq (JSON processor)
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check for ssh
    if ! command -v ssh &> /dev/null; then
        missing_deps+=("ssh")
    fi
    
    # Check for timeout or nc (for connectivity tests)
    if ! command -v timeout &> /dev/null && ! command -v nc &> /dev/null; then
        missing_deps+=("timeout or nc")
    fi
    
    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - ${YELLOW}$dep${NC}"
        done
        echo -e "\nPlease install the missing dependencies:"
        echo -e "  ${CYAN}sudo apt-get install ${missing_deps[*]}${NC} (Ubuntu/Debian)"
        echo -e "  ${CYAN}brew install ${missing_deps[*]}${NC} (macOS)"
        return 1
    fi
    
    return 0
}

# Sort the repo_map by path depth (shallowest first)
sort_repo_map_once() {
    local sorted_entries=()
    
    # Parse repo_map and sort by depth
    for pair in $repo_map; do
        IFS=':' read -r repo_name local_folder <<< "$pair"
        if [ -n "$repo_name" ] && [ -n "$local_folder" ]; then
            local depth=$(echo "$local_folder" | tr -cd '/' | wc -c)
            sorted_entries+=("${depth}:${pair}")
        fi
    done
    
    # Sort by depth (numeric sort) and reconstruct repo_map
    repo_map=""
    while IFS= read -r entry; do
        # Remove the depth prefix
        local pair="${entry#*:}"
        repo_map="$repo_map
    $pair"
    done <<< "$(printf '%s\n' "${sorted_entries[@]}" | sort -n)"
}

# Create backup of a file with timestamp
backup_file() {
    local file_path="$1"
    local backup_suffix="${2:-$(date '+%Y%m%d_%H%M%S')}"
    
    if [[ -z "$file_path" ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "backup_file: file path is required"
        fi
        return 1
    fi
    
    if [[ -f "$file_path" ]]; then
        local backup_path="${file_path}.backup.${backup_suffix}"
        if cp "$file_path" "$backup_path"; then
            if command -v log > /dev/null 2>&1; then
                log "INFO" "Created backup: $backup_path"
            fi
            echo "$backup_path"
            return 0
        else
            if command -v log > /dev/null 2>&1; then
                log "ERROR" "Failed to create backup: $backup_path"
            fi
            return 1
        fi
    else
        if command -v log > /dev/null 2>&1; then
            log "WARNING" "backup_file: file does not exist: $file_path"
        fi
        return 1
    fi
}

# Restore file from backup
restore_backup() {
    local original_file="$1"
    local backup_file="$2"
    
    if [[ -z "$original_file" ]] || [[ -z "$backup_file" ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "restore_backup: both original and backup file paths are required"
        fi
        return 1
    fi
    
    if [[ -f "$backup_file" ]]; then
        if cp "$backup_file" "$original_file"; then
            if command -v log > /dev/null 2>&1; then
                log "INFO" "Restored from backup: $backup_file -> $original_file"
            fi
            return 0
        else
            if command -v log > /dev/null 2>&1; then
                log "ERROR" "Failed to restore from backup: $backup_file"
            fi
            return 1
        fi
    else
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "restore_backup: backup file does not exist: $backup_file"
        fi
        return 1
    fi
}

# Safe directory creation with path validation
safe_mkdir() {
    local dir_path="$1"
    local mode="${2:-755}"
    
    if [[ -z "$dir_path" ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "safe_mkdir: directory path is required"
        fi
        return 1
    fi
    
    # Basic path validation to prevent dangerous operations
    if [[ "$dir_path" =~ \.\.|^/etc|^/usr|^/bin|^/sbin ]]; then
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "safe_mkdir: potentially dangerous path: $dir_path"
        fi
        return 1
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}[DRY-RUN] Would create directory: $dir_path${NC}"
        return 0
    fi
    
    if mkdir -p -m "$mode" "$dir_path"; then
        if command -v log > /dev/null 2>&1; then
            log "INFO" "Created directory: $dir_path"
        fi
        return 0
    else
        if command -v log > /dev/null 2>&1; then
            log "ERROR" "Failed to create directory: $dir_path"
        fi
        return 1
    fi
}

# Check if we're in a git repository
is_git_repo() {
    local dir_path="${1:-$(pwd)}"
    
    if [[ -d "$dir_path" ]]; then
        (cd "$dir_path" && git rev-parse --git-dir >/dev/null 2>&1)
    else
        return 1
    fi
}

# Get current git branch
get_current_branch() {
    local repo_path="${1:-$(pwd)}"
    
    if [[ -d "$repo_path" ]]; then
        (cd "$repo_path" && git branch --show-current 2>/dev/null)
    else
        return 1
    fi
}

# Wait for user confirmation
confirm_action() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"
    
    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$prompt [Y/n]: " response
            response=${response:-y}
        else
            read -p "$prompt [y/N]: " response
            response=${response:-n}
        fi
        
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Format elapsed time
format_duration() {
    local seconds=$1
    
    if [[ -z "$seconds" ]] || [[ ! "$seconds" =~ ^[0-9]+$ ]]; then
        echo "0s"
        return
    fi
    
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}