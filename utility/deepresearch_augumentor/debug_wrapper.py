#!/usr/bin/env python3
"""
Debug Wrapper for Reference Augmentor

This script adds debugging capabilities to help troubleshoot issues with
the Reference Augmentor. It captures detailed information about the extraction
process, saves artifacts for inspection, and provides verbose logging.

Usage:
    python debug_wrapper.py input_file [--extractor jina|firecrawl|local_bs4] [--mode default|body-only|article|main-content] [--output output_file] [--timeout seconds]
"""

import os
import sys
import json
import time
import logging
import traceback
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('debug_wrapper')

# Import the main module
from main import augment_research_report, EXTRACTION_MODES


def create_debug_dir(extractor_type):
    """Create a debug directory for this run."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Use a consistent location for debug files
    if os.name == 'nt':  # Windows
        base_dir = os.path.join(os.environ['APPDATA'], "ReferenceAugmentor")
    else:  # macOS/Linux
        base_dir = os.path.join(str(Path.home()), ".referenceaugmentor")
        
    debug_dir = os.path.join(base_dir, f"debug/run_{extractor_type}_{timestamp}")
    
    if not os.path.exists(debug_dir):
        os.makedirs(debug_dir)
        
    return debug_dir


def run_with_debug(input_file, extractor_type, output_file=None, timeout=15, extraction_mode="default", extractor_config=None):
    """Run the augmentation with debugging enabled."""
    # Create debug directory
    debug_dir = create_debug_dir(extractor_type)
    logger.info(f"Debug artifacts will be saved to {debug_dir}")
    
    # Read input file
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            report_text = f.read()
        
        # Save a copy of the input
        with open(os.path.join(debug_dir, "input.txt"), 'w', encoding='utf-8') as f:
            f.write(report_text)
            
        logger.info(f"Input file read: {len(report_text)} characters")
    except Exception as e:
        logger.error(f"Failed to read input file: {str(e)}")
        with open(os.path.join(debug_dir, "error.txt"), 'w', encoding='utf-8') as f:
            f.write(f"Error reading input file: {str(e)}\n\n")
            f.write(traceback.format_exc())
        sys.exit(1)
    
    # Set up environment variables for debugging
    old_log_level = logging.getLogger('reference_augmentor').level
    logging.getLogger('reference_augmentor').setLevel(logging.DEBUG)
    
    # Create log file handler
    log_file = os.path.join(debug_dir, "debug.log")
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
    logging.getLogger().addHandler(file_handler)
    
    logger.info(f"Logging debug information to {log_file}")
    
    # Log extractor configuration details
    if extractor_config:
        # Log API key presence (not the actual key)
        if 'api_key' in extractor_config:
            logger.info(f"API key provided for {extractor_type}")
        # Log other configuration parameters
        for key, value in extractor_config.items():
            if key != 'api_key':
                logger.info(f"Configuration: {key} = {value}")
    
    # Capture stdout and stderr
    stdout_file = os.path.join(debug_dir, "stdout.txt")
    stderr_file = os.path.join(debug_dir, "stderr.txt")
    
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    
    with open(stdout_file, 'w') as stdout_writer, open(stderr_file, 'w') as stderr_writer:
        sys.stdout = stdout_writer
        sys.stderr = stderr_writer
        
        # Track timing
        start_time = time.time()
        logger.info(f"Starting augmentation with {extractor_type} extractor using mode {extraction_mode}")
        
        try:
            # Monkey patch the extractors to capture API responses
            if extractor_type in ["jina", "firecrawl"]:
                # Import the extractor
                if extractor_type == "jina":
                    from extractors.jina_extractor import JinaAIExtractor
                    extractor_class = JinaAIExtractor
                else:
                    from extractors.firecrawl_extractor import FirecrawlExtractor
                    extractor_class = FirecrawlExtractor
                
                # Save the original method
                original_extract_text = extractor_class.extract_text
                
                # Create a wrapper that logs the response
                def extract_text_with_logging(self, url, api_key=None, **kwargs):
                    logger.info(f"Calling {extractor_type} API for URL: {url}")
                    if kwargs.get('target_selector'):
                        logger.info(f"Using target_selector: {kwargs.get('target_selector')}")
                    if kwargs.get('remove_selector'):
                        logger.info(f"Using remove_selector: {kwargs.get('remove_selector')}")
                    
                    start = time.time()
                    
                    try:
                        result, error = original_extract_text(self, url, api_key, **kwargs)
                        duration = time.time() - start
                        
                        # Log the result
                        if error:
                            logger.warning(f"API error for {url}: {error} (took {duration:.2f}s)")
                        else:
                            content_length = len(result) if result else 0
                            logger.info(f"API success for {url}: {content_length} characters (took {duration:.2f}s)")
                        
                        return result, error
                    
                    except Exception as e:
                        duration = time.time() - start
                        logger.error(f"Exception calling API for {url}: {str(e)} (took {duration:.2f}s)")
                        raise
                
                # Replace the method
                extractor_class.extract_text = extract_text_with_logging
            
            # Run the report augmentation
            result = augment_research_report(
                report_text=report_text,
                extractor_type=extractor_type,
                extractor_config=extractor_config,
                extraction_mode=extraction_mode,
                request_timeout=timeout,
                verbose=True  # Always verbose in debug mode
            )
            
            # Save the result
            with open(os.path.join(debug_dir, "output.txt"), 'w', encoding='utf-8') as f:
                f.write(result)
                
            # Save timing information
            end_time = time.time()
            timing_info = {
                "start_time": datetime.fromtimestamp(start_time).isoformat(),
                "end_time": datetime.fromtimestamp(end_time).isoformat(),
                "total_seconds": end_time - start_time,
                "input_size": len(report_text),
                "output_size": len(result)
            }
            with open(os.path.join(debug_dir, "timing.json"), 'w', encoding='utf-8') as f:
                json.dump(timing_info, f, indent=2)
                
            logger.info(f"Processing completed in {end_time - start_time:.2f} seconds")
            
            # If output file specified, write the result there
            if output_file:
                with open(output_file, 'w', encoding='utf-8') as f:
                    f.write(result)
                logger.info(f"Output written to {output_file}")
                
            logger.info(f"Debug artifacts saved to {debug_dir}")
            
            # Restore the original method if we modified it
            if extractor_type in ["jina", "firecrawl"]:
                if extractor_type == "jina":
                    JinaAIExtractor.extract_text = original_extract_text
                else:
                    FirecrawlExtractor.extract_text = original_extract_text
                
        except Exception as e:
            logger.error(f"Error during processing: {str(e)}")
            with open(os.path.join(debug_dir, "error.txt"), 'w', encoding='utf-8') as f:
                f.write(f"Error: {str(e)}\n\n")
                f.write(traceback.format_exc())
                
            # Restore the original method if we modified it
            if extractor_type in ["jina", "firecrawl"]:
                if extractor_type == "jina":
                    JinaAIExtractor.extract_text = original_extract_text
                else:
                    FirecrawlExtractor.extract_text = original_extract_text
                
            # Print to real stderr
            print(f"Error: {str(e)}", file=old_stderr)
            print(f"See {os.path.join(debug_dir, 'error.txt')} for details", file=old_stderr)
            
        finally:
            # Restore stdout, stderr and logging
            sys.stdout = old_stdout
            sys.stderr = old_stderr
            logging.getLogger('reference_augmentor').setLevel(old_log_level)
            logging.getLogger().removeHandler(file_handler)
            
    return result, debug_dir


def main():
    """CLI entry point for standalone debug usage."""
    import argparse
    from config_manager import ConfigManager
    
    parser = argparse.ArgumentParser(description="Debug Wrapper for Reference Augmentor")
    
    parser.add_argument("input_file", help="Path to the input report file")
    parser.add_argument("--extractor", choices=["jina", "firecrawl", "local_bs4"], 
                        default="local_bs4", help="Content extraction method")
    parser.add_argument("--output", help="Output file path (default: print to stdout)")
    parser.add_argument("--timeout", type=int, default=15, help="HTTP request timeout in seconds")
    # Add extraction mode argument with choices from predefined modes
    parser.add_argument("--mode", choices=list(EXTRACTION_MODES.keys()), default="default",
                      help="Content extraction mode (Jina API only)")
    
    args = parser.parse_args()
    
    try:
        # Initialize config manager to get API keys
        config = ConfigManager()
        extractor_config = {}
        
        if args.extractor == "jina":
            api_key = config.get_api_key("JINA_API_KEY")
            if not api_key:
                print("Jina API key not found in configuration.")
                print("Please set it using: python main.py --set-jina-key YOUR_API_KEY")
                return
            extractor_config['api_key'] = api_key
        elif args.extractor == "firecrawl":
            api_key = config.get_api_key("FIRECRAWL_API_KEY")
            if not api_key:
                print("Firecrawl API key not found in configuration.")
                print("Please set it using: python main.py --set-firecrawl-key YOUR_API_KEY")
                return
            extractor_config['api_key'] = api_key
            
        result, debug_dir = run_with_debug(
            args.input_file,
            args.extractor,
            args.output,
            args.timeout,
            args.mode,
            extractor_config
        )
        
        if not args.output:
            print(result)
            
        print(f"\nDebug artifacts saved to {debug_dir}")
        
    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}")
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
