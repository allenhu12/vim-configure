#!/bin/bash
# Location: This script will be run from within the .../opensource/openwrt directory
# Purpose: Complete build process including compile_commands.json generation and path fixing.
#          Optionally compiles only a specific module and integrates its compile commands.
#          Optionally skips compile_commands.json update entirely.

# --- Configuration ---
MAIN_LOG_FILE="compile_.log"             # Name for the main build log file
MAIN_DB_FILE="compile_commands.json"     # Name for the main compilation database
# --- IMPORTANT: Set the ABSOLUTE path to your rewrite script ---
REWRITE_SCRIPT="/home/hubo/workspace/git-depot/github_repo/vim-configure/utility/rewrite_compile_commands.py"

# --- Flags ---
SHOULD_UPDATE_DB=0 # Default: Do not update the DB

# --- Usage/Help Function ---
print_usage() {
    echo "Usage: $0 [module_path] [make_options...] [update_db=true] [-h|--help]"
    echo ""
    echo "Builds the OpenWrt project and optionally generates/updates compile_commands.json."
    echo ""
    echo "Options:"
    echo "  module_path       (Optional) Path to a specific module to clean and compile"
    echo "                    (e.g., package/ruckus/librsm)."
    echo "                    If omitted, a full build is performed."
    echo ""
    echo "  make_options...   (Optional) Any additional options to pass directly to the 'make'"
    echo "                    command during a full build (ignored for module builds)."
    echo "                    Example: -j1 V=sc"
    echo ""
    echo "  update_db=true    (Optional) If present, the script will generate/update"
    echo "                    the '$MAIN_DB_FILE' using 'compiledb',"
    echo "                    run the rewrite script ('$REWRITE_SCRIPT'),"
    echo "                    and integrate the results."
    echo "                    If omitted (default), these database steps are skipped."
    echo ""
    echo "  -h, --help        Display this help message and exit."
    echo ""
    echo "Examples:"
    echo "  $0                              # Full build, skip DB update"
    echo "  $0 update_db=true               # Full build, update DB"
    echo "  $0 -j8 V=sc                     # Full build with options, skip DB update"
    echo "  $0 -j8 V=sc update_db=true      # Full build with options, update DB"
    echo "  $0 package/feeds/ruckus/librsm  # Build only librsm, skip DB update"
    echo "  $0 package/feeds/ruckus/librsm update_db=true # Build only librsm, update DB"

}

# --- Argument Processing ---
MODULE_PATH=""
ARGS_ARRAY=()
FILTERED_ARGS=()

# Check for help flag first, then separate update_db flag and filter other arguments
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      print_usage
      exit 0
      ;;
    update_db=true)
      SHOULD_UPDATE_DB=1
      ;;
    *)
      FILTERED_ARGS+=("$arg")
      ;;
  esac
done

