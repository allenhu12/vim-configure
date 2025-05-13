"""
Unit tests for the extractor factory (get_extractor function) in main.py
"""
import pytest
from main import get_extractor
from extractors import JinaAIExtractor, FirecrawlExtractor, BeautifulSoupExtractor

def test_get_extractor_jina():
    """Test getting JinaAIExtractor."""
    extractor = get_extractor("jina")
    assert isinstance(extractor, JinaAIExtractor)

def test_get_extractor_firecrawl():
    """Test getting FirecrawlExtractor."""
    extractor = get_extractor("firecrawl")
    assert isinstance(extractor, FirecrawlExtractor)

def test_get_extractor_local_bs4():
    """Test getting BeautifulSoupExtractor."""
    extractor = get_extractor("local_bs4")
    assert isinstance(extractor, BeautifulSoupExtractor)

def test_get_extractor_invalid():
    """Test that an invalid extractor type raises ValueError."""
    with pytest.raises(ValueError) as excinfo:
        get_extractor("invalid_extractor")
    
    # Check that the error message contains the supported types
    error_msg = str(excinfo.value)
    assert "Unsupported extractor type" in error_msg
    assert "jina" in error_msg
    assert "firecrawl" in error_msg
    assert "local_bs4" in error_msg

def test_get_extractor_case_sensitive():
    """Test that extractor type is case sensitive."""
    with pytest.raises(ValueError):
        get_extractor("JINA")  # Should be lowercase "jina" 