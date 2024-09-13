#!/bin/bash

# Default MAP_FILE location
DEFAULT_MAP_FILE="/Users/hubo/workspace/git-depot/vim-configure/utility/rsync_map.txt"

# Function to display help information
show_help() {
    echo "Usage: $0 [--dry-run|--run] [--map-file <path_to_map_file>]"
    echo
    echo "Options:"
    echo "  --dry-run             Perform a trial run with no changes made"
    echo "  --run                 Perform the actual synchronization"
    echo "  --map-file <file>     Specify a custom map file (default: $DEFAULT_MAP_FILE)"
    echo
    echo "Examples:"
    echo "  # Use default map file"
    echo "  $0 --dry-run"
    echo
    echo "  # Use a custom map file"
    echo "  $0 --dry-run --map-file /path/to/custom/map_file.txt"
    echo
    echo "  # Perform actual sync with custom map file"
    echo "  $0 --run --map-file /path/to/custom/map_file.txt"
}

# Function to perform rsync
perform_rsync() {
    local dry_run=$1
    local map_file=$2
    local dry_run_option=""
    
    if [ "$dry_run" = true ]; then
        dry_run_option="--dry-run"
    fi

    # Define color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    while IFS=: read -r source target; do
        echo "Syncing from $source to $target"
        rsync -avi --checksum --itemize-changes \
              --include='*/' --include='*.c' --include='*.h' --exclude='*' \
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
                    # Ignore other changes
                    ;;
            esac
        done
        echo "-----------------------------------"
    done < "$map_file"
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

if [ "$DRY_RUN" = true ]; then
    echo "Performing dry run..."
else
    echo "Performing actual sync..."
fi

perform_rsync $DRY_RUN "$MAP_FILE"

echo "Sync operation completed."