#!/bin/bash

# Debug control - set to "true" to enable debug output, "false" to disable
DEBUG="false"

# Exit on any error
set -e

# Debug logging function with control switch
debug_log() {
    if [ "$DEBUG" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ~/Downloads/hazel_log2.txt
    fi
}

# Function to extract zip file
extract_export() {
    local zip_path="$1"
    local extract_dir="${zip_path%.*}"
    
    debug_log "EXTRACT: Starting extraction of zip file"
    debug_log "EXTRACT: Input zip path: $zip_path"
    debug_log "EXTRACT: Target extraction directory: $extract_dir"
    
    if [ -f "$zip_path" ]; then
        debug_log "EXTRACT: Zip file exists, proceeding with extraction"
        unzip -q "$zip_path" -d "$extract_dir"
        debug_log "EXTRACT: Extraction completed successfully"
    else
        debug_log "EXTRACT: ERROR - Zip file not found: $zip_path"
        exit 1
    fi
    
    debug_log "EXTRACT: Extraction directory contents:"
    ls -la "$extract_dir" >> ~/Downloads/hazel_log2.txt
    
    echo "$extract_dir"
}

# Function to clean folder names
clean_folders() {
    local export_dir="$1"
    
    debug_log "CLEAN: Starting folder cleanup"
    debug_log "CLEAN: Working with export directory: $export_dir"
    
    # Check if there's a markdown file at root
    local md_files=("$export_dir"/*.md)
    local md_file="${md_files[0]}"
    
    if [ -f "$md_file" ]; then
        debug_log "CLEAN: Found markdown file at root: $md_file"
        local clean_name=$(basename "$md_file" | sed -E 's/[[:space:]][[:alnum:]]{32}\.md$/.md/')
        clean_name=${clean_name%.md}  # Remove .md extension for folder name
        debug_log "CLEAN: Cleaned name will be: $clean_name"
        
        # Create a folder for the content
        mkdir -p "$export_dir/$clean_name"
        debug_log "CLEAN: Created new folder: $export_dir/$clean_name"
        
        # Move markdown file
        mv "$md_file" "$export_dir/$clean_name.md"
        debug_log "CLEAN: Moved markdown file to: $export_dir/$clean_name.md"
        
        # Rename main export folder
        local final_dir="$(dirname "$export_dir")/$clean_name"
        debug_log "CLEAN: Renaming main folder to: $final_dir"
        mv "$export_dir" "$final_dir"
        debug_log "CLEAN: Main folder renamed successfully"
        
        debug_log "CLEAN: Final directory structure:"
        ls -la "$final_dir" >> ~/Downloads/hazel_log2.txt
        
        echo "$final_dir:$clean_name"
    else
        debug_log "CLEAN: ERROR - No markdown file found"
        exit 1
    fi
}

# Function to organize assets
# Function to organize assets and clean up empty folders
organize_assets() {
    local dir_path="$1"
    local clean_name="$2"
    
    debug_log "ASSETS: Starting assets organization"
    debug_log "ASSETS: Working in directory: $dir_path"
    
    # Create assets directory
    local assets_dir="$dir_path/assets"
    mkdir -p "$assets_dir"
    debug_log "ASSETS: Created assets directory: $assets_dir"
    
    # First, move all images to assets directory
    debug_log "ASSETS: Moving image files to assets directory"
    find "$dir_path" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" \) -not -path "*/assets/*" -exec mv {} "$assets_dir/" \;
    
    # Log the initial state after moving images
    debug_log "ASSETS: Directory structure after moving images:"
    ls -la "$dir_path" >> ~/Downloads/hazel_log2.txt
    
    # Now clean up any empty folders
    debug_log "ASSETS: Cleaning up empty folders"
    
    # Find all directories except assets and the root directory itself
    find "$dir_path" -mindepth 1 -type d -not -name "assets" | while read folder; do
        # Check if folder is empty (no files or hidden files)
        if [ -z "$(ls -A "$folder")" ]; then
            debug_log "ASSETS: Removing empty folder: $folder"
            rmdir "$folder"
        else
            debug_log "ASSETS: Folder not empty, skipping: $folder"
            ls -la "$folder" >> ~/Downloads/hazel_log2.txt
        fi
    done
    
    # Verify final structure
    debug_log "ASSETS: Final directory structure:"
    ls -la "$dir_path" >> ~/Downloads/hazel_log2.txt
    debug_log "ASSETS: Final assets directory contents:"
    ls -la "$assets_dir" >> ~/Downloads/hazel_log2.txt
    
    echo "$assets_dir"
}

# Function to fix markdown references
fix_markdown_refs() {
    local dir_path="$1"
    local clean_name="$2"
    local md_file="$dir_path/$clean_name.md"
    
    debug_log "MARKDOWN: Starting markdown reference fixes"
    debug_log "MARKDOWN: Processing file: $md_file"
    
    if [ -f "$md_file" ]; then
        debug_log "MARKDOWN: Found markdown file, proceeding with fixes"
        
        # Create backup
        cp "$md_file" "$md_file.bak"
        debug_log "MARKDOWN: Created backup at: $md_file.bak"
        
        # First fix the Notion-specific encoding and paths
        sed -i '' -E \
            -e 's/\(([^)]*%20[[:alnum:]]{32}\/)/\(assets\//' \
            -e 's/%20/ /g' \
            "$md_file"
            
        # Then ensure all image references point to assets directory
        sed -i '' -E \
            -e 's/\('"$clean_name"'\/([^)]+)\)/\(assets\/\1\)/g' \
            "$md_file"
        
        debug_log "MARKDOWN: Reference fixes completed"
        
        # Log differences
        debug_log "MARKDOWN: Changes made to file:"
        diff "$md_file.bak" "$md_file" >> ~/Downloads/hazel_log2.txt 2>&1 || true
        
        # Remove backup
        rm "$md_file.bak"
    else
        debug_log "MARKDOWN: WARNING - Markdown file not found: $md_file"
    fi
}

# Function to move to completed directory
# Function to move to completed directory
move_to_complete() {
    local dir_path="$1"
    local complete_dir="/Users/hubo/obsidian_files/OB_DT/projects/notion_bk"
    local target_path="$complete_dir/$(basename "$dir_path")"
    
    debug_log "MOVE: Starting move to complete directory"
    debug_log "MOVE: Source directory: $dir_path"
    debug_log "MOVE: Target directory: $target_path"
    
    # Create parent directory if it doesn't exist
    if [ ! -d "$complete_dir" ]; then
        debug_log "MOVE: Creating parent directory"
        mkdir -p "$complete_dir"
    fi
    
    # Remove existing target if it exists
    if [ -d "$target_path" ]; then
        debug_log "MOVE: Removing existing directory: $target_path"
        rm -rf "$target_path"
    fi
    
    mv "$dir_path" "$complete_dir/"
    debug_log "MOVE: Directory moved successfully"
    debug_log "MOVE: Final location contents:"
    ls -la "$target_path" >> ~/Downloads/hazel_log2.txt
}

# Main process
main() {
    local zip_path="$1"
    
    debug_log "========================="
    debug_log "MAIN: Starting new process"
    debug_log "MAIN: Input file: $zip_path"
    
    # Validate input
    if [[ ! "$zip_path" =~ Export.*\.zip$ ]]; then
        debug_log "MAIN: ERROR - Invalid input file format"
        exit 1
    fi
    
    # Extract the zip file
    debug_log "MAIN: Calling extract_export"
    local extract_dir=$(extract_export "$zip_path")
    debug_log "MAIN: Extraction completed, directory: $extract_dir"
    
    # Clean folder names and get paths
    debug_log "MAIN: Calling clean_folders"
    local cleaned_info=$(clean_folders "$extract_dir")
    local final_dir=$(echo "$cleaned_info" | cut -d: -f1)
    local clean_name=$(echo "$cleaned_info" | cut -d: -f2)
    debug_log "MAIN: Cleaning completed, final directory: $final_dir"
    debug_log "MAIN: Clean name: $clean_name"
    
    # Organize assets
    debug_log "MAIN: Calling organize_assets"
    organize_assets "$final_dir" "$clean_name"
    
    # Fix markdown references
    debug_log "MAIN: Calling fix_markdown_refs"
    fix_markdown_refs "$final_dir" "$clean_name"
    
    # Move to completed directory
    debug_log "MAIN: Calling move_to_complete"
    move_to_complete "$final_dir"
    
    # Cleanup
    debug_log "MAIN: Removing original zip file"
    rm -f "$zip_path"
    
    debug_log "MAIN: Process completed successfully"
    debug_log "========================="
}

# Run the main process with error handling
{
    main "$1"
} || {
    debug_log "ERROR: Script failed with error code: $?"
    debug_log "ERROR: Failed processing file: $1"
    exit 1
}