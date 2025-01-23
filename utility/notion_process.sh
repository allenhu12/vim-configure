#!/bin/bash

# Exit on any error
set -e

# Debug logging function
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ~/Downloads/hazel_log2.txt
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
    
    # Find and clean the inner folder name
    local inner_folder=$(find "$export_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    debug_log "CLEAN: Found inner folder: $inner_folder"
    
    local clean_name=$(basename "$inner_folder" | sed -E 's/[[:space:]][[:alnum:]]{32}$//')
    debug_log "CLEAN: Cleaned name will be: $clean_name"
    
    # Rename inner folder
    debug_log "CLEAN: Renaming inner folder"
    mv "$inner_folder" "$(dirname "$inner_folder")/$clean_name"
    debug_log "CLEAN: Inner folder renamed successfully"
    
    # Rename markdown file
    local md_file="${inner_folder}.md"
    if [ -f "$md_file" ]; then
        debug_log "CLEAN: Found markdown file: $md_file"
        mv "$md_file" "$(dirname "$md_file")/$clean_name.md"
        debug_log "CLEAN: Markdown file renamed to: $clean_name.md"
    else
        debug_log "CLEAN: No markdown file found at: $md_file"
    fi
    
    # Rename main export folder
    local final_dir="$(dirname "$export_dir")/$clean_name"
    debug_log "CLEAN: Renaming main folder to: $final_dir"
    mv "$export_dir" "$final_dir"
    debug_log "CLEAN: Main folder renamed successfully"
    
    debug_log "CLEAN: Final directory structure:"
    ls -la "$final_dir" >> ~/Downloads/hazel_log2.txt
    
    echo "$final_dir:$clean_name"
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
        
        # Fix image references
        debug_log "MARKDOWN: Replacing folder references with: $clean_name"
        sed -i '' -E \
            -e 's/\(([^)]*%20[[:alnum:]]{32}\/)/\('"$clean_name"'\//' \
            -e 's/%20/ /g' \
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
move_to_complete() {
    local dir_path="$1"
    local complete_dir=/Users/hubo/obsidian_files/OB_DT/projects/notion_bk
    
    debug_log "MOVE: Starting move to complete directory"
    debug_log "MOVE: Source directory: $dir_path"
    debug_log "MOVE: Target directory: $complete_dir"
    
    # Create complete directory if it doesn't exist
    if [ ! -d "$complete_dir" ]; then
        debug_log "MOVE: Creating complete directory"
        mkdir -p "$complete_dir"
    fi
    
    mv "$dir_path" "$complete_dir/"
    debug_log "MOVE: Directory moved successfully"
    debug_log "MOVE: Final location contents:"
    ls -la "$complete_dir/$(basename "$dir_path")" >> ~/Downloads/hazel_log2.txt
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