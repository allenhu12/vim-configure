#!/bin/bash
#
# move_firmware.sh (DEBUG VERSION - LOG FILE) - PRECISE VERSION REGEX (200.XX)
#
# Usage: DEBUG=1 move_firmware.sh "/path/to/file"
#
# Enable debug output by setting DEBUG=1
# Logs to: /Users/hubo/Downloads/images_bk/debug.log
########################################################################

# Debug configuration
DEBUG_MODE="${DEBUG:-0}"
SCRIPT_NAME=$(basename "$0")
LOG_FILE="/Users/hubo/Downloads/images_bk/debug.log"

# Ensure log file exists and is writable (optional, but good practice)
touch "$LOG_FILE"

if [ ! -w "$LOG_FILE" ]; then
  echo "Error: Log file '$LOG_FILE' is not writable. Debug logging disabled."
  DEBUG_MODE=0
fi

dblog() {
  if [ "$DEBUG_MODE" -eq 1 ]; then
    echo "[DEBUG] $SCRIPT_NAME: $1" >> "$LOG_FILE"
  fi
}

# Get file info
FILEPATH="$1"
FILENAME="$(basename "$FILEPATH")"

dblog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
dblog "Processing file: $FILENAME"
dblog "Full path: $FILEPATH"

# Version extraction (using precise regex - starts with 200. and 2-3 digits)
RAW_VERSION=$(echo "$FILENAME" | grep -Eo '200\.[0-9]{2,3}\b' | head -n 1)
VERSION=$(echo "$RAW_VERSION" | cut -d. -f1-2 2>/dev/null)

dblog "Raw version match: ${RAW_VERSION:-<none>}"
dblog "Processed version: ${VERSION:-<none>}"

# Model extraction (Improved - search entire filename, case-insensitive, take LAST match)
MODEL_RAW=$(echo "$FILENAME" | grep -Eio '[A-Z][0-9]{3}' | tail -n 1)
MODEL=$(echo "$MODEL_RAW" | tr '[:lower:]' '[:upper:]') # Portable uppercase conversion

dblog "Model candidate raw match: ${MODEL_RAW:-<none>}"
dblog "Model candidate: ${MODEL:-<none>}"


# Directory construction
BASEDIR="$HOME/Downloads/images_bk"
DESTINATION="$BASEDIR"

if [ -n "$VERSION" ]; then
  DESTINATION="$BASEDIR/unleashed_$VERSION"
  if [ -n "$MODEL" ]; then
      DESTINATION="$DESTINATION/$MODEL"
  fi
fi

dblog "Base directory: $BASEDIR"
dblog "Final destination: $DESTINATION"

# File operations
dblog "Creating directory: $DESTINATION"
mkdir -vp "$DESTINATION"

dblog "Moving file: $FILEPATH ➔ $DESTINATION/"
mv -nv "$FILEPATH" "$DESTINATION/"

# Post-move verification
if [ -f "$DESTINATION/$(basename "$FILEPATH")" ]; then
  dblog "✓ Successfully moved file"
else
  dblog "✗ Failed to move file!"
fi

dblog "Processing complete for: $FILENAME"
exit 0
