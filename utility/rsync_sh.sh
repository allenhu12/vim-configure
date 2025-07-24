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
    local filter_options=() # Use an array for filter options
    local error_occurred=false # Flag to track if any errors happened

    if [ "$dry_run" = true ]; then
        dry_run_option="--dry-run"
    fi

    # --- Start Filter Rules Setup ---
    # Always include directories first to allow recursion
    filter_options+=("--include=*/")

    if [ -n "$include_file" ]; then
        # Remove leading/trailing whitespace and empty lines from include file
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//;/^$/d' "$include_file" > "${include_file}.tmp"
        filter_options+=("--include-from=${include_file}.tmp")
        echo "Using include patterns from: $include_file"
        echo "Cleaned include patterns:"
        cat "${include_file}.tmp"
        echo "-----------------------------------"
    else
        # Default includes if no file specified (adjust as needed)
        echo "No include file specified, using defaults: *.c, *.h"
        filter_options+=("--include=*.c")
        filter_options+=("--include=*.h")
        echo "-----------------------------------"
    fi

    # Exclude everything else that wasn't explicitly included by preceding rules
    filter_options+=("--exclude=*")
    # --- End Filter Rules Setup ---


    # Define color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    while IFS=: read -r source target; do
        # --- Start Directory Checks ---
        local skip_pair=false
        echo "Processing pair: $source -> $target"

        # Check source directory
        if [ ! -d "$source" ]; then
            echo -e "${YELLOW}Warning:${NC} Source path '$source' is not a directory. Skipping this pair." >&2
            skip_pair=true
            error_occurred=true
        elif [ ! -r "$source" ]; then
            echo -e "${YELLOW}Warning:${NC} Source directory '$source' is not readable. Skipping this pair." >&2
            skip_pair=true
            error_occurred=true
        fi

        # Check target directory / parent directory (only if source is ok)
        if [ "$skip_pair" = false ]; then
            target_parent=$(dirname "$target")
            if [ -e "$target" ]; then # Target exists
                if [ ! -d "$target" ]; then
                    echo -e "${YELLOW}Warning:${NC} Target path '$target' exists but is not a directory. Skipping this pair." >&2
                    skip_pair=true
                    error_occurred=true
                elif [ ! -w "$target" ]; then
                     echo -e "${YELLOW}Warning:${NC} Target directory '$target' is not writable. Skipping this pair." >&2
                     skip_pair=true
                     error_occurred=true
                fi
            else # Target does not exist, check parent
                 # Create target parent directory first if possible/needed, rsync might handle this, but checking writability is good.
                 if [ ! -d "$target_parent" ]; then
                     echo -e "${YELLOW}Warning:${NC} Parent directory '$target_parent' for target '$target' does not exist or is not a directory. Skipping this pair." >&2
                     skip_pair=true
                     error_occurred=true
                 elif [ ! -w "$target_parent" ]; then
                     echo -e "${YELLOW}Warning:${NC} Parent directory '$target_parent' for target '$target' is not writable. Skipping this pair." >&2
                     skip_pair=true
                     error_occurred=true
                 fi
            fi
        fi

        if [ "$skip_pair" = true ]; then
             echo "-----------------------------------"
             continue # Skip to the next pair in the map file
        fi
        # --- End Directory Checks ---


        echo "Syncing from $source to $target"
        # Construct the rsync command string for display (optional but helpful)
        rsync_cmd_str="rsync -avi --checksum --no-times --no-perms --no-owner --no-group --itemize-changes ${filter_options[*]} $dry_run_option \"$source\" \"$target\""
        echo "rsync command: $rsync_cmd_str"

        # Execute the rsync command
        rsync -avi --checksum --no-times --no-perms --no-owner --no-group --itemize-changes \
              "${filter_options[@]}" \
              $dry_run_option \
              "$source" "$target" | while read -r line; do
            # Colorizing logic based on itemized output
            action="${line:0:1}"
            file="${line:12}" # Adjust index based on rsync output format if needed
            case "$action" in
                "<") # Deletion
                    echo -e "${RED}Deleted:${NC} $file"
                    ;;
                ">") # Transfer
                    if [[ $line == *"f"+* ]]; then # Added file
                        echo -e "${GREEN}Added:${NC} $file"
                    elif [[ $line == *"f."* ]]; then # Changed file content/metadata
                        echo -e "${YELLOW}Changed (content):${NC} $file"
                    elif [[ $line == *"d"* ]]; then # Directory change
                        echo -e "${BLUE}Changed (directory):${NC} $file"
                    else # Other transferred item
                        echo -e "${BLUE}Changed:${NC} $file"
                    fi
                    ;;
                "c") # Metadata change
                    echo -e "${YELLOW}Changed (metadata):${NC} $file"
                    ;;
                "h") # Hardlink
                    echo -e "${BLUE}Hardlink:${NC} $file"
                    ;;
                ".") # Attribute changes only (usually ignored visually unless needed)
                    # echo -e "${NC}Attribute change:${NC} $line" # Uncomment if needed
                    ;;
                *) # Unexpected itemized output
                    echo "Other change: $line"
                    ;;
            esac
        done
        # Check rsync exit status if needed ( $? after the pipe might be tricky, need process substitution or other methods)
        echo "-----------------------------------"
    done < "$map_file"

    # Clean up temporary file
    if [ -n "$include_file" ] && [ -f "${include_file}.tmp" ]; then
        rm "${include_file}.tmp"
    fi

    # Optionally, report if any errors occurred during checks
    if [ "$error_occurred" = true ]; then
        echo -e "${YELLOW}Warning:${NC} One or more source/target directory issues were encountered. See details above." >&2
        # Optionally exit with an error code if checks failed
        # exit 1
    fi
}

# Parse command line arguments
MAP_FILE="$DEFAULT_MAP_FILE"
DRY_RUN=false # Default to actual run unless --dry-run is specified

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --run)
            DRY_RUN=false # Explicitly set to false, though it's the default
            shift
            ;;
        --map-file)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --map-file requires an argument." >&2; show_help; exit 1;
            fi
            MAP_FILE="$2"
            shift 2
            ;;
        --include)
             if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --include requires an argument." >&2; show_help; exit 1;
            fi
            INCLUDE_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Check if the map file exists and is readable
if [ ! -f "$MAP_FILE" ]; then
    echo "Map file not found: $MAP_FILE" >&2
    # Consider if creating a sample is appropriate or just erroring out
    # echo "Creating a sample one at the default location."
    # echo "/path/to/source:/path/to/target" > "$DEFAULT_MAP_FILE"
    # echo "Please edit $DEFAULT_MAP_FILE to add your source:target mappings."
    exit 1
elif [ ! -r "$MAP_FILE" ]; then
     echo "Map file not readable: $MAP_FILE" >&2
     exit 1
fi

# Check if the include file exists and is readable (only if specified)
if [ -n "$INCLUDE_FILE" ]; then
    if [ ! -f "$INCLUDE_FILE" ]; then
        echo "Include file not found: $INCLUDE_FILE" >&2
        exit 1
    elif [ ! -r "$INCLUDE_FILE" ]; then
        echo "Include file not readable: $INCLUDE_FILE" >&2
        exit 1
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo "Performing dry run..."
else
    echo "Performing actual sync..."
    # Add a safety prompt for actual run?
    # read -p "Press Enter to continue or Ctrl+C to abort..."
fi

perform_rsync $DRY_RUN "$MAP_FILE" "$INCLUDE_FILE"

echo "Sync operation completed."
exit 0 # Explicitly exit with success