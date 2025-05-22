import os
import sys
import time
from typing import Optional, Dict, List, Tuple

# Try to import tqdm, create a simple fallback if not available
try:
    from tqdm import tqdm
except ImportError:
    # Create a simple fallback version of tqdm
    def tqdm(iterable, **kwargs):
        disable = kwargs.get('disable', False)
        desc = kwargs.get('desc', '')
        if not disable and desc:
            print(f"{desc}...")
        return iterable

# Handle case when python-dotenv is not installed
try:
    from dotenv import load_dotenv
except ImportError:
    # Create a dummy load_dotenv function if the package is missing
    def load_dotenv():
        print("Warning: python-dotenv package not installed. Environment variables will not be loaded from .env file.")
        print("Install with: pip install python-dotenv")
        pass

# Import ConfigManager for API key handling
from config_manager import ConfigManager

# Predefined extraction modes with appropriate selectors
EXTRACTION_MODES = {
    "default": {
        "description": "Extract full page content"
    },
    "body-only": {
        "description": "Extract only the body content, removing navigation elements",
        "target_selector": "body",
        "remove_selector": "nav,header,footer,aside,script,style",
        "links_handling": "default"
    },
    "article": {
        "description": "Focus on article content",
        "target_selector": "article,main,.article,.content,.post,#article,#content",
        "remove_selector": "nav,header,footer,aside,script,style,#comments,.comments,.related,.sidebar,.ad,.advertisement",
        "links_handling": "default"
    },
    "main-content": {
        "description": "Target main content area",
        "target_selector": "main,.main,#main,.content,#content",
        "remove_selector": "nav,header,footer,aside,script,style,#comments,.comments,.related,.sidebar,.ad,.advertisement",
        "links_handling": "default"
    },
    "clean-text": {
        "description": "Focus on content with minimal links",
        "target_selector": "body",
        "remove_selector": "nav,header,footer,aside,script,style,#comments,.comments,.related,.sidebar,.ad,.advertisement",
        "links_handling": "discarded",
        "links_summary": False
    },
    "referenced-links": {
        "description": "Clean content with numbered link references",
        "target_selector": "article,main,.article,.content,.post,#article,#content",
        "remove_selector": "nav,header,footer,aside,script,style,#comments,.comments,.related,.sidebar,.ad,.advertisement",
        "links_handling": "referenced",
        "links_summary": True
    },
    "clean-body": {
        "description": "Body content only with no links (combines clean-text and body-only)",
        "target_selector": "body",
        "remove_selector": "nav,header,footer,aside,script,style",
        "links_handling": "discarded",
        "links_summary": False
    },
    "clean-article": {
        "description": "Article content only with no links (combines clean-text and article)",
        "target_selector": "article,main,.article,.content,.post,#article,#content",
        "remove_selector": "nav,header,footer,aside,script,style,#comments,.comments,.related,.sidebar,.ad,.advertisement",
        "links_handling": "discarded",
        "links_summary": False
    }
}

