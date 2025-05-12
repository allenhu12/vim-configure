import requests
from bs4 import BeautifulSoup
from typing import Tuple, Optional, Dict, Any
from .base import ContentExtractorInterface


class BeautifulSoupExtractor(ContentExtractorInterface):
    """Content extractor using local BeautifulSoup parsing."""
    
    def extract_text(self, url: str, api_key: Optional[str] = None, **kwargs) -> Tuple[Optional[str], Optional[str]]:
        """
        Extract text content from a URL using BeautifulSoup.
        
        Args:
            url: The URL to extract content from
            api_key: Not used for this extractor
            **kwargs: Additional parameters
                - timeout: Request timeout in seconds
                - user_agent: Custom User-Agent string
        
        Returns:
            Tuple of (extracted_text, error_message)
        """
        timeout = kwargs.get('timeout', 10)
        user_agent = kwargs.get('user_agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
        
        headers = {
            "User-Agent": user_agent
        }
        
        try:
            response = requests.get(url, headers=headers, timeout=timeout)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.text, 'html.parser')
                
                # Remove script and style elements
                for script in soup(["script", "style"]):
                    script.extract()
                
                # Extract text content
                text = soup.get_text(separator='\n')
                
                # Clean up whitespace
                lines = (line.strip() for line in text.splitlines())
                chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
                text = '\n'.join(chunk for chunk in chunks if chunk)
                
                return text, None
            else:
                return None, f"HTTP error: {response.status_code}"
        
        except Exception as e:
            return None, f"Exception while extracting content: {str(e)}" 