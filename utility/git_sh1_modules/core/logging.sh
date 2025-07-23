#!/bin/bash

# core/logging.sh - Logging system, cleanup, and signal handling for git_sh1_modules
# Depends on: core/config.sh (for LOG_FILE, VERBOSE, colors, and LOCK_FILE variables)

# Initialize logging system
init_logging() {
    # Ensure script_dir is available
    if [[ -z "$script_dir" ]]; then
        echo "Warning: script_dir not set, using current directory for log file" >&2
        script_dir="$(pwd)"
    fi
    
    LOG_FILE="${script_dir}/git_sh1_$(date '+%Y%m%d_%H%M%S').log"
    
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${CYAN}Logging to: $LOG_FILE${NC}"
    fi
    
    # Create log file and log initialization
    touch "$LOG_FILE"
    log "INFO" "Logging initialized: $LOG_FILE"
}

# Centralized logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure LOG_FILE is set
    if [[ -z "$LOG_FILE" ]]; then
        echo "Warning: LOG_FILE not set, logging to stderr" >&2
        LOG_FILE="/dev/stderr"
    fi
    
    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Optionally write to console
    if [ "$VERBOSE" = "true" ] || [ "$level" = "ERROR" ]; then
        echo -e "${CYAN}[$level]${NC} $message"
    fi
}

# Cleanup function - called on script exit
cleanup() {
    # Clean up temporary directory if it exists
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log "INFO" "Cleaned up temporary directory: $TEMP_DIR"
    fi
    
    # Remove lock file if it exists
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log "INFO" "Removed lock file: $LOCK_FILE"
    fi
    
    log "INFO" "Script cleanup completed"
}

# Process locking mechanism
acquire_lock() {
    # Check if lock file already exists
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid
        lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        
        # Check if the process is still running
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            echo -e "${RED}Error: Another instance is running (PID: $lock_pid)${NC}"
            return 1
        else
            log "INFO" "Removing stale lock file (PID: $lock_pid)"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    # Create lock file with current PID
    echo $$ > "$LOCK_FILE"
    log "INFO" "Acquired lock with PID: $$"
    return 0
}

# Release lock (optional explicit release)
release_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid
        lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        
        if [ "$lock_pid" = "$$" ]; then
            rm -f "$LOCK_FILE"
            log "INFO" "Released lock (PID: $$)"
        else
            log "WARNING" "Lock file contains different PID: $lock_pid (current: $$)"
        fi
    fi
}

# Create temporary directory
create_temp_dir() {
    TEMP_DIR=$(mktemp -d)
    local result=$?
    
    if [ $result -eq 0 ] && [ -d "$TEMP_DIR" ]; then
        log "INFO" "Created temporary directory: $TEMP_DIR"
        return 0
    else
        log "ERROR" "Failed to create temporary directory"
        return 1
    fi
}

# Enhanced logging functions for different levels
log_debug() {
    if [ "$VERBOSE" = "true" ]; then
        log "DEBUG" "$@"
    fi
}

log_info() {
    log "INFO" "$@"
}

log_warning() {
    log "WARNING" "$@"
}

log_error() {
    log "ERROR" "$@"
}

# Log command execution with timing
log_command() {
    local cmd="$1"
    local start_time=$(date +%s)
    
    log_info "Executing command: $cmd"
    
    # Execute the command and capture return code
    eval "$cmd"
    local exit_code=$?
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $exit_code -eq 0 ]; then
        log_info "Command completed successfully in ${duration}s: $cmd"
    else
        log_error "Command failed with exit code $exit_code in ${duration}s: $cmd"
    fi
    
    return $exit_code
}

# Set up signal handlers for cleanup
setup_signal_handlers() {
    trap cleanup EXIT INT TERM
    log_debug "Signal handlers set up for cleanup"
}

# Initialize signal handlers when module is loaded
setup_signal_handlers