def print_usage():
    """Print detailed usage information about the script."""
    usage_text = """
REFERENCE AUGMENTOR - USAGE GUIDE
=================================

The Reference Augmentor enhances research reports by automatically fetching 
content from URLs listed in their reference section.

BASIC USAGE:
    For development/testing (using python directly):
        python main.py input_file [options]
    
    For packaged executable (e.g., on macOS/Linux):
        ./ReferenceAugmentor input_file [options]
    (On Windows, use ReferenceAugmentor.exe)

ARGUMENTS:
    input_file                Path to the report file with references to process

OPTIONS:
    --extractor EXTRACTOR     Specify the content extraction method to use
                              Choices: jina, firecrawl, local_bs4
                              Default: local_bs4

    --mode MODE               Content extraction mode (works with Jina API only)
                              Choices:
                                • default: Extract full page content
                                • body-only: Extract only the body content, removing navigation elements
                                • article: Focus on article content (articles, main content areas)
                                • main-content: Target primary content areas
                                • clean-text: Focus on content with minimal links
                                • referenced-links: Clean content with numbered link references
                                • clean-body: Body content only with no links (combines clean-text and body-only)
                                • clean-article: Article content only with no links (combines clean-text and article)
                              Default: default

    --output OUTPUT           Output file path to save the augmented report
                              If not specified, prints to stdout

    --timeout TIMEOUT         HTTP request timeout in seconds
                              Default: 15

    --usage                   Display this usage guide
    
    --quiet                   Suppress progress information (show only errors)

API KEY MANAGEMENT:
    API keys are required for Jina and Firecrawl extractors.
    Manage them with the packaged executable (./ReferenceAugmentor or ReferenceAugmentor.exe):

    ./ReferenceAugmentor --set-jina-key YOUR_JINA_API_KEY
    ./ReferenceAugmentor --set-firecrawl-key YOUR_FIRECRAWL_API_KEY
    ./ReferenceAugmentor --show-keys
    ./ReferenceAugmentor --clear-keys

    (Or use `python main.py --set-jina-key ...` during development)

    API keys are stored in a configuration file:
    - Windows: %APPDATA%\\ReferenceAugmentor\\config.json
    - macOS/Linux: ~/.referenceaugmentor/config.json

EXAMPLES:
    Using Python directly:
        # Basic usage with local extraction
        python main.py report.txt

        # Use Jina extractor with body-only mode to focus on main content
        python main.py report.txt --extractor jina --mode body-only

        # Save output to a file
        python main.py report.txt --extractor jina --mode article --output augmented_report.txt

        # Increase timeout for slow connections
        python main.py report.txt --extractor jina --timeout 30

    Using the packaged executable (macOS/Linux):
        # Basic usage with local extraction
        ./ReferenceAugmentor report.txt

        # Use Jina extractor with body-only mode
        ./ReferenceAugmentor report.txt --extractor jina --mode body-only

        # Save output to a file
        ./ReferenceAugmentor report.txt --extractor jina --mode article --output augmented_report.txt

DEBUGGING:
    For troubleshooting issues, use the --debug flag with the main script or executable:
    
    python main.py report.txt --extractor jina --mode body-only --debug
    ./ReferenceAugmentor report.txt --extractor jina --mode body-only --debug
    
    This provides detailed logging, API call tracking, and stores debug artifacts in:
    - Windows: %APPDATA%\\ReferenceAugmentor\\debug\\run_[extractor]_[timestamp]\
    - macOS/Linux: ~/.referenceaugmentor/debug/run_[extractor]_[timestamp]/

NOTES:
    - The extraction modes feature only works with the Jina extractor
    - Use '--mode body-only' to target just the main content and ignore navigation elements
    - Use '--mode clean-text' to get content with minimal links (links are converted to plain text)
    - Use '--mode referenced-links' for clean content with numbered link references at the end
    - Use '--mode clean-body' for a combination of body-only focus and removing all links
    - Use '--mode clean-article' for a combination of article focus and removing all links
    - Report format should have a clear separation between the main content and references
    """
    print(usage_text)


def get_extractor(extractor_type: str):
    """
    Factory function to get the appropriate content extractor.
    
    Args:
        extractor_type: Type of extractor to use (e.g., "jina", "firecrawl", "local_bs4")
    
    Returns:
        ContentExtractorInterface instance
    
    Raises:
        ValueError: If extractor_type is not recognized
    """
    # Import extractors here to allow --usage to work without dependencies
    from extractors import JinaAIExtractor, FirecrawlExtractor, BeautifulSoupExtractor
    
    extractors = {
        "jina": JinaAIExtractor(),
        "firecrawl": FirecrawlExtractor(),
        "local_bs4": BeautifulSoupExtractor()
    }
    
    if extractor_type not in extractors:
        raise ValueError(f"Unsupported extractor type: {extractor_type}. " 
                         f"Supported types are: {', '.join(extractors.keys())}")
    
    return extractors[extractor_type]


