#!/bin/bash
# Location: This script will be run from within the .../opensource/openwrt directory
# Purpose: Complete build process including compile_commands.json generation and path fixing.
#          Optionally compiles only a specific module and integrates its compile commands.

# --- Configuration ---
MAIN_LOG_FILE="compile_.log"             # Name for the main build log file
MAIN_DB_FILE="compile_commands.json"     # Name for the main compilation database
# --- IMPORTANT: Set the ABSOLUTE path to your rewrite script ---
REWRITE_SCRIPT="/home/hubo/workspace/git-depot/github_repo/vim-configure/utility/rewrite_compile_commands.py"

# --- Pre-requisite Check ---
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' command not found. Please install jq to proceed."
    exit 10
fi
if [ ! -f "$REWRITE_SCRIPT" ]; then
    echo "Error: Rewrite script '$REWRITE_SCRIPT' not found. Aborting."
    exit 11
fi

# --- Argument Processing ---
MODULE_PATH=""
if [ -n "$1" ]; then
    MODULE_PATH=$(echo "$1" | sed 's:/*$::') # Remove trailing slash if present
    echo "=== Module build requested for: $MODULE_PATH ==="
    # Generate temporary filenames based on module path (replace / with _)
    MODULE_PATH_SAFE=$(echo "$MODULE_PATH" | tr '/' '_')
    TMP_LOG_FILE="compile_${MODULE_PATH_SAFE}.log"
    TMP_DB_FILE="compile_commands_${MODULE_PATH_SAFE}.json"
