import re
from typing import Tuple, List, Optional
import os
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
    Format the final output by combining original content with extracted references.
    
    Args:
        original_content: The original research report text
        url_contents: List of tuples (url, extracted_content, error_message)
    
    Returns:
        Combined text suitable for LLM consumption
    """
    output = original_content
    
    # Add a clear delimiter for the appended reference content
    output += "\n\n" + "="*50 + "\n"
    output += "REFERENCE CONTENT APPENDIX\n"
    output += "="*50 + "\n\n"
    
    # Add content for each reference URL
    for url, content, error in url_contents:
        output += f"\n\n--- BEGIN SOURCE: {url} ---\n\n"
        
        if content:
            output += content
        elif error:
            output += f"[Content extraction failed: {error}]"
        else:
            output += "[No content available]"
            
        output += f"\n\n--- END SOURCE: {url} ---\n"
    
    return output 