def augment_research_report(
    report_text: str,
    extractor_type: str = "local_bs4",
    extractor_config: Optional[Dict] = None,
    extraction_mode: str = "default",
    request_timeout: int = 15,
    verbose: bool = True
) -> str:
    """
    Augments a research report with content fetched from its reference links
    using a specified content extraction strategy.
    
    Args:
        report_text: The full text of the research report
        extractor_type: Identifier for the content extraction method
                      (e.g., "jina", "firecrawl", "local_bs4")
        extractor_config: Configuration dictionary for the chosen extractor.
                        Should contain 'api_key' if using jina or firecrawl.
        extraction_mode: Predefined mode for content extraction (default, body-only, article, main-content)
        request_timeout: Timeout in seconds for HTTP requests
        verbose: Whether to show detailed progress information
    
    Returns:
        A string containing the original report followed by appended content
    """
    # Import utils here to allow --usage to work without dependencies
    from utils import parse_report, format_output
    
    # Initialize configuration if not provided
    if extractor_config is None:
        extractor_config = {}
    
    # Apply extraction mode settings if applicable for the extractor type
    # (only Jina currently supports these options)
    if extractor_type == "jina" and extraction_mode in EXTRACTION_MODES:
        mode_config = EXTRACTION_MODES[extraction_mode]
        # Only override if not already specified in extractor_config
        if 'target_selector' in mode_config and 'target_selector' not in extractor_config:
            extractor_config['target_selector'] = mode_config['target_selector']
        if 'remove_selector' in mode_config and 'remove_selector' not in extractor_config:
            extractor_config['remove_selector'] = mode_config['remove_selector']
        if 'links_handling' in mode_config and 'links_handling' not in extractor_config:
            extractor_config['links_handling'] = mode_config['links_handling']
        if 'links_summary' in mode_config and 'links_summary' not in extractor_config:
            extractor_config['links_summary'] = mode_config['links_summary']
    
    # Get the appropriate extractor
    extractor = get_extractor(extractor_type)
    
    # Parse the report to get original content and URLs
    original_content, urls = parse_report(report_text)
    
    if verbose:
        print(f"Found {len(urls)} URLs to process")
        if len(urls) > 5:
            print("This might take some time. Processing in progress...")
    
    # Extract content for each URL
    url_contents = []
    total_urls = len(urls)
    failed_urls = 0
    skipped_urls = 0
    max_retries = 2
    
    for i, url in enumerate(tqdm(urls, desc="Extracting content", unit="URL", disable=not verbose)):
        try:
            if verbose:
                print(f"\nURL {i+1}/{total_urls}: {url}")
                process_start = time.time()
            
            retry_count = 0
            while retry_count <= max_retries:
                # If this is a retry, let the user know
                if retry_count > 0 and verbose:
                    print(f"  Retry {retry_count}/{max_retries}...")
                
                try:
                    # Start a timer for this extraction
                    start_time = time.time()
                    
                    # Try to extract content with timeout
                    extracted_text, error = extractor.extract_text(
                        url=url,
                        api_key=extractor_config.get('api_key'),
                        timeout=request_timeout,
                        target_selector=extractor_config.get('target_selector'),
                        remove_selector=extractor_config.get('remove_selector'),
                        links_handling=extractor_config.get('links_handling'),
                        links_summary=extractor_config.get('links_summary')
                    )
                    
                    # Calculate how long the extraction took
                    elapsed = time.time() - start_time
                    
                    # If successful, break the retry loop
                    if extracted_text is not None:
                        if verbose:
                            content_length = len(extracted_text)
                            print(f"  ✓ Success: Got {content_length} characters in {elapsed:.2f}s")
                        break
                    
                    # If there was an error but not a timeout, maybe retry
                    if verbose:
                        print(f"  ✗ Error: {error} ({elapsed:.2f}s)")
                    
                    if "timeout" in str(error).lower() or elapsed >= request_timeout * 0.9:
                        # If we've timed out, we might want to try one more time
                        if verbose and retry_count < max_retries:
                            print(f"  Request timed out, will retry...")
                    else:
                        # For other errors, don't retry
                        break
                    
                except Exception as e:
                    # Catch any unexpected exceptions
                    error = str(e)
                    if verbose:
                        print(f"  ✗ Exception: {error}")
                
                retry_count += 1
            
            # Add the result to our list (could be None if all retries failed)
            url_contents.append((url, extracted_text, error))
            
            # Count failures for reporting
            if extracted_text is None:
                failed_urls += 1
            
            if verbose and extracted_text is None:
                print(f"  ✗ Failed to extract content after {retry_count} attempts")
            
            # Show overall progress
            if verbose:
                process_time = time.time() - process_start
                print(f"  Completed in {process_time:.2f}s")
                
                # Provide progress summary
                successful = i + 1 - failed_urls - skipped_urls
                print(f"  Progress: {i+1}/{total_urls} URLs processed ({successful} successful, {failed_urls} failed, {skipped_urls} skipped)")
        
        except KeyboardInterrupt:
            # Allow the user to skip a URL if it's taking too long
            if verbose:
                print("\nSkipping this URL due to user interruption...")
            skipped_urls += 1
            url_contents.append((url, None, "Skipped by user"))
    
    # Show final statistics if verbose
    if verbose:
        successful = total_urls - failed_urls - skipped_urls
        print(f"\nExtraction complete: {total_urls} URLs processed")
        print(f"  {successful} successful, {failed_urls} failed, {skipped_urls} skipped")
    
    # Format the final output
    return format_output(original_content, url_contents)


