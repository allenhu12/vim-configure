import re
from typing import Tuple, List, Optional
import os
from datetime import datetime
from dotenv import load_dotenv


def load_api_keys():
    """
    Load API keys from .env file or environment variables.
    """
    # Try to load from .env file if present
    load_dotenv()


def parse_report(report_text: str) -> Tuple[str, List[str]]:
    """
    Parse a research report to extract original content and reference URLs.
    
    Args:
        report_text: The text of the research report
    
    Returns:
        Tuple of (original_content, list_of_urls)
    """
    # This is a simplified implementation. In a real application,
    # you might want to use more sophisticated methods to identify 
    # the reference section.
    
    # Regular expression to match URLs
    url_pattern = r'https?://[^\s()<>]+(?:\([\w\d]+\)|(?:[^,.;:!?()"\'\s<>]))'
    
    # Find all URLs in the text
    all_urls = re.findall(url_pattern, report_text)
    
    # Deduplicate URLs
    unique_urls = list(dict.fromkeys(all_urls))
    
    # For simplicity, we'll consider the original content to be the entire report
    # In a real-world scenario, you might want to separate the references section
    original_content = report_text
    
    return original_content, unique_urls


def format_output(original_content: str, url_contents: List[Tuple[str, Optional[str], Optional[str]]]) -> str:
    """
    Format the final output by combining original content with extracted references in a beautiful Markdown format.
    
    Args:
        original_content: The original research report text
        url_contents: List of tuples (url, extracted_content, error_message)
    
    Returns:
        Combined text in Markdown format suitable for LLM consumption
    """
    # Start with the original content
    output = original_content
    
    # Add a reference appendix header with proper Markdown formatting
    output += "\n\n## Reference Content Appendix\n\n"
    output += "_This appendix contains content extracted from the referenced sources to provide additional context._\n\n"
    
    # Create a table of contents for the references
    if url_contents:
        output += "### Table of Contents\n\n"
        
        for i, (url, _, _) in enumerate(url_contents, 1):
            # Create a simplified URL for the TOC by removing protocols and common prefixes
            display_url = url.replace("https://", "").replace("http://", "").split("/")[0]
            # Create a link to the reference section
            ref_id = f"reference-{i}"
            output += f"{i}. [{display_url}](#{ref_id})\n"
        
        output += "\n---\n\n"
    
    # Add content for each reference URL
    for i, (url, content, error) in enumerate(url_contents, 1):
        # Create a section for each reference with anchor for navigation
        ref_id = f"reference-{i}"
        # Add an anchor point for linking and use a proper markdown heading
        output += f'<a id="{ref_id}"></a>\n'
        output += f'### Reference {i}: [{url}]({url})\n\n'
        output += f"_Retrieved: {datetime.now().strftime('%Y-%m-%d')}_\n\n"
        
        if content:
            # Format the content as a blockquote for better readability
            content_lines = content.split('\n')
            formatted_content = '\n'.join([f'> {line}' if line.strip() else '>' for line in content_lines])
            output += formatted_content
        elif error:
            output += f"**Error:** {error}\n"
        else:
            output += "_No content available_\n"
            
        # Add a horizontal rule between references
        output += "\n\n---\n\n"
    
    # Add attribution footer
    output += "\n\n_Content processed by Reference Augmentor_\n"
    
    return output 