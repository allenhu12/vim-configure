#!/usr/bin/env python3

import json
import os
import sys
import argparse
import logging
from pathlib import Path
import typing # For older Python 3 type hints

# Configure logging level (e.g., logging.DEBUG for more verbose output)
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s: %(message)s')

# --- !!! IMPORTANT: DEFINE YOUR PATH MAPPINGS HERE !!! ---
# This dictionary maps the unique part of the path *within* the build directory
# (relative to BUILD_DIR_PREFIX) to the corresponding source directory path
# (relative to SOURCE_ROOT).
#
# YOU MUST ADD ENTRIES FOR ALL COMPONENTS BUILT OUT-OF-TREE.
# Key: Path segment in build_dir identifying the component
# Value: Corresponding path in source tree containing the source files (e.g., the 'src' dir)

PATH_MAPPINGS = {
    "librsm-0.1": "rks_ap/libs/librsm/src",
    # --- Add mappings for other components ---
    # Example:
    # "some-other-lib-1.2": "vendor_mtk/libs/some-other-lib/source",
    # "another-app": "rks_ap/apps/another-app/src",
    # "linux-mediatek_mt7988/some_kernel_module": "vendor_mtk_11be/mt7992/some_kernel_module/src", # Example for kernel modules if needed
}

# --- Base Paths (Adjust if necessary, but likely correct based on logs) ---
# The common prefix for build directories found in compile_commands.json
BUILD_DIR_PREFIX = "/home/hubo/workspace/git-depot/unleashed_200.18.7.101_r370/opensource/openwrt/build_dir/target-aarch64_cortex-a53_musl"
# The absolute path to the root of your source code checkout
SOURCE_ROOT = "/home/hubo/workspace/git-depot/unleashed_200.18.7.101_r370"
# --------------------------------------------------------------------

def find_source_mapping(build_dir_str: str, build_file: str) -> typing.Tuple[typing.Optional[str], typing.Optional[str]]:
    """
    Finds the corresponding source path based on PATH_MAPPINGS.
    Returns (source_directory, absolute_source_file_path) or (None, None) if no mapping applies
    or the source file doesn't exist at the mapped location.
    """
    build_dir_path = Path(build_dir_str).resolve()
    source_root_path = Path(SOURCE_ROOT).resolve()

    # Check if the build directory starts with the expected prefix
    if not build_dir_str.startswith(BUILD_DIR_PREFIX):
        logging.debug(f"Directory '{build_dir_str}' does not start with build prefix '{BUILD_DIR_PREFIX}'. Skipping mapping.")
        return None, None

    # Extract the part of the path relative to the prefix
    relative_build_path_str = build_dir_str[len(BUILD_DIR_PREFIX):].lstrip('/')
    # Find the first component (the mapping key)
    build_component_key = relative_build_path_str.split('/')[0]

    if build_component_key in PATH_MAPPINGS:
        source_relative_path_str = PATH_MAPPINGS[build_component_key]
        mapped_source_dir = source_root_path / source_relative_path_str
        # Assume build_file is relative to the directory listed in compile_commands
        # Construct absolute source file path
        absolute_source_file = mapped_source_dir / build_file

        logging.debug(f"Mapping found for key '{build_component_key}'.")
        logging.debug(f"  Build Dir: {build_dir_str}")
        logging.debug(f"  Mapped Source Dir: {mapped_source_dir}")
        logging.debug(f"  Checking for source file: {absolute_source_file}")

        # IMPORTANT: Check if the calculated source file actually exists
        if absolute_source_file.is_file():
            logging.debug(f"  Source file exists. Rewriting entry.")
            # Return the mapped source directory and the absolute path to the source file
            return str(mapped_source_dir), str(absolute_source_file)
        else:
            logging.warning(f"Mapped source file '{absolute_source_file}' not found for build file '{build_file}' in build dir '{build_dir_str}'. Keeping original entry.")
            return None, None
    else:
        logging.debug(f"No specific mapping found for component key '{build_component_key}' derived from '{build_dir_str}'. Keeping original entry.")
        return None, None


def main():
    parser = argparse.ArgumentParser(
        description="Rewrite compile_commands.json paths for out-of-tree builds using explicit mappings."
    )
    parser.add_argument(
        "input_file",
        type=Path,
        help="Path to the input compile_commands.json file.",
    )
    parser.add_argument(
        "-o",
        "--output_file",
        type=Path,
        help="Path to the output rewritten compile_commands.json file. "
             "If omitted, overwrites the input file.",
    )
    args = parser.parse_args()

    input_path = args.input_file.resolve()
    output_path = args.output_file.resolve() if args.output_file else input_path

    if not input_path.is_file():
        logging.error(f"Input file not found: {input_path}")
        sys.exit(1)

    logging.info(f"Reading compile commands from: {input_path}")
    try:
        with open(input_path, "r") as f:
            compile_db = json.load(f)
    except json.JSONDecodeError as e:
        logging.error(f"Failed to parse JSON from {input_path}: {e}")
        sys.exit(1)
    except OSError as e:
        logging.error(f"Failed to read {input_path}: {e}")
        sys.exit(1)


    rewritten_db = []
    modified_count = 0
    processed_count = 0
    for entry in compile_db:
        processed_count += 1
        build_dir = entry.get("directory")
        build_file = entry.get("file") # Often just filename.c
        arguments = entry.get("arguments")

        if not build_dir or not build_file or not arguments:
            logging.warning(f"Skipping entry {processed_count} with missing fields: {entry}")
            rewritten_db.append(entry)
            continue

        # Try to find mapping and verify source file existence
        mapped_source_dir, absolute_source_file = find_source_mapping(build_dir, build_file)

        if mapped_source_dir and absolute_source_file:
            # Create a new entry with modified paths but original arguments
            new_entry = {
                "directory": mapped_source_dir,
                "arguments": arguments,
                "file": absolute_source_file # Use absolute path here
            }
            rewritten_db.append(new_entry)
            logging.debug(f"Rewrote entry {processed_count} for {build_file}: build_dir '{build_dir}' -> source_dir '{mapped_source_dir}'")
            modified_count += 1
        else:
            # If no mapping applied or source file didn't exist, keep original
            rewritten_db.append(entry)
            logging.debug(f"Kept original entry {processed_count} for {build_file} in {build_dir}")


    logging.info(f"Processed {processed_count} entries, modified {modified_count}.")

    if modified_count > 0:
        logging.info(f"Writing rewritten compile commands to: {output_path} (Readable Format)")
        try:
            # Ensure the output directory exists
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "w") as f:
                # Use indent=2 for readable, formatted JSON output
                json.dump(rewritten_db, f, indent=2) # <--- USE INDENTATION
        except OSError as e:
            logging.error(f"Failed to write {output_path}: {e}")
            sys.exit(1)
    else:
        logging.info("No entries were modified, output file remains unchanged.")

    logging.info("Rewrite script finished.")

if __name__ == "__main__":
    main()