def main():
    """CLI entry point."""
    import argparse
    import traceback
    
    # Check for usage flag first for more immediate help
    if "--usage" in sys.argv:
        print_usage()
        sys.exit(0)
    
    parser = argparse.ArgumentParser(description="Reference Augmentor - Enhance research reports with referenced content")
    
    # Standard arguments
    parser.add_argument("input_file", nargs="?", help="Path to the input report file")
    parser.add_argument("--extractor", choices=["jina", "firecrawl", "local_bs4"], 
                        default="local_bs4", help="Content extraction method")
    parser.add_argument("--output", help="Output file path (default: print to stdout)")
    parser.add_argument("--timeout", type=int, default=15, help="HTTP request timeout in seconds")
    # Add extraction mode argument with choices from predefined modes
    parser.add_argument("--mode", choices=list(EXTRACTION_MODES.keys()), default="default",
                      help="Content extraction mode (Jina API only)")
    parser.add_argument("--usage", action="store_true", help="Display detailed usage guide")
    
    # API key management arguments
    key_group = parser.add_argument_group('API Key Management')
    key_group.add_argument("--set-jina-key", metavar="KEY", help="Set Jina API key")
    key_group.add_argument("--set-firecrawl-key", metavar="KEY", help="Set Firecrawl API key")
    key_group.add_argument("--clear-keys", action="store_true", help="Clear all stored API keys")
    key_group.add_argument("--show-keys", action="store_true", help="Show currently stored API keys (masked)")
    
    # Debug mode flag
    parser.add_argument("--debug", action="store_true", help="Run in debug mode with detailed logging and artifacts")
    
    # Progress display options
    parser.add_argument("--quiet", action="store_true", help="Suppress progress information (show only errors)")
    
    args = parser.parse_args()
    
    # Initialize config manager
    config = ConfigManager()
    
    # Handle API key management commands
    if args.set_jina_key:
        config.set_api_key("JINA_API_KEY", args.set_jina_key)
        print("Jina API key has been set successfully.")
        return
        
    if args.set_firecrawl_key:
        config.set_api_key("FIRECRAWL_API_KEY", args.set_firecrawl_key)
        print("Firecrawl API key has been set successfully.")
        return
        
    if args.clear_keys:
        config.clear_api_key("JINA_API_KEY")
        config.clear_api_key("FIRECRAWL_API_KEY")
        print("All API keys have been cleared.")
        return
        
    if args.show_keys:
        jina_key = config.get_api_key("JINA_API_KEY")
        firecrawl_key = config.get_api_key("FIRECRAWL_API_KEY")
        
        print("Currently stored API keys:")
        if jina_key:
            masked_key = jina_key[:4] + "*" * (len(jina_key) - 8) + jina_key[-4:] if len(jina_key) > 8 else "*" * len(jina_key)
            print(f"JINA_API_KEY: {masked_key}")
        else:
            print("JINA_API_KEY: Not set")
            
        if firecrawl_key:
            masked_key = firecrawl_key[:4] + "*" * (len(firecrawl_key) - 8) + firecrawl_key[-4:] if len(firecrawl_key) > 8 else "*" * len(firecrawl_key)
            print(f"FIRECRAWL_API_KEY: {masked_key}")
        else:
            print("FIRECRAWL_API_KEY: Not set")
        return
    
    # Check for usage flag
    if args.usage:
        print_usage()
        return
    
    # Ensure input file is provided for normal operation
    if not args.input_file:
        parser.error("Input file is required unless using API key management commands")
    
    try:
        # Read input file
        with open(args.input_file, 'r', encoding='utf-8') as f:
            report_text = f.read()
        
        # Create extractor config with API keys
        extractor_config = {}
        if args.extractor == "jina":
            api_key = config.get_api_key("JINA_API_KEY")
            if not api_key:
                print("Jina API key not found in configuration.")
                print("Please set it using: --set-jina-key YOUR_API_KEY")
                return
            extractor_config['api_key'] = api_key
        elif args.extractor == "firecrawl":
            api_key = config.get_api_key("FIRECRAWL_API_KEY")
            if not api_key:
                print("Firecrawl API key not found in configuration.")
                print("Please set it using: --set-firecrawl-key YOUR_API_KEY")
                return
            extractor_config['api_key'] = api_key
        
        # Handle debug mode
        if args.debug:
            from debug_wrapper import run_with_debug
            try:
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
                print(f"Error in debug mode: {str(e)}", file=sys.stderr)
                traceback.print_exc()
                sys.exit(1)
            return
        
        # Process the report (normal mode)
        augmented_report = augment_research_report(
            report_text=report_text,
            extractor_type=args.extractor,
            extractor_config=extractor_config,
            extraction_mode=args.mode,
            request_timeout=args.timeout,
            verbose=not args.quiet
        )
        
        # Output the result
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(augmented_report)
            print(f"Augmented report written to {args.output}")
        else:
            print(augmented_report)
            
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    # Check for usage flag without requiring argparse
    if "--usage" in sys.argv:
        print_usage()
    else:
        main() 