else
    echo "=== Full build requested ==="
    # Collect all arguments passed to this script for the main 'make' command
    ARGS_ARRAY=()
    while (($#)); do
      # Basic quoting for safety, though "${ARGS_ARRAY[@]}" handles most cases
      ARGS_ARRAY+=("$1")
      shift
    done
fi
echo # Blank line

# --- Get Current Directory ---
BUILD_DIR=$(pwd)
echo "=== Build script starting in directory: $BUILD_DIR ==="
echo # Blank line

# --- Variables for results ---
BUILD_EXIT_CODE=0
COMPILEDB_EXIT_CODE=0
REWRITE_EXIT_CODE=0
INTEGRATE_EXIT_CODE=0

# --- Conditional Build Logic ---

if [ -n "$MODULE_PATH" ]; then
    # --- Module Build ---
    echo "--- Step 1: Cleaning module: $MODULE_PATH ---"
    make "${MODULE_PATH}/clean"
    CLEAN_EXIT_CODE=$?
    if [ $CLEAN_EXIT_CODE -ne 0 ]; then
        echo "Error: 'make clean' for module '$MODULE_PATH' failed with exit code $CLEAN_EXIT_CODE. Aborting."
        exit 1
    fi
    echo "--- Module clean finished successfully ---"
    echo # Blank line

    echo "--- Step 2: Compiling module: $MODULE_PATH (logging to $TMP_LOG_FILE) ---"
    echo "Running: make ${MODULE_PATH}/compile V=s"
    # Run make for the module, logging output
    LC_ALL=C.UTF-8 make "${MODULE_PATH}/compile" V=s 2>&1 | tee "$TMP_LOG_FILE"
    BUILD_EXIT_CODE=${PIPESTATUS[0]}

    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        echo "Warning: Module build process failed with exit code $BUILD_EXIT_CODE."
        echo "Attempting to generate $TMP_DB_FILE from the partial log anyway..."
    else
        echo "--- Module build process finished successfully ---"
    fi
    echo # Blank line

    echo "--- Step 3: Generate temporary $TMP_DB_FILE from $TMP_LOG_FILE ---"
    if [ ! -f "$TMP_LOG_FILE" ]; then
        echo "Error: Log file '$TMP_LOG_FILE' not found. Cannot generate compile database."
        exit $BUILD_EXIT_CODE # Exit with build code if log wasn't created
    fi

    LC_ALL=C.UTF-8 compiledb -S -v -f -p "$TMP_LOG_FILE" -o "$TMP_DB_FILE"
    COMPILEDB_EXIT_CODE=$?

    if [ $COMPILEDB_EXIT_CODE -ne 0 ]; then
        echo "Error: compiledb failed to generate $TMP_DB_FILE (Exit code: $COMPILEDB_EXIT_CODE)."
        # Don't exit yet, allow potential cleanup/integration attempt if file exists but is invalid
    elif [ ! -s "$TMP_DB_FILE" ]; then
        echo "Warning: compiledb ran but $TMP_DB_FILE is empty or does not exist."
        COMPILEDB_EXIT_CODE=1 # Mark as failed if file is empty
    else
        echo "--- Temporary $TMP_DB_FILE generated successfully ---"
    fi
    echo # Blank line

    if [ $COMPILEDB_EXIT_CODE -eq 0 ]; then
        echo "--- Step 4: Rewriting paths in temporary $TMP_DB_FILE ---"
        echo "Executing: $REWRITE_SCRIPT $TMP_DB_FILE"
        "$REWRITE_SCRIPT" "$TMP_DB_FILE"
        REWRITE_EXIT_CODE=$?
        if [ $REWRITE_EXIT_CODE -ne 0 ]; then
            echo "Error: Path rewriting failed for $TMP_DB_FILE (Exit code $REWRITE_EXIT_CODE)."
            # Proceed to integration? Maybe not if rewrite failed. Let's stop here for safety.
            # Clean up potentially corrupted temp db? Or leave it for inspection? Leave it.
            rm -f "$TMP_LOG_FILE" # Remove log file
            exit 4 # Exit with rewrite error
        else
            echo "--- Path rewriting complete for $TMP_DB_FILE ---"
        fi
    else
         echo "--- Skipping rewrite due to compiledb errors ---"
         # Ensure rewrite code doesn't indicate success if skipped
         REWRITE_EXIT_CODE=1
    fi
    echo # Blank line

    if [ $COMPILEDB_EXIT_CODE -eq 0 ] && [ $REWRITE_EXIT_CODE -eq 0 ]; then
        echo "--- Step 5: Integrating $TMP_DB_FILE into $MAIN_DB_FILE ---"
        # Check if temp file is valid JSON before proceeding
        if ! jq '.' "$TMP_DB_FILE" > /dev/null 2>&1; then
             echo "Error: Temporary file $TMP_DB_FILE is not valid JSON. Skipping integration."
             INTEGRATE_EXIT_CODE=1
        else
            # Extract unique source directories from the rewritten temporary DB
            MODULE_DIRS_JSON=$(jq -c '[.[].directory] | unique' "$TMP_DB_FILE")

            if [ "$MODULE_DIRS_JSON" = "[]" ] || [ -z "$MODULE_DIRS_JSON" ]; then
                 echo "Warning: Could not extract source directories from $TMP_DB_FILE or it contains no entries. Skipping integration."
                 INTEGRATE_EXIT_CODE=1
            elif [ -f "$MAIN_DB_FILE" ]; then
                echo "Main file $MAIN_DB_FILE exists. Merging entries."
                # --- Debugging Output ---
                echo "DEBUG: TMP_DB_FILE = $TMP_DB_FILE"
                echo "DEBUG: MAIN_DB_FILE = $MAIN_DB_FILE"
                echo "DEBUG: MODULE_DIRS_JSON = $MODULE_DIRS_JSON"
                # Validate MODULE_DIRS_JSON is valid JSON before proceeding
                # Redirect jq output to /dev/null to silence it
                if ! echo "$MODULE_DIRS_JSON" | jq empty > /dev/null 2>&1; then
                     echo "Error: MODULE_DIRS_JSON content is not valid JSON: $MODULE_DIRS_JSON. Skipping integration."
                     INTEGRATE_EXIT_CODE=1
                else
                    # Create a backup
                    cp "$MAIN_DB_FILE" "${MAIN_DB_FILE}.bak"
                    # Use jq to filter the main file and append the module entries
                    # Revised filter 2: Explicit variable names, removed outer parens
                    jq --slurpfile moduleData "$TMP_DB_FILE" \
                       --argjson moduleDirs "$MODULE_DIRS_JSON" \
                       'map(select(.directory as $d | ($moduleDirs | index($d) | not))) + $moduleData[0]' \
                       "$MAIN_DB_FILE" > "${MAIN_DB_FILE}.new"
                    INTEGRATE_EXIT_CODE=$?
                    if [ $INTEGRATE_EXIT_CODE -eq 0 ]; then
                        # Optional: Validate the new file before moving
                        # Redirect jq output to /dev/null
                        if jq empty "${MAIN_DB_FILE}.new" > /dev/null 2>&1; then
                            mv "${MAIN_DB_FILE}.new" "$MAIN_DB_FILE"
                            rm "${MAIN_DB_FILE}.bak" # Remove backup on success
                            echo "--- Integration successful ---"
                            # You can remove the DEBUG echos above once confirmed working
                        else
                            echo "Error: jq produced an invalid JSON file (${MAIN_DB_FILE}.new). Check .new and .bak files."
                            INTEGRATE_EXIT_CODE=5 # Assign a new error code for merge output validation failure
                            # Keep backup and .new file for inspection
                        fi
                    else
                        echo "Error: jq integration command failed (Exit code: $INTEGRATE_EXIT_CODE). Check ${MAIN_DB_FILE}.new and ${MAIN_DB_FILE}.bak"
                        # Keep backup and .new file for inspection
                    fi
                 fi # End MODULE_DIRS_JSON validation
            else
                echo "Main file $MAIN_DB_FILE does not exist. Copying temporary file."
                cp "$TMP_DB_FILE" "$MAIN_DB_FILE"
                INTEGRATE_EXIT_CODE=$?
                if [ $INTEGRATE_EXIT_CODE -eq 0 ]; then
                     echo "--- Copied $TMP_DB_FILE to $MAIN_DB_FILE successfully ---"
                else
                     echo "Error: Failed to copy $TMP_DB_FILE to $MAIN_DB_FILE (Exit code: $INTEGRATE_EXIT_CODE)."
                fi
            fi
        fi
        # Clean up temporary files only if integration step was attempted (success or fail)
        echo "Cleaning up temporary files: $TMP_LOG_FILE, $TMP_DB_FILE"
        rm -f "$TMP_LOG_FILE" "$TMP_DB_FILE"
    else
        echo "--- Skipping integration due to previous errors ---"
        # Clean up potentially invalid temp db file if rewrite didn't run or failed
        if [ -f "$TMP_DB_FILE" ]; then
             echo "Cleaning up potentially invalid temporary file: $TMP_DB_FILE"
             rm -f "$TMP_DB_FILE"
        fi
        rm -f "$TMP_LOG_FILE" # Always remove log
        INTEGRATE_EXIT_CODE=1 # Mark integration as not successful
    fi
    echo # Blank line

else
    # --- Full Build ---
    echo "--- Step 1: Custom Pre-build Step (make clean) ---"
    # Note: Keeping the original clean target for the full build case.
    make package/ruckus/director-webres/clean
    CLEAN_EXIT_CODE=$?
    if [ $CLEAN_EXIT_CODE -ne 0 ]; then
        echo "Error: 'make clean' step failed with exit code $CLEAN_EXIT_CODE. Aborting."
        exit 1
    fi
    echo "--- Custom pre-build step finished successfully ---"
    echo # Blank line

    echo "--- Step 2: Main Build Process & Log Capture (logging to $MAIN_LOG_FILE) ---"
    echo "Running: make V=s ${ARGS_ARRAY[@]}"
    LC_ALL=C.UTF-8 make V=s "${ARGS_ARRAY[@]}" 2>&1 | tee "$MAIN_LOG_FILE"
    BUILD_EXIT_CODE=${PIPESTATUS[0]}

    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        echo "Warning: Main build process failed with exit code $BUILD_EXIT_CODE."
        echo "Attempting to generate $MAIN_DB_FILE from the partial log anyway..."
    else
        echo "--- Main build process finished successfully ---"
    fi
    echo # Blank line

    echo "--- Step 3: Generate $MAIN_DB_FILE from $MAIN_LOG_FILE ---"
    if [ ! -f "$MAIN_LOG_FILE" ]; then
        echo "Error: Log file '$MAIN_LOG_FILE' not found. Cannot generate $MAIN_DB_FILE."
        exit $BUILD_EXIT_CODE
    fi

    LC_ALL=C.UTF-8 compiledb -S -v -f -p "$MAIN_LOG_FILE" -o "$MAIN_DB_FILE"
    COMPILEDB_EXIT_CODE=$?

    if [ $COMPILEDB_EXIT_CODE -ne 0 ]; then
        echo "Error: compiledb failed to generate $MAIN_DB_FILE (Exit code: $COMPILEDB_EXIT_CODE)."
        exit 2
    elif [ ! -s "$MAIN_DB_FILE" ]; then
         echo "Warning: compiledb ran but $MAIN_DB_FILE is empty or does not exist."
         exit 2 # Exit if file is empty after full build attempt
    else
        echo "--- Initial $MAIN_DB_FILE generated successfully ---"
    fi
    echo # Blank line

    echo "--- Step 4: Rewrite Paths in $MAIN_DB_FILE ---"
    echo "Executing: $REWRITE_SCRIPT $MAIN_DB_FILE"
    "$REWRITE_SCRIPT" "$MAIN_DB_FILE"
    REWRITE_EXIT_CODE=$?
    if [ $REWRITE_EXIT_CODE -ne 0 ]; then
        echo "Error: Path rewriting failed for $MAIN_DB_FILE with exit code $REWRITE_EXIT_CODE."
        echo "Warning: $MAIN_DB_FILE may contain build_dir paths."
        # Exit with rewrite error code
        exit 3
    else
        echo "--- Path rewriting complete. $MAIN_DB_FILE updated. ---"
    fi
    echo # Blank line
fi

# --- Final Summary ---
echo "=== Build script finished ==="
FINAL_EXIT_CODE=0
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo "Build/Compile step failed (Exit Code: $BUILD_EXIT_CODE)"
    FINAL_EXIT_CODE=$BUILD_EXIT_CODE
elif [ $COMPILEDB_EXIT_CODE -ne 0 ]; then
    echo "Compile DB generation step failed (Exit Code: $COMPILEDB_EXIT_CODE)"
    FINAL_EXIT_CODE=2 # Use compiledb specific error code
elif [ $REWRITE_EXIT_CODE -ne 0 ]; then
    echo "Path rewriting step failed (Exit Code: $REWRITE_EXIT_CODE)"
    FINAL_EXIT_CODE=3 # Use rewrite specific error code
elif [ $INTEGRATE_EXIT_CODE -ne 0 ] && [ -n "$MODULE_PATH" ]; then
    # Only consider integration failure an error if it was attempted (module build)
    echo "Integration step failed (Exit Code: $INTEGRATE_EXIT_CODE)"
    FINAL_EXIT_CODE=4 # Use integration specific error code
fi

if [ $FINAL_EXIT_CODE -eq 0 ]; then
    echo "Result: SUCCESS"
else
    echo "Result: FAILED (Exit Code: $FINAL_EXIT_CODE)"
fi

exit $FINAL_EXIT_CODE 
