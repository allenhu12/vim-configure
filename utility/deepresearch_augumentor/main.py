import os
import sys
from typing import Optional, Dict, List, Tuple

# Handle case when python-dotenv is not installed
try:
    from dotenv import load_dotenv
except ImportError:
    # Create a dummy load_dotenv function if the package is missing
    def load_dotenv():
        print("Warning: python-dotenv package not installed. Environment variables will not be loaded from .env file.")
        print("Install with: pip install python-dotenv")
        pass

# Predefined extraction modes with appropriate selectors
EXTRACTION_MODES = {
    "default": {
        "description": "Extract full page content"
    },
    "body-only": {
        "description": "Extract only the body content, removing navigation elements",
        "target_selector": "body",
        "remove_selector": "nav,header,footer,aside,script,style"
    },
    "article": {
        "description": "Focus on article content",
        "target_selector": "article,main,.article,.content,.post,#article,#content",
        "remove_selector": "nav,header,footer,aside,script,style,#comments,.comments,.related,.sidebar,.ad,.advertisement"
    },
    "main-content": {
        "description": "Target main content area",
        "target_selector": "main,.main,#main,.content,#content",
        "remove_selector": "nav,header,footer,aside,script,style,#comments,.comments,.related,.sidebar,.ad,.advertisement"
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
    python main.py input_file [options]

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
                              Default: default

    --output OUTPUT           Output file path to save the augmented report
                              If not specified, prints to stdout

    --timeout TIMEOUT         HTTP request timeout in seconds
                              Default: 15

    --usage                   Display this usage guide

EXAMPLES:
    # Basic usage with local extraction
    python main.py report.txt

    # Use Jina extractor with body-only mode to focus on main content
    python main.py report.txt --extractor jina --mode body-only

    # Save output to a file
    python main.py report.txt --extractor jina --mode article --output augmented_report.txt

    # Increase timeout for slow connections
    python main.py report.txt --extractor jina --timeout 30

DEBUGGING:
    For troubleshooting issues, use the debug_wrapper.py script instead of main.py:
    
    python debug_wrapper.py input_file [same options as main.py]
    
    The debug wrapper provides:
    - Detailed logging with timestamps
    - Tracking of API calls and responses
    - Time measurements for each operation
    - Storage of input, output, and intermediate results
    
    Debug artifacts are saved to debug/run_[extractor]_[timestamp]/ and include:
    - input.txt: Copy of the input report
    - output.txt: The generated augmented report
    - debug.log: Detailed logs including API calls and selectors used
    - timing.json: Performance metrics and timing information
    - stdout.txt, stderr.txt: Captured console output
    - error.txt: Detailed error information if something fails
    
    Example debugging command:
    python debug_wrapper.py report.txt --extractor jina --mode body-only

ENVIRONMENT VARIABLES:
    For the Jina and Firecrawl extractors, API keys are needed:

    JINA_API_KEY              API key for Jina AI Reader API
    FIRECRAWL_API_KEY         API key for Firecrawl API

    These can be set in the environment or in a .env file in the same directory.

NOTES:
    - The extraction modes feature only works with the Jina extractor
    - Use '--mode body-only' to target just the main content and ignore navigation elements
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
    request_timeout: int = 15
) -> str:
    """
    Augments a research report with content fetched from its reference links
    using a specified content extraction strategy.
    
    Args:
        report_text: The full text of the research report
        extractor_type: Identifier for the content extraction method
                      (e.g., "jina", "firecrawl", "local_bs4")
        extractor_config: Configuration dictionary for the chosen extractor.
                        Caller is responsible for populating this securely
                        with API keys if needed (e.g., from os.getenv()).
                        Example: {'api_key': os.getenv('JINA_API_KEY')}
        extraction_mode: Predefined mode for content extraction (default, body-only, article, main-content)
        request_timeout: Timeout in seconds for HTTP requests
    
    Returns:
        A string containing the original report followed by appended content
    """
    # Import utils here to allow --usage to work without dependencies
    from utils import parse_report, format_output
    
    # Load environment variables from .env file if present
    load_dotenv()
    
    # Initialize configuration if not provided
    if extractor_config is None:
        extractor_config = {}
    
    # Get API key based on extractor type if not in config
    if 'api_key' not in extractor_config:
        if extractor_type == "jina":
            extractor_config['api_key'] = os.environ.get("JINA_API_KEY")
        elif extractor_type == "firecrawl":
            extractor_config['api_key'] = os.environ.get("FIRECRAWL_API_KEY")
    
    # Apply extraction mode settings if applicable for the extractor type
    # (only Jina currently supports these options)
    if extractor_type == "jina" and extraction_mode in EXTRACTION_MODES:
        mode_config = EXTRACTION_MODES[extraction_mode]
        # Only override if not already specified in extractor_config
        if 'target_selector' in mode_config and 'target_selector' not in extractor_config:
            extractor_config['target_selector'] = mode_config['target_selector']
        if 'remove_selector' in mode_config and 'remove_selector' not in extractor_config:
            extractor_config['remove_selector'] = mode_config['remove_selector']
    
    # Get the appropriate extractor
    extractor = get_extractor(extractor_type)
    
    # Parse the report to get original content and URLs
    original_content, urls = parse_report(report_text)
    
    # Extract content for each URL
    url_contents = []
    for url in urls:
        extracted_text, error = extractor.extract_text(
            url=url,
            api_key=extractor_config.get('api_key'),
            timeout=request_timeout,
            target_selector=extractor_config.get('target_selector'),
            remove_selector=extractor_config.get('remove_selector')
        )
        url_contents.append((url, extracted_text, error))
    
    # Format the final output
    return format_output(original_content, url_contents)


def main():
    """CLI entry point."""
    import argparse
    
    # Check for usage flag first for more immediate help
    if "--usage" in sys.argv:
        print_usage()
        sys.exit(0)
    
    parser = argparse.ArgumentParser(description="Reference Augmentor - Enhance research reports with referenced content")
    
    parser.add_argument("input_file", help="Path to the input report file")
    parser.add_argument("--extractor", choices=["jina", "firecrawl", "local_bs4"], 
                        default="local_bs4", help="Content extraction method")
    parser.add_argument("--output", help="Output file path (default: print to stdout)")
    parser.add_argument("--timeout", type=int, default=15, help="HTTP request timeout in seconds")
    # Add extraction mode argument with choices from predefined modes
    parser.add_argument("--mode", choices=list(EXTRACTION_MODES.keys()), default="default",
                      help="Content extraction mode (Jina API only)")
    parser.add_argument("--usage", action="store_true", help="Display detailed usage guide")
    
    args = parser.parse_args()
    
    # Check for usage flag again (this time parsed by argparse)
    if args.usage:
        print_usage()
        return
    
    try:
        # Read input file
        with open(args.input_file, 'r', encoding='utf-8') as f:
            report_text = f.read()
        
        # Process the report
        augmented_report = augment_research_report(
            report_text=report_text,
            extractor_type=args.extractor,
            extraction_mode=args.mode,
            request_timeout=args.timeout
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