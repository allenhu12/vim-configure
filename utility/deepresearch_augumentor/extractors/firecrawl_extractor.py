import os
import requests
from typing import Tuple, Optional, Dict, Any
from .base import ContentExtractorInterface


class FirecrawlExtractor(ContentExtractorInterface):
    """Content extractor using Firecrawl API."""
    
    def extract_text(self, url: str, api_key: Optional[str] = None, **kwargs) -> Tuple[Optional[str], Optional[str]]:
        """
        Extract text content from a URL using Firecrawl API.
        
        Args:
            url: The URL to extract content from
            api_key: Firecrawl API key (can be passed directly or via env var)
            **kwargs: Additional parameters for the Firecrawl API
        
        Returns:
            Tuple of (extracted_text, error_message)
        """
        api_key = api_key or os.environ.get("FIRECRAWL_API_KEY")
        
        if not api_key:
            return None, "Firecrawl API key not provided. Set FIRECRAWL_API_KEY environment variable."
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        try:
            # Note: Update the endpoint and payload structure based on 
            # actual Firecrawl API documentation
            response = requests.post(
                "https://api.firecrawl.dev/v1/extract",  # Example endpoint
                headers=headers,
                json={"url": url}
            )
            
            if response.status_code == 200:
                json_response = response.json()
                if "content" in json_response:
                    return json_response["content"], None
                else:
                    return None, f"Response format error: {json_response}"
            else:
                return None, f"API error: {response.status_code} - {response.text}"
        
        except Exception as e:
            return None, f"Exception while calling Firecrawl API: {str(e)}" 