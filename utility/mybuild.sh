#!/bin/bash
# Location: This script will be run from within the .../opensource/openwrt directory
# Purpose: Complete build process including compile_commands.json generation and path fixing.

# --- Configuration ---
LOG_FILE="compile_.log"               # Name for the build log file in the current directory
DB_FILE="compile_commands.json"       # Name for the compilation database in the current directory
# --- IMPORTANT: Set the ABSOLUTE path to your rewrite script ---
REWRITE_SCRIPT="/home/hubo/workspace/git-depot/github_repo/vim-configure/utility/rewrite_compile_commands.py" 

# --- Argument Processing ---
# Collect all arguments passed to this script for the main 'make' command
ARGS_ARRAY=()
while (($#)); do
  # Basic quoting for safety, though "${ARGS_ARRAY[@]}" handles most cases
  ARGS_ARRAY+=("$1")
  shift
done

# --- Get Current Directory ---
# Assumes this script is run from the directory where make should be executed
BUILD_DIR=$(pwd)
echo "=== Build script starting in directory: $BUILD_DIR ==="
echo # Blank line

# --- Step 1: Custom Pre-build Step ---
echo "=== Running custom pre-build step (make clean) ==="
make package/ruckus/director-webres/clean
CLEAN_EXIT_CODE=$?
if [ $CLEAN_EXIT_CODE -ne 0 ]; then
    echo "Error: 'make clean' step failed with exit code $CLEAN_EXIT_CODE. Aborting."
    exit 1
fi
echo "=== Custom pre-build step finished successfully ==="
echo # Blank line

# --- Step 2: Main Build Process & Log Capture ---
echo "=== Starting main build process (logging to $LOG_FILE) ==="
echo "Running: make V=s ${ARGS_ARRAY[@]}"

# Run make, ensuring UTF-8 locale for output consistency.
# Redirect both stdout and stderr (2>&1) to tee.
# tee writes to the log file and also shows output on the console.
# Pass collected arguments using "${ARGS_ARRAY[@]}" which handles spaces correctly.
LC_ALL=C.UTF-8 make V=s "${ARGS_ARRAY[@]}" 2>&1 | tee "$LOG_FILE"

# Capture the exit status of 'make' (the command on the left side of the pipe)
BUILD_EXIT_CODE=${PIPESTATUS[0]}

# Check if the main build succeeded
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo "Warning: Main build process failed with exit code $BUILD_EXIT_CODE."
    echo "Attempting to generate $DB_FILE from the partial log anyway..."
else
    echo "=== Main build process finished successfully ==="
fi
echo # Blank line

# --- Step 3: Generate initial compile_commands.json from Log ---
echo "=== Generating initial $DB_FILE from $LOG_FILE using compiledb ==="

# Check if the log file was actually created (important if make failed early)
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found. Cannot generate $DB_FILE."
    # Exit with the build code if the log wasn't even created
    exit $BUILD_EXIT_CODE 
fi

# Run compiledb in Snoop mode (-S) parsing the log file.
# Ensure UTF-8 locale for compiledb's parsing process.
LC_ALL=C.UTF-8 compiledb -S -v -f -p "$LOG_FILE" -o "$DB_FILE"
COMPILEDB_EXIT_CODE=$?

# Check if compiledb succeeded
if [ $COMPILEDB_EXIT_CODE -ne 0 ]; then
    echo "Error: compiledb failed to generate $DB_FILE from $LOG_FILE (Exit code: $COMPILEDB_EXIT_CODE)."
    # Exit with a specific error code if DB generation fails, but after a potentially failed build
    exit 2 
else
    echo "=== Initial $DB_FILE generated successfully ==="
fi
echo # Blank line

# --- Step 4: Rewrite Paths in compile_commands.json ---
echo "=== Rewriting paths in $DB_FILE to point to source locations ==="

# Check if the rewrite script exists
if [ ! -f "$REWRITE_SCRIPT" ]; then
    echo "Error: Rewrite script '$REWRITE_SCRIPT' not found. Skipping path rewrite."
    echo "Warning: $DB_FILE may contain build_dir paths."
elif [ ! -f "$DB_FILE" ]; then
    echo "Error: Database file '$DB_FILE' not found (should not happen if compiledb succeeded). Cannot rewrite."
    # Exit with a specific error code
    exit 3 
else
    # Execute the rewrite script, passing the generated DB file as input
    # The Python script is configured to overwrite the input file by default
    echo "Executing: $REWRITE_SCRIPT $DB_FILE"
    "$REWRITE_SCRIPT" "$DB_FILE" 
    REWRITE_EXIT_CODE=$?
    if [ $REWRITE_EXIT_CODE -ne 0 ]; then
        echo "Error: Path rewriting failed with exit code $REWRITE_EXIT_CODE."
        echo "Warning: $DB_FILE may contain build_dir paths."
        # Decide if this is fatal - maybe exit 3? Or let it continue with the build exit code?
        # For now, we'll just warn and continue, exiting with the build status.
    else
        echo "=== Path rewriting complete. $DB_FILE updated. ==="
    fi
fi
echo # Blank line


echo "=== Build script finished ==="
# Exit with the original build exit code, so CI systems or callers
# know if the primary build succeeded or failed.
exit $BUILD_EXIT_CODE 
