#!/bin/bash

# Default MAP_FILE location
DEFAULT_MAP_FILE="/Users/hubo/workspace/git-depot/vim-configure/utility/rsync_map.txt"
INCLUDE_FILE=""

# Function to display help information
show_help() {
    echo "Usage: $0 [--dry-run|--run] [--map-file <path_to_map_file>] [--include <path_to_include_file>]"
    echo
    echo "Options:"
    echo "  --dry-run             Perform a trial run with no changes made"
    echo "  --run                 Perform the actual synchronization"
    echo "  --map-file <file>     Specify a custom map file (default: $DEFAULT_MAP_FILE)"
    echo "  --include <file>      Specify a file containing include patterns (supports regex)"
    echo
    echo "Examples:"
    echo "  # Use default map file"
    echo "  $0 --dry-run"
    echo
    echo "  # Use a custom map file"
    echo "  $0 --dry-run --map-file /path/to/custom/map_file.txt"
    echo
    echo "  # Perform actual sync with custom map file and include file"
    echo "  $0 --run --map-file /path/to/custom/map_file.txt --include /path/to/include_patterns.txt"
}

# Function to perform rsync
perform_rsync() {
    local dry_run=$1
    local map_file=$2
    local include_file=$3
    local dry_run_option=""
    local include_option=""
    
    if [ "$dry_run" = true ]; then
        dry_run_option="--dry-run"
    fi

    if [ -n "$include_file" ]; then
        # Remove leading/trailing whitespace and empty lines from include file
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//;/^$/d' "$include_file" > "${include_file}.tmp"
        include_option="--include-from=${include_file}.tmp --exclude=*"
        echo "Using include patterns from: $include_file"
        echo "Cleaned include patterns:"
        cat "${include_file}.tmp"
        echo "-----------------------------------"
    else
        include_option="--include='*/' --include='*.c' --include='*.h' --exclude='*'"
    fi

    # Define color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    while IFS=: read -r source target; do
        echo "Syncing from $source to $target"
        echo "rsync command: rsync -avi --checksum --itemize-changes $include_option $dry_run_option \"$source\" \"$target\""
        rsync -avi --checksum --itemize-changes \
              $include_option \
              $dry_run_option \
              "$source" "$target" | while read -r line; do
            action="${line:0:1}"
            file="${line:12}"
            case "$action" in
                "<")
                    echo -e "${RED}Deleted:${NC} $file"
                    ;;
                ">")
                    if [[ $line == *"f+++"* ]]; then
                        echo -e "${GREEN}Added:${NC} $file"
                    elif [[ $line == *"f.st"* ]]; then
                        echo -e "${YELLOW}Changed (content):${NC} $file"
                    else
                        echo -e "${BLUE}Changed:${NC} $file"
                    fi
                    ;;
                "c")
                    echo -e "${YELLOW}Changed (metadata):${NC} $file"
                    ;;
                "h")
                    echo -e "${BLUE}Hardlink:${NC} $file"
                    ;;
                ".")
                    # Ignore attribute changes
                    ;;
                *)
                    echo "Other change: $line"
                    ;;
            esac
        done
        echo "-----------------------------------"
    done < "$map_file"

    # Clean up temporary file
    if [ -n "$include_file" ]; then
        rm "${include_file}.tmp"
    fi
}

# Parse command line arguments
MAP_FILE="$DEFAULT_MAP_FILE"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --run)
            DRY_RUN=false
            shift
            ;;
        --map-file)
            MAP_FILE="$2"
            shift 2
            ;;
        --include)
            INCLUDE_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if the map file exists
if [ ! -f "$MAP_FILE" ]; then
    echo "Map file not found: $MAP_FILE"
    echo "Creating a sample one at the default location."
    echo "/Volumes/BackupT7/workspace_t7/git-depot/webserver_upgrade/rks_ap/apps/web_adapter/:/Volumes/ubuntu20_workspace/bk/web_adapter/" > "$DEFAULT_MAP_FILE"
    echo "Please edit $DEFAULT_MAP_FILE to add your source:target mappings."
    exit 1
fi

# Check if the include file exists
if [ -n "$INCLUDE_FILE" ] && [ ! -f "$INCLUDE_FILE" ]; then
    echo "Include file not found: $INCLUDE_FILE"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    echo "Performing dry run..."
else
    echo "Performing actual sync..."
fi

perform_rsync $DRY_RUN "$MAP_FILE" "$INCLUDE_FILE"

echo "Sync operation completed."