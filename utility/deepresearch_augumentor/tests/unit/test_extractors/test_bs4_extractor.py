"""
Unit tests for BeautifulSoupExtractor
"""
import pytest
import requests
from unittest.mock import patch, MagicMock
from extractors.local_bs4_extractor import BeautifulSoupExtractor

@pytest.fixture
def extractor():
    """Return a BeautifulSoupExtractor instance."""
    return BeautifulSoupExtractor()

def test_extract_text_success(extractor, mock_html_content):
    """Test successful text extraction."""
    url = "https://example.com"
    
    # Mock requests.get to return our test HTML
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.text = mock_html_content
    
    with patch("requests.get", return_value=mock_response):
        text, error = extractor.extract_text(url)
    
    # Check that extraction was successful
    assert error is None
    assert text is not None
    assert "Main Article Title" in text
    assert "This is the main content paragraph." in text
    assert "This is another paragraph" in text
    
    # Check that script and style content was removed
    assert "This should be removed" not in text
    assert "font-family: Arial" not in text
    
    # Check that HTML tags were removed
    assert "<h1>" not in text
    assert "<p>" not in text

def test_extract_text_http_error(extractor):
    """Test handling of HTTP error."""
    url = "https://example.com"
    
    # Mock requests.get to return 404
    mock_response = MagicMock()
    mock_response.status_code = 404
    
    with patch("requests.get", return_value=mock_response):
        text, error = extractor.extract_text(url)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "HTTP error: 404" in error

def test_extract_text_connection_error(extractor):
    """Test handling of connection error."""
    url = "https://example.com"
    
    # Mock requests.get to raise ConnectionError
    with patch("requests.get", side_effect=requests.ConnectionError("Failed to connect")):
        text, error = extractor.extract_text(url)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "Exception while extracting content" in error
    assert "Failed to connect" in error

def test_extract_text_timeout(extractor):
    """Test handling of timeout."""
    url = "https://example.com"
    
    # Mock requests.get to raise Timeout
    with patch("requests.get", side_effect=requests.Timeout("Request timed out")):
        text, error = extractor.extract_text(url)
    
    # Check that error was returned properly
    assert text is None
    assert error is not None
    assert "Exception while extracting content" in error
    assert "Request timed out" in error

def test_extract_text_empty_content(extractor):
    """Test handling of empty content."""
    url = "https://example.com"
    
    # Mock requests.get to return empty HTML
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.text = "<html><body></body></html>"
    
    with patch("requests.get", return_value=mock_response):
        text, error = extractor.extract_text(url)
    
    # Check that extraction returns empty string, not error
    assert error is None
    assert text == ""

def test_extract_text_custom_timeout(extractor):
    """Test that custom timeout is passed to requests."""
    url = "https://example.com"
    timeout = 30
    
    # Mock requests.get
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.text = "<html><body>Test</body></html>"
    
    with patch("requests.get", return_value=mock_response) as mock_get:
        extractor.extract_text(url, timeout=timeout)
    
    # Check that timeout was passed to requests.get
    args, kwargs = mock_get.call_args
    assert kwargs["timeout"] == timeout

def test_extract_text_custom_user_agent(extractor):
    """Test that custom user agent is passed to requests."""
    url = "https://example.com"
    user_agent = "Custom User Agent"
    
    # Mock requests.get
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.text = "<html><body>Test</body></html>"
    
    with patch("requests.get", return_value=mock_response) as mock_get:
        extractor.extract_text(url, user_agent=user_agent)
    
    # Check that user agent was passed in headers
    args, kwargs = mock_get.call_args
    assert kwargs["headers"]["User-Agent"] == user_agent 