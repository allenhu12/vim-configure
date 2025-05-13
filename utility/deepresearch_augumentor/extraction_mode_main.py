#!/usr/bin/env python3
"""
Content Extraction Mode Demonstration Script

This script demonstrates the various content extraction modes available with the
Jina AI extractor. It allows you to analyze a single URL with different extraction
modes to compare the results.
"""

import os
import sys
import argparse
import time
from typing import Optional, Dict, List, Tuple

# Import needed modules
from config_manager import ConfigManager
from extractors import JinaAIExtractor
from main import EXTRACTION_MODES

def extract_with_mode(url: str, mode: str, api_key: str, timeout: int = 15, verbose: bool = True) -> Tuple[Optional[str], Optional[str]]:
    """
    Extract content from a URL using a specific extraction mode.
    
    Args:
        url: The URL to extract content from
        mode: Extraction mode to use (from EXTRACTION_MODES)
        api_key: Jina API key
        timeout: Request timeout in seconds
        verbose: Whether to display detailed information
        
    Returns:
        Tuple of (extracted_content, error_message)
    """
    if verbose:
        print(f"Extracting content from {url} using mode: {mode}")
        if mode in EXTRACTION_MODES:
            print(f"Mode description: {EXTRACTION_MODES[mode]['description']}")
            print("Mode settings:")
            for key, value in EXTRACTION_MODES[mode].items():
                if key != 'description':
                    print(f"  - {key}: {value}")
        print("Sending request...")
    
    start_time = time.time()
    
    # Create extractor and config
    extractor = JinaAIExtractor()
    extractor_config = {'api_key': api_key}
    
    # Apply mode settings if available
    if mode in EXTRACTION_MODES:
        mode_config = EXTRACTION_MODES[mode]
        # Only override if not already specified in extractor_config
        if 'target_selector' in mode_config:
            extractor_config['target_selector'] = mode_config['target_selector']
        if 'remove_selector' in mode_config:
            extractor_config['remove_selector'] = mode_config['remove_selector']
        if 'links_handling' in mode_config:
            extractor_config['links_handling'] = mode_config['links_handling']
        if 'links_summary' in mode_config:
            extractor_config['links_summary'] = mode_config['links_summary']
    
    # Add timeout and debugging
    extractor_config['timeout'] = timeout
    extractor_config['debug'] = verbose
    
    # Extract content
    content, error = extractor.extract_text(url=url, **extractor_config)
    
    elapsed = time.time() - start_time
    
    if verbose:
        if content:
            content_length = len(content)
            print(f"Success: Got {content_length} characters in {elapsed:.2f}s")
        else:
            print(f"Error: {error} ({elapsed:.2f}s)")
    
    return content, error

def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(description="Content Extraction Mode Demonstration")
    
    # Create argument groups to handle the command properly
    url_group = parser.add_argument_group('URL Extraction')
    url_group.add_argument("url", nargs='?', help="URL to extract content from")
    url_group.add_argument("--mode", choices=list(EXTRACTION_MODES.keys()), default="default",
                       help="Content extraction mode")
    url_group.add_argument("--output", help="Output file path (default: print to stdout)")
    url_group.add_argument("--timeout", type=int, default=15, help="HTTP request timeout in seconds")
    url_group.add_argument("--quiet", action="store_true", help="Suppress detailed output")
    
    info_group = parser.add_argument_group('Information')
    info_group.add_argument("--list-modes", action="store_true", help="List available extraction modes")
    
    args = parser.parse_args()
    
    # Handle mode listing (doesn't require a URL)
    if args.list_modes:
        print("Available extraction modes:")
        for mode_name, mode_info in EXTRACTION_MODES.items():
            print(f"  {mode_name}: {mode_info['description']}")
            # Print additional settings for each mode
            for key, value in mode_info.items():
                if key != 'description':
                    print(f"    - {key}: {value}")
            print()
        return 0
    
    # If not listing modes, URL is required
    if not args.url:
        parser.error("URL is required unless using --list-modes")
        return 1
    
    # Get API key
    config = ConfigManager()
    api_key = config.get_api_key("JINA_API_KEY")
    
    if not api_key:
        print("Jina API key not found in configuration.")
        print("Please set it using: python main.py --set-jina-key YOUR_API_KEY")
        return 1
    
    try:
        # Extract content using the specified mode
        content, error = extract_with_mode(
            url=args.url,
            mode=args.mode, 
            api_key=api_key,
            timeout=args.timeout,
            verbose=not args.quiet
        )
        
        if error:
            print(f"Error extracting content: {error}", file=sys.stderr)
            return 1
        
        # Output the result
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Extracted content written to {args.output}")
        else:
            print("\n" + "="*50 + "\n")
            print("EXTRACTED CONTENT:")
            print("="*50 + "\n")
            print(content)
        
        return 0
    
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main()) 