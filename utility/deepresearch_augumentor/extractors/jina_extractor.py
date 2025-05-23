import os
import requests
from typing import Tuple, Optional, Dict, Any
import json
from .base import ContentExtractorInterface


class JinaAIExtractor(ContentExtractorInterface):
    """Content extractor using Jina AI Reader API."""
    
    def extract_text(self, url: str, api_key: Optional[str] = None, **kwargs) -> Tuple[Optional[str], Optional[str]]:
        """
        Extract text content from a URL using Jina AI Reader API.
        
        Args:
            url: The URL to extract content from
            api_key: Jina AI API key (can be passed directly or via env var)
            **kwargs: Additional parameters for the Jina Reader API
                - timeout: Request timeout in seconds
                - target_selector: CSS selector to target specific elements
                - remove_selector: CSS selector to exclude elements
                - links_handling: How to handle links, options:
                   * "default": Standard link handling (default)
                   * "discarded": Remove all links but keep the text
                   * "referenced": Show links as numbered references
                - links_summary: Whether to include a links summary section (true/false/all)
                - with_images_summary: Whether to include images summary (true/false/all)
                - retain_images: Control image inclusion (default: include, 'none' to exclude)
                - engine: Engine type ('browser', 'direct', 'cf-browser-rendering')
                - with_generated_alt: Generate alt text for images without captions
        
        Returns:
            Tuple of (extracted_text, error_message)
        """
        # Get your Jina AI API key for free: https://jina.ai/?sui=apikey
        api_key = api_key or os.environ.get("JINA_API_KEY")
        
        if not api_key:
            return None, "Jina AI API key not provided. Set JINA_API_KEY environment variable."
        
        # Extract parameters from kwargs with defaults
        timeout = kwargs.get('timeout', 10)
        target_selector = kwargs.get('target_selector', None)
        remove_selector = kwargs.get('remove_selector', None)
        links_handling = kwargs.get('links_handling', 'default')
        links_summary = kwargs.get('links_summary', None)
        with_images_summary = kwargs.get('with_images_summary', None)
        retain_images = kwargs.get('retain_images', None)
        engine = kwargs.get('engine', None)
        with_generated_alt = kwargs.get('with_generated_alt', None)
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        # Add request timeout if provided
        if timeout:
            headers["X-Timeout"] = str(timeout)
        
        # Add content targeting headers
        if target_selector:
            headers["X-Target-Selector"] = target_selector
        if remove_selector:
            headers["X-Remove-Selector"] = remove_selector
        
        # Add image handling headers
        if with_images_summary is not None:
            if with_images_summary is True:
                headers["X-With-Images-Summary"] = "true"
            elif with_images_summary == "all":
                headers["X-With-Images-Summary"] = "all"
            else:
                headers["X-With-Images-Summary"] = "false"
        
        if retain_images == "none":
            headers["X-Retain-Images"] = "none"
        
        if with_generated_alt is True:
            headers["X-With-Generated-Alt"] = "true"
            
        # Add engine selection if provided
        if engine:
            headers["X-Engine"] = engine
        
        # Handle links differently based on user preference
        if links_handling == 'discarded':
            headers["X-Md-Link-Style"] = "discarded"  # Replace links with anchor text only
        elif links_handling == 'referenced':
            headers["X-Md-Link-Style"] = "referenced"  # Show links as numbered references
        
        # Control the links summary section
        if links_summary is not None:
            if links_summary is False or links_summary == 'none':
                # Don't include a links summary section
                headers["X-With-Links-Summary"] = "false"
            elif links_summary == 'all':
                headers["X-With-Links-Summary"] = "all"
            else:
                headers["X-With-Links-Summary"] = "true"
        
        # Log the request details if debugging is enabled
        if kwargs.get('debug'):
            print(f"Request headers: {headers}")
        
        try:
            response = requests.post(
                "https://r.jina.ai/",
                headers=headers,
                json={"url": url},
                timeout=timeout  # Use the timeout for the request itself
            )
            
            if response.status_code == 200:
                json_response = response.json()
                if "data" in json_response and "content" in json_response["data"]:
                    return json_response["data"]["content"], None
                else:
                    return None, f"Response format error: {json_response}"
            else:
                error_message = f"API error: {response.status_code}"
                try:
                    error_details = response.json()
                    error_message += f" - {json.dumps(error_details)}"
                except:
                    error_message += f" - {response.text}"
                return None, error_message
        
        except requests.exceptions.Timeout:
            return None, f"Request timed out after {timeout} seconds"
        except requests.exceptions.ConnectionError:
            return None, "Connection error. Please check your internet connection."
        except Exception as e:
            return None, f"Exception while calling Jina AI Reader API: {str(e)}" 