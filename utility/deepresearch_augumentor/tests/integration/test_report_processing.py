"""
Integration tests for the report processing flow
"""
import os
import pytest
from unittest.mock import patch, MagicMock
from main import augment_research_report
from extractors.base import ContentExtractorInterface

class MockExtractor(ContentExtractorInterface):
    """Mock extractor for integration testing."""
    
    def __init__(self, responses=None):
        """Initialize with predefined responses for URLs."""
        self.responses = responses or {}
        self.calls = []
    
    def extract_text(self, url, api_key=None, **kwargs):
        """Mock implementation that returns predefined responses."""
        self.calls.append((url, api_key, kwargs))
        
        if url in self.responses:
            return self.responses[url]
        
        # Default response for unknown URLs
        return f"Extracted content from {url}", None

@pytest.fixture
def mock_get_extractor():
    """Patch get_extractor to return our mock."""
    mock_extractor = MockExtractor()
    
    with patch("main.get_extractor", return_value=mock_extractor):
        yield mock_extractor

def test_full_flow_basic(mock_get_extractor):
    """Test the full processing flow with a mock extractor."""
    # Create a sample report with references
    report = """
    This is a sample research report.
    
    References:
    https://example.com/article1
    https://example.com/article2
    """
    
    # Configure mock responses
    mock_get_extractor.responses = {
        "https://example.com/article1": ("Content from article 1", None),
        "https://example.com/article2": (None, "Error fetching article 2")
    }
    
    # Process the report
    result = augment_research_report(report, extractor_type="mock")
    
    # Check that both URLs were processed
    assert len(mock_get_extractor.calls) == 2
    assert mock_get_extractor.calls[0][0] == "https://example.com/article1"
    assert mock_get_extractor.calls[1][0] == "https://example.com/article2"
    
    # Check that original content is preserved
    assert report in result
    
    # Check that appendix and results are included
    assert "REFERENCE CONTENT APPENDIX" in result
    assert "BEGIN SOURCE: https://example.com/article1" in result
    assert "Content from article 1" in result
    assert "BEGIN SOURCE: https://example.com/article2" in result
    assert "Error fetching article 2" in result

def test_full_flow_with_api_key():
    """Test the full processing flow with API key handling."""
    # Create a sample report with a reference
    report = """
    This is a sample research report.
    
    References:
    https://example.com/article
    """
    
    # Create a mock extractor that checks API key
    mock_extractor = MockExtractor()
    
    with patch("main.get_extractor", return_value=mock_extractor):
        with patch.dict(os.environ, {"JINA_API_KEY": "test-api-key"}, clear=True):
            augment_research_report(report, extractor_type="jina")
    
    # Check that API key was passed to the extractor
    assert len(mock_extractor.calls) == 1
    _, api_key, _ = mock_extractor.calls[0]
    assert api_key == "test-api-key"

def test_full_flow_with_extraction_mode():
    """Test the full processing flow with extraction mode settings."""
    # Create a sample report with a reference
    report = """
    This is a sample research report.
    
    References:
    https://example.com/article
    """
    
    # Create a mock extractor
    mock_extractor = MockExtractor()
    
    with patch("main.get_extractor", return_value=mock_extractor):
        # Use a predefined extraction mode (body-only)
        augment_research_report(report, extractor_type="jina", extraction_mode="body-only")
    
    # Check that mode settings were passed to the extractor
    assert len(mock_extractor.calls) == 1
    _, _, kwargs = mock_extractor.calls[0]
    assert kwargs["target_selector"] == "body"
    assert kwargs["remove_selector"] == "nav,header,footer,aside,script,style"

def test_full_flow_with_timeout():
    """Test the full processing flow with custom timeout."""
    # Create a sample report with a reference
    report = """
    This is a sample research report.
    
    References:
    https://example.com/article
    """
    
    # Create a mock extractor
    mock_extractor = MockExtractor()
    
    with patch("main.get_extractor", return_value=mock_extractor):
        # Use a custom timeout
        augment_research_report(report, extractor_type="local_bs4", request_timeout=30)
    
    # Check that timeout was passed to the extractor
    assert len(mock_extractor.calls) == 1
    _, _, kwargs = mock_extractor.calls[0]
    assert kwargs["timeout"] == 30 