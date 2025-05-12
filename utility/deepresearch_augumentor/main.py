import os
from typing import Optional, Dict, List, Tuple
from dotenv import load_dotenv

from extractors import JinaAIExtractor, FirecrawlExtractor, BeautifulSoupExtractor
from utils import parse_report, format_output


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
        request_timeout: Timeout in seconds for HTTP requests
    
    Returns:
        A string containing the original report followed by appended content
    """
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
            timeout=request_timeout
        )
        url_contents.append((url, extracted_text, error))
    
    # Format the final output
    return format_output(original_content, url_contents)


def main():
    """CLI entry point."""
    import argparse
    import sys
    
    parser = argparse.ArgumentParser(description="Reference Augmentor - Enhance research reports with referenced content")
    
    parser.add_argument("input_file", help="Path to the input report file")
    parser.add_argument("--extractor", choices=["jina", "firecrawl", "local_bs4"], 
                        default="local_bs4", help="Content extraction method")
    parser.add_argument("--output", help="Output file path (default: print to stdout)")
    parser.add_argument("--timeout", type=int, default=15, help="HTTP request timeout in seconds")
    
    args = parser.parse_args()
    
    try:
        # Read input file
        with open(args.input_file, 'r', encoding='utf-8') as f:
            report_text = f.read()
        
        # Process the report
        augmented_report = augment_research_report(
            report_text=report_text,
            extractor_type=args.extractor,
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
    main() 