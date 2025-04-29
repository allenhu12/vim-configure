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
    "librsm-0.1": "rks_ap/libs/librsm/src", # Keep '/src' here as base for mtk/qca
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

# --- Vendor Disambiguation ---
# Map vendor defines found in compile arguments to subdirectory names
VENDOR_DEFINES_TO_SUBDIRS = {
    "-DLIBRSM_VENDOR_MTK": "mtk",
    "-DLIBRSM_VENDOR_QCA": "qca", # Assuming this define exists for QCA builds
    # Add more if needed
}
# ---------------------------

def find_source_mapping(build_dir_str: str, build_file: str, arguments: typing.List[str]) -> typing.Tuple[typing.Optional[str], typing.Optional[str]]:
    """
    Finds the corresponding source path based on PATH_MAPPINGS.
    Handles cases where the source file might be in a subdirectory of the mapped path,
    using compiler arguments to disambiguate if multiple matches are found.
    Returns (source_directory, absolute_source_file_path) or (None, None) if no mapping applies
    or the source file cannot be uniquely located.
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
        mapped_source_dir_base = source_root_path / source_relative_path_str
        build_file_path_obj = Path(build_file) # Treat build_file as potentially having dirs

        logging.debug(f"Mapping found for key '{build_component_key}'.")
        logging.debug(f"  Build Dir: {build_dir_str}")
        logging.debug(f"  Build File: {build_file}")
        logging.debug(f"  Mapped Source Base Dir: {mapped_source_dir_base}")

        # Attempt 1: Check if file exists directly at mapped_dir / build_file
        absolute_source_file_guess1 = mapped_source_dir_base / build_file_path_obj
        logging.debug(f"  Attempt 1: Checking direct path: {absolute_source_file_guess1}")
        if absolute_source_file_guess1.is_file():
            logging.debug(f"  Source file exists directly. Rewriting entry.")
            final_source_dir = str(absolute_source_file_guess1.parent)
            final_source_file = str(absolute_source_file_guess1)
            return final_source_dir, final_source_file

        # Attempt 2: If build_file is just a filename (no slashes), search recursively
        elif '/' not in build_file and '\\' not in build_file:
            logging.debug(f"  Direct path failed. Attempt 2: Recursively searching for '{build_file}' under {mapped_source_dir_base}")
            try:
                filename_only = build_file_path_obj.name
                found_files = list(mapped_source_dir_base.rglob(filename_only))
                exact_matches = [p for p in found_files if p.name == filename_only and p.is_file()] # Ensure it's a file

                if len(exact_matches) == 1:
                    found_file_path = exact_matches[0]
                    logging.debug(f"  Found unique match via rglob: {found_file_path}. Rewriting entry.")
                    final_source_dir = str(found_file_path.parent)
                    final_source_file = str(found_file_path)
                    return final_source_dir, final_source_file

                # --- MODIFICATION START: Handle Multiple Matches ---
                elif len(exact_matches) > 1:
                    logging.warning(f"  Found multiple instances of '{filename_only}' under '{mapped_source_dir_base}': {exact_matches}. Attempting disambiguation using compiler arguments.")
                    potential_subdir = None
                    for define, subdir in VENDOR_DEFINES_TO_SUBDIRS.items():
                        if define in arguments:
                            potential_subdir = subdir
                            logging.info(f"  Found vendor define '{define}', suggesting subdirectory '{subdir}'.")
                            break # Found a potential vendor

                    if potential_subdir:
                        # Filter the matches based on the detected subdirectory
                        filtered_matches = [
                            p for p in exact_matches
                            if f"{os.sep}{potential_subdir}{os.sep}" in str(p) or p.parts[-2] == potential_subdir
                        ]

                        if len(filtered_matches) == 1:
                            found_file_path = filtered_matches[0]
                            logging.info(f"  Successfully disambiguated using vendor define. Using: {found_file_path}. Rewriting entry.")
                            final_source_dir = str(found_file_path.parent)
                            final_source_file = str(found_file_path)
                            return final_source_dir, final_source_file
                        elif len(filtered_matches) > 1:
                             logging.error(f"  Disambiguation failed: Found multiple matches even after filtering for subdir '{potential_subdir}': {filtered_matches}. Keeping original entry.")
                             return None, None
                        else:
                             logging.warning(f"  Disambiguation failed: Found vendor define '{define}' but no matching path in {exact_matches} contained subdir '{potential_subdir}'. Keeping original entry.")
                             return None, None
                    else:
                        logging.warning(f"  Disambiguation failed: No known vendor define found in arguments. Cannot uniquely determine path. Keeping original entry.")
                        return None, None
                # --- MODIFICATION END ---
                else: # len(exact_matches) == 0
                    logging.warning(f"  Could not find '{filename_only}' recursively under '{mapped_source_dir_base}'. Keeping original entry.")
                    return None, None
            except Exception as e:
                logging.error(f"  Error during recursive search for '{build_file}': {e}")
                return None, None
        else:
             # If build_file contained slashes but didn't exist directly
            logging.warning(f"  Mapped source file '{absolute_source_file_guess1}' (derived from path in 'file' field) not found. Keeping original entry.")
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
        arguments = entry.get("arguments") # Get arguments

        if not build_dir or not build_file or not arguments:
            logging.warning(f"Skipping entry {processed_count} with missing fields: {entry}")
            rewritten_db.append(entry)
            continue

        # --- Pass arguments to the mapping function ---
        mapped_source_dir, absolute_source_file = find_source_mapping(build_dir, build_file, arguments)

        if mapped_source_dir and absolute_source_file:
            # Create a new entry with modified paths but original arguments
            new_entry = {
                "directory": mapped_source_dir,
                "arguments": arguments,
                "file": absolute_source_file # Use absolute path here
            }
            # --- Optional: Clean up arguments list ---
            # Remove build-path-specific flags like -fmacro-prefix-map if desired
            # Example (add more sophisticated logic if needed):
            # clean_arguments = [arg for arg in arguments if not arg.startswith("-fmacro-prefix-map=")]
            # new_entry["arguments"] = clean_arguments
            # -----------------------------------------
            rewritten_db.append(new_entry)
            # Use INFO level for successful rewrites for better visibility
            logging.info(f"Rewrote entry {processed_count} for {Path(absolute_source_file).name}: build_dir '{build_dir}' -> source_dir '{mapped_source_dir}'")
            modified_count += 1
        else:
            # If no mapping applied or source file didn't exist/was ambiguous, keep original
            rewritten_db.append(entry)
            logging.debug(f"Kept original entry {processed_count} for {build_file} in {build_dir}")


    logging.info(f"Processed {processed_count} entries, modified {modified_count}.")

    # Only write if changes were made or if output is different from input
    # (Avoids rewriting identical file)
    if modified_count > 0 or output_path != input_path:
        logging.info(f"Writing {modified_count} modified entries to: {output_path} (Readable Format)")
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
        logging.info("No entries needed modification, output file identical to input.")

    logging.info("Rewrite script finished.")

if __name__ == "__main__":
    main()
