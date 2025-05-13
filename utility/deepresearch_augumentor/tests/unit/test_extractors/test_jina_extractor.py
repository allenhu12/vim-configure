"""
Unit tests for JinaAIExtractor
"""
import os
import pytest
import requests
import json
from unittest.mock import patch, MagicMock
from extractors.jina_extractor import JinaAIExtractor

@pytest.fixture
def extractor():
    """Return a JinaAIExtractor instance."""
    return JinaAIExtractor()

def test_extract_text_success(extractor, mock_jina_response_success):
    """Test successful text extraction with Jina AI API."""
    url = "https://example.com"
    api_key = "test-api-key"
    
    # Mock successful requests.post
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_jina_response_success
    
    with patch("requests.post", return_value=mock_response):
        text, error = extractor.extract_text(url, api_key=api_key)
    
    # Check that extraction was successful
    assert error is None
    assert text is not None
    assert text == mock_jina_response_success["data"]["content"]

def test_extract_text_missing_api_key(extractor):
    """Test handling of missing API key."""
    url = "https://example.com"
    
    # Ensure environment is clean
    with patch.dict(os.environ, {}, clear=True):
        text, error = extractor.extract_text(url)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "API key not provided" in error

def test_extract_text_api_error(extractor, mock_jina_response_error):
    """Test handling of API error."""
    url = "https://example.com"
    api_key = "test-api-key"
    
    # Mock error response from API
    mock_response = MagicMock()
    mock_response.status_code = 401
    mock_response.json.return_value = mock_jina_response_error
    mock_response.text = json.dumps(mock_jina_response_error)
    
    with patch("requests.post", return_value=mock_response):
        text, error = extractor.extract_text(url, api_key=api_key)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "API error: 401" in error

def test_extract_text_connection_error(extractor):
    """Test handling of connection error."""
    url = "https://example.com"
    api_key = "test-api-key"
    
    # Mock requests.post to raise ConnectionError
    with patch("requests.post", side_effect=requests.ConnectionError("Failed to connect")):
        text, error = extractor.extract_text(url, api_key=api_key)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "Exception while calling Jina AI Reader API" in error
    assert "Failed to connect" in error

def test_extract_text_timeout(extractor):
    """Test handling of timeout."""
    url = "https://example.com"
    api_key = "test-api-key"
    
    # Mock requests.post to raise Timeout
    with patch("requests.post", side_effect=requests.Timeout("Request timed out")):
        text, error = extractor.extract_text(url, api_key=api_key)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "Exception while calling Jina AI Reader API" in error
    assert "Request timed out" in error

def test_extract_text_invalid_response_format(extractor):
    """Test handling of invalid response format."""
    url = "https://example.com"
    api_key = "test-api-key"
    
    # Mock response with missing data or content fields
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"code": 200, "status": 20000}  # Missing data/content
    
    with patch("requests.post", return_value=mock_response):
        text, error = extractor.extract_text(url, api_key=api_key)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "Response format error" in error

def test_extract_text_with_target_selector(extractor):
    """Test extraction with target_selector parameter."""
    url = "https://example.com"
    api_key = "test-api-key"
    target_selector = "main,article"
    
    # Mock successful requests.post
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "code": 200,
        "status": 20000,
        "data": {
            "content": "Targeted content",
            "url": url
        }
    }
    
    with patch("requests.post", return_value=mock_response) as mock_post:
        text, error = extractor.extract_text(
            url, 
            api_key=api_key,
            target_selector=target_selector
        )
    
    # Check that target_selector was passed in the header
    _, kwargs = mock_post.call_args
    assert kwargs["headers"]["X-Target-Selector"] == target_selector
    assert error is None
    assert text == "Targeted content"

def test_extract_text_with_remove_selector(extractor):
    """Test extraction with remove_selector parameter."""
    url = "https://example.com"
    api_key = "test-api-key"
    remove_selector = "nav,footer,header"
    
    # Mock successful requests.post
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "code": 200,
        "status": 20000,
        "data": {
            "content": "Content with elements removed",
            "url": url
        }
    }
    
    with patch("requests.post", return_value=mock_response) as mock_post:
        text, error = extractor.extract_text(
            url, 
            api_key=api_key,
            remove_selector=remove_selector
        )
    
    # Check that remove_selector was passed in the header
    _, kwargs = mock_post.call_args
    assert kwargs["headers"]["X-Remove-Selector"] == remove_selector
    assert error is None
    assert text == "Content with elements removed"

def test_extract_text_with_timeout_parameter(extractor):
    """Test extraction with timeout parameter."""
    url = "https://example.com"
    api_key = "test-api-key"
    timeout = 30
    
    # Mock successful requests.post
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "code": 200,
        "status": 20000,
        "data": {
            "content": "Content",
            "url": url
        }
    }
    
    with patch("requests.post", return_value=mock_response) as mock_post:
        text, error = extractor.extract_text(
            url, 
            api_key=api_key,
            timeout=timeout
        )
    
    # Check that timeout was passed in the header
    _, kwargs = mock_post.call_args
    assert kwargs["headers"]["X-Timeout"] == str(timeout)
    assert error is None 