# Determine module path vs full build args from filtered list
if [[ ${#FILTERED_ARGS[@]} -gt 0 ]]; then
    # Heuristic: If the first remaining argument looks like a path (contains '/'),
    # treat it as a module path. Otherwise, assume full build with args.
    # You might need to adjust this heuristic based on your typical make arguments.
    if [[ "${FILTERED_ARGS[0]}" == */* ]]; then
        MODULE_PATH=$(echo "${FILTERED_ARGS[0]}" | sed 's:/*$::') # Remove trailing slash
    else
        # Assume full build, pass all filtered args to make
        ARGS_ARRAY=("${FILTERED_ARGS[@]}")
    fi
    # If it was determined to be a module path, don't pass it as a make argument
    if [[ -n "$MODULE_PATH" ]]; then
        echo "=== Module build requested for: $MODULE_PATH ==="
        # Generate temporary filenames based on module path (replace / with _)
        MODULE_PATH_SAFE=$(echo "$MODULE_PATH" | tr '/' '_')
        TMP_LOG_FILE="compile_${MODULE_PATH_SAFE}.log"
        TMP_DB_FILE="compile_commands_${MODULE_PATH_SAFE}.json"
    else
         echo "=== Full build requested with arguments: ${ARGS_ARRAY[@]} ==="
    fi
else
    echo "=== Full build requested (no arguments) ==="
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

    # Determine log file based on whether DB update is enabled
    CURRENT_LOG_FILE=""
    if [ "$SHOULD_UPDATE_DB" -eq 1 ]; then
        CURRENT_LOG_FILE="$TMP_LOG_FILE"
        echo "--- Step 2: Compiling module: $MODULE_PATH (logging to $CURRENT_LOG_FILE for DB update) ---"
    else
        # Log to a temporary file that will be discarded, or /dev/null if no log needed
        CURRENT_LOG_FILE=$(mktemp) # Log to a disposable temp file
        echo "--- Step 2: Compiling module: $MODULE_PATH (logging disabled for DB) ---"
    fi

    echo "Running: make ${MODULE_PATH}/compile V=s"
    LC_ALL=C.UTF-8 make "${MODULE_PATH}/compile" V=s 2>&1 | tee "$CURRENT_LOG_FILE"
    BUILD_EXIT_CODE=${PIPESTATUS[0]}

    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        echo "Warning: Module build process failed with exit code $BUILD_EXIT_CODE."
        # If DB update was intended, try generating from partial log
        if [ "$SHOULD_UPDATE_DB" -eq 1 ]; then
            echo "Attempting to generate DB from the partial log anyway..."
        fi
    else
        echo "--- Module build process finished successfully ---"
    fi
    echo # Blank line

    # --- DB Update Steps (Conditional) ---
    if [ "$SHOULD_UPDATE_DB" -eq 1 ]; then
        echo "--- Step 3: Generate temporary $TMP_DB_FILE from $TMP_LOG_FILE ---"
        if [ ! -f "$TMP_LOG_FILE" ]; then
            echo "Error: Log file '$TMP_LOG_FILE' not found. Cannot generate compile database."
            COMPILEDB_EXIT_CODE=1 # Mark as failed
        else
            LC_ALL=C.UTF-8 compiledb -S -v -f -p "$TMP_LOG_FILE" -o "$TMP_DB_FILE"
            COMPILEDB_EXIT_CODE=$?

            if [ $COMPILEDB_EXIT_CODE -ne 0 ]; then
                echo "Error: compiledb failed to generate $TMP_DB_FILE (Exit code: $COMPILEDB_EXIT_CODE)."
            elif [ ! -s "$TMP_DB_FILE" ]; then
                echo "Warning: compiledb ran but $TMP_DB_FILE is empty or does not exist."
                COMPILEDB_EXIT_CODE=1 # Mark as failed if file is empty
            else
                echo "--- Temporary $TMP_DB_FILE generated successfully ---"
            fi
        fi
        echo # Blank line

        if [ $COMPILEDB_EXIT_CODE -eq 0 ]; then
            echo "--- Step 4: Rewriting paths in temporary $TMP_DB_FILE ---"
            echo "Executing: $REWRITE_SCRIPT $TMP_DB_FILE"
            "$REWRITE_SCRIPT" "$TMP_DB_FILE"
            REWRITE_EXIT_CODE=$?
            if [ $REWRITE_EXIT_CODE -ne 0 ]; then
                echo "Error: Path rewriting failed for $TMP_DB_FILE (Exit code $REWRITE_EXIT_CODE)."
            else
                echo "--- Path rewriting complete for $TMP_DB_FILE ---"
            fi
        else
             echo "--- Skipping rewrite due to compiledb errors ---"
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
                MODULE_DIRS_JSON=$(jq -c '[.[].directory] | unique' "$TMP_DB_FILE")

                if [ "$MODULE_DIRS_JSON" = "[]" ] || [ -z "$MODULE_DIRS_JSON" ]; then
                     echo "Warning: Could not extract source directories from $TMP_DB_FILE or it contains no entries. Skipping integration."
                     INTEGRATE_EXIT_CODE=1 # Or 0 if this isn't an error? Let's keep 1 for now.
                elif [ -f "$MAIN_DB_FILE" ]; then
                    echo "Main file $MAIN_DB_FILE exists. Merging entries."
                    # --- Debugging Output ---
                    echo "DEBUG: TMP_DB_FILE = $TMP_DB_FILE"
                    echo "DEBUG: MAIN_DB_FILE = $MAIN_DB_FILE"
                    echo "DEBUG: MODULE_DIRS_JSON = $MODULE_DIRS_JSON"
                    if ! echo "$MODULE_DIRS_JSON" | jq empty > /dev/null 2>&1; then
                         echo "Error: MODULE_DIRS_JSON content is not valid JSON: $MODULE_DIRS_JSON. Skipping integration."
                         INTEGRATE_EXIT_CODE=1
                    else
                        cp "$MAIN_DB_FILE" "${MAIN_DB_FILE}.bak"
                        jq --slurpfile moduleData "$TMP_DB_FILE" \
                           --argjson moduleDirs "$MODULE_DIRS_JSON" \
                           'map(select(.directory as $d | ($moduleDirs | index($d) | not))) + $moduleData[0]' \
                           "$MAIN_DB_FILE" > "${MAIN_DB_FILE}.new"
                        INTEGRATE_EXIT_CODE=$?
                        if [ $INTEGRATE_EXIT_CODE -eq 0 ]; then
                            if jq empty "${MAIN_DB_FILE}.new" > /dev/null 2>&1; then
                                mv "${MAIN_DB_FILE}.new" "$MAIN_DB_FILE"
                                rm "${MAIN_DB_FILE}.bak"
                                echo "--- Integration successful ---"
                            else
                                echo "Error: jq produced an invalid JSON file (${MAIN_DB_FILE}.new). Check .new and .bak files."
                                INTEGRATE_EXIT_CODE=5
                            fi
                        else
                            echo "Error: jq integration command failed (Exit code: $INTEGRATE_EXIT_CODE). Check ${MAIN_DB_FILE}.new and ${MAIN_DB_FILE}.bak"
                        fi
                     fi
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
            # Clean up temporary files only if DB update was enabled and attempted
            echo "Cleaning up temporary DB files: $TMP_LOG_FILE, $TMP_DB_FILE"
            rm -f "$TMP_LOG_FILE" "$TMP_DB_FILE"
        else
            echo "--- Skipping integration due to previous errors ---"
            # Clean up potentially invalid temp db file if rewrite didn't run or failed
            if [ -f "$TMP_DB_FILE" ]; then
                 echo "Cleaning up potentially invalid temporary file: $TMP_DB_FILE"
                 rm -f "$TMP_DB_FILE"
            fi
             # Also remove the log file if DB update was intended but failed early
            if [ -f "$TMP_LOG_FILE" ]; then
                 rm -f "$TMP_LOG_FILE"
            fi
            INTEGRATE_EXIT_CODE=1
        fi
        echo # Blank line
    else
         # DB update was disabled, clean up the temporary log file if created
         if [[ "$CURRENT_LOG_FILE" != "$TMP_LOG_FILE" ]] && [ -f "$CURRENT_LOG_FILE" ]; then
              echo "Cleaning up temporary log file: $CURRENT_LOG_FILE"
              rm -f "$CURRENT_LOG_FILE"
         fi
    fi # End of conditional DB update steps

else
    # --- Full Build ---
    echo "--- Step 1: Custom Pre-build Step (make clean) ---"
    make package/ruckus/director-webres/clean
    CLEAN_EXIT_CODE=$?
    if [ $CLEAN_EXIT_CODE -ne 0 ]; then
        echo "Error: 'make clean' step failed with exit code $CLEAN_EXIT_CODE. Aborting."
        exit 1
    fi
    echo "--- Custom pre-build step finished successfully ---"
    echo # Blank line

    # Determine log file based on whether DB update is enabled
    CURRENT_LOG_FILE=""
    if [ "$SHOULD_UPDATE_DB" -eq 1 ]; then
        CURRENT_LOG_FILE="$MAIN_LOG_FILE"
        echo "--- Step 2: Main Build Process & Log Capture (logging to $CURRENT_LOG_FILE for DB update) ---"
    else
        # Log to a temporary file that will be discarded, or /dev/null if no log needed
        CURRENT_LOG_FILE=$(mktemp) # Log to a disposable temp file
        echo "--- Step 2: Main Build Process & Log Capture (logging disabled for DB) ---"
    fi

    echo "Running: make V=s ${ARGS_ARRAY[@]}"
    LC_ALL=C.UTF-8 make V=s "${ARGS_ARRAY[@]}" 2>&1 | tee "$CURRENT_LOG_FILE"
    BUILD_EXIT_CODE=${PIPESTATUS[0]}

    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        echo "Warning: Main build process failed with exit code $BUILD_EXIT_CODE."
        if [ "$SHOULD_UPDATE_DB" -eq 1 ]; then
            echo "Attempting to generate DB from the partial log anyway..."
        fi
    else
        echo "--- Main build process finished successfully ---"
    fi
    echo # Blank line

    # --- DB Update Steps (Conditional) ---
    if [ "$SHOULD_UPDATE_DB" -eq 1 ]; then
        TMP_DB_FILE="${MAIN_DB_FILE}.latest" # Define temp file name for full build
        echo "--- Step 3: Generate temporary DB ($TMP_DB_FILE) from $MAIN_LOG_FILE ---"

        if [ ! -f "$MAIN_LOG_FILE" ]; then
            echo "Error: Log file '$MAIN_LOG_FILE' not found. Cannot generate DB."
            COMPILEDB_EXIT_CODE=1
        else
            LC_ALL=C.UTF-8 compiledb -S -v -f -p "$MAIN_LOG_FILE" -o "$TMP_DB_FILE"
            COMPILEDB_EXIT_CODE=$?

            if [ $COMPILEDB_EXIT_CODE -ne 0 ]; then
                echo "Error: compiledb failed to generate temporary DB $TMP_DB_FILE (Exit code: $COMPILEDB_EXIT_CODE)."
            elif [ ! -s "$TMP_DB_FILE" ]; then
                 echo "Warning: compiledb ran but temporary DB $TMP_DB_FILE is empty or does not exist."
                 COMPILEDB_EXIT_CODE=1
            else
                echo "--- Temporary DB $TMP_DB_FILE generated successfully ---"
            fi
        fi
        echo # Blank line

        if [ $COMPILEDB_EXIT_CODE -eq 0 ]; then
            echo "--- Step 4: Rewrite Paths in temporary DB $TMP_DB_FILE ---"
            echo "Executing: $REWRITE_SCRIPT $TMP_DB_FILE"
            "$REWRITE_SCRIPT" "$TMP_DB_FILE"
            REWRITE_EXIT_CODE=$?
            if [ $REWRITE_EXIT_CODE -ne 0 ]; then
                echo "Error: Path rewriting failed for $TMP_DB_FILE (Exit code $REWRITE_EXIT_CODE)."
            else
                echo "--- Path rewriting complete for $TMP_DB_FILE ---"
            fi
        else
             echo "--- Skipping rewrite due to compiledb errors ---"
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
                LATEST_DIRS_JSON=$(jq -c '[.[].directory] | unique' "$TMP_DB_FILE")

                if [ "$LATEST_DIRS_JSON" = "[]" ] || [ -z "$LATEST_DIRS_JSON" ]; then
                     echo "Warning: Could not extract source directories from $TMP_DB_FILE or it contains no entries. Skipping integration."
                     INTEGRATE_EXIT_CODE=0 # Not an error if nothing to merge
                elif [ -f "$MAIN_DB_FILE" ]; then
                    echo "Main file $MAIN_DB_FILE exists. Merging entries."
                    # --- Debugging Output ---
                    echo "DEBUG: TMP_DB_FILE = $TMP_DB_FILE"
                    echo "DEBUG: MAIN_DB_FILE = $MAIN_DB_FILE"
                    echo "DEBUG: LATEST_DIRS_JSON = $LATEST_DIRS_JSON"
                     if ! echo "$LATEST_DIRS_JSON" | jq empty > /dev/null 2>&1; then
                         echo "Error: LATEST_DIRS_JSON content is not valid JSON: $LATEST_DIRS_JSON. Skipping integration."
                         INTEGRATE_EXIT_CODE=1
                    else
                        cp "$MAIN_DB_FILE" "${MAIN_DB_FILE}.bak"
                        jq --slurpfile latestData "$TMP_DB_FILE" \
                           --argjson latestDirs "$LATEST_DIRS_JSON" \
                           'map(select(.directory as $d | ($latestDirs | index($d) | not))) + $latestData[0]' \
                           "$MAIN_DB_FILE" > "${MAIN_DB_FILE}.new"
                        INTEGRATE_EXIT_CODE=$?
                        if [ $INTEGRATE_EXIT_CODE -eq 0 ]; then
                            if jq empty "${MAIN_DB_FILE}.new" > /dev/null 2>&1; then
                                mv "${MAIN_DB_FILE}.new" "$MAIN_DB_FILE"
                                rm "${MAIN_DB_FILE}.bak"
                                echo "--- Integration successful ---"
                            else
                                echo "Error: jq produced an invalid JSON file (${MAIN_DB_FILE}.new). Check .new and .bak files."
                                INTEGRATE_EXIT_CODE=5
                            fi
                        else
                            echo "Error: jq integration command failed (Exit code: $INTEGRATE_EXIT_CODE). Check ${MAIN_DB_FILE}.new and ${MAIN_DB_FILE}.bak"
                        fi
                     fi
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
            # Clean up temporary files for full build DB update
            echo "Cleaning up temporary DB files: $MAIN_LOG_FILE, $TMP_DB_FILE"
            rm -f "$MAIN_LOG_FILE" "$TMP_DB_FILE"
        else
            echo "--- Skipping integration due to previous errors ---"
            # Clean up potentially invalid temp db file
            if [ -f "$TMP_DB_FILE" ]; then
                 echo "Cleaning up potentially invalid temporary file: $TMP_DB_FILE"
                 rm -f "$TMP_DB_FILE"
            fi
             # Also remove the log file if DB update was intended but failed early
            if [ -f "$MAIN_LOG_FILE" ]; then
                 rm -f "$MAIN_LOG_FILE"
            fi
            INTEGRATE_EXIT_CODE=1
        fi
        echo # Blank line
    else
         # DB update was disabled, clean up the temporary log file if created
         if [[ "$CURRENT_LOG_FILE" != "$MAIN_LOG_FILE" ]] && [ -f "$CURRENT_LOG_FILE" ]; then
              echo "Cleaning up temporary log file: $CURRENT_LOG_FILE"
              rm -f "$CURRENT_LOG_FILE"
         fi
    fi # End of conditional DB update steps

fi # End of module vs full build logic

# --- Final Summary ---
echo "=== Build script finished ==="
FINAL_EXIT_CODE=0
# Prioritize build failure exit code
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo "Build/Compile step failed (Exit Code: $BUILD_EXIT_CODE)"
    FINAL_EXIT_CODE=$BUILD_EXIT_CODE
# Only report DB errors if DB update was enabled
elif [ "$SHOULD_UPDATE_DB" -eq 1 ]; then
    if [ $COMPILEDB_EXIT_CODE -ne 0 ]; then
        echo "Compile DB generation step failed (Exit Code: $COMPILEDB_EXIT_CODE)"
        FINAL_EXIT_CODE=2 # Use compiledb specific error code
    elif [ $REWRITE_EXIT_CODE -ne 0 ]; then
        echo "Path rewriting step failed (Exit Code: $REWRITE_EXIT_CODE)"
        FINAL_EXIT_CODE=3 # Use rewrite specific error code
    elif [ $INTEGRATE_EXIT_CODE -ne 0 ]; then
        # Distinguish between jq failure and other integration issues
        if [ $INTEGRATE_EXIT_CODE -eq 5 ]; then
             echo "Integration step failed: jq produced invalid output (Exit Code: $INTEGRATE_EXIT_CODE)"
        else
             echo "Integration step failed (Exit Code: $INTEGRATE_EXIT_CODE)"
        fi
        FINAL_EXIT_CODE=4 # Use integration specific error code
    fi
fi

if [ $FINAL_EXIT_CODE -eq 0 ]; then
    echo "Result: SUCCESS"
    if [ "$SHOULD_UPDATE_DB" -ne 1 ]; then
        echo "(compile_commands.json update was skipped)"
    fi
else
    echo "Result: FAILED (Exit Code: $FINAL_EXIT_CODE)"
fi

exit $FINAL_EXIT_CODE 
