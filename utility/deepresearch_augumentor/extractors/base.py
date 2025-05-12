from abc import ABC, abstractmethod
from typing import Tuple, Optional, Dict, Any


class ContentExtractorInterface(ABC):
    """Abstract base class defining the interface for all content extractors."""
    
    @abstractmethod
    def extract_text(self, url: str, api_key: Optional[str] = None, **kwargs) -> Tuple[Optional[str], Optional[str]]:
        """
        Extract main textual content from a URL.
        
        Args:
            url: The URL to extract content from
            api_key: Optional API key for services requiring authentication
            **kwargs: Additional extractor-specific parameters
            
        Returns:
            A tuple of (extracted_text, error_message)
            - If successful: (text_content, None)
            - If failed: (None, error_description)
        """
        pass 