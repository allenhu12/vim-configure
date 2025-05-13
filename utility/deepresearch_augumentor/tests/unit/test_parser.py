"""
Unit tests for the parse_report function in utils.py
"""
import pytest
from utils import parse_report

def test_parse_report_no_urls(sample_report_no_urls):
    """Test parsing a report with no URLs."""
    original_content, urls = parse_report(sample_report_no_urls)
    
    # Check that original content is preserved
    assert original_content == sample_report_no_urls
    # Check that the URL list is empty
    assert urls == []

def test_parse_report_single_url(sample_report_single_url):
    """Test parsing a report with a single URL."""
    original_content, urls = parse_report(sample_report_single_url)
    
    # Check that original content is preserved
    assert original_content == sample_report_single_url
    # Check that the URL is extracted
    assert len(urls) == 1
    assert urls[0] == "https://example.com/article"

def test_parse_report_multiple_urls(sample_report_multiple_urls):
    """Test parsing a report with multiple unique URLs."""
    original_content, urls = parse_report(sample_report_multiple_urls)
    
    # Check that original content is preserved
    assert original_content == sample_report_multiple_urls
    # Check that all URLs are extracted
    assert len(urls) == 3
    assert "https://example.com/article1" in urls
    assert "https://example.com/article2" in urls
    assert "http://another-site.org/page" in urls

def test_parse_report_duplicate_urls(sample_report_duplicate_urls):
    """Test parsing a report with duplicate URLs (should deduplicate)."""
    original_content, urls = parse_report(sample_report_duplicate_urls)
    
    # Check that original content is preserved
    assert original_content == sample_report_duplicate_urls
    # Check that URLs are deduplicated
    assert len(urls) == 2
    assert "https://example.com/article" in urls
    assert "https://another-example.com/page" in urls

def test_parse_report_mixed_format_urls(sample_report_mixed_format_urls):
    """Test parsing a report with URLs in various formats (plain, markdown, HTML)."""
    original_content, urls = parse_report(sample_report_mixed_format_urls)
    
    # Check that original content is preserved
    assert original_content == sample_report_mixed_format_urls
    # Check that URLs are extracted from different formats
    assert len(urls) == 3
    assert "https://example.com/article" in urls
    assert "https://plain-example.com/page" in urls
    assert "https://html-example.com/page" in urls

def test_parse_report_special_char_urls(sample_report_special_char_urls):
    """Test parsing a report with URLs containing special characters."""
    original_content, urls = parse_report(sample_report_special_char_urls)
    
    # Check that original content is preserved
    assert original_content == sample_report_special_char_urls
    # Check that URLs with special characters are extracted properly
    assert len(urls) == 3
    assert "https://example.com/search?q=test&page=1" in urls
    # The URL pattern may extract these slightly differently depending on the regex
    # Test for either the exact URL or reasonable variation
    assert any(u.startswith("https://example.com/article(2023)") for u in urls)
    assert any(u.startswith("https://example.com/path/with/[brackets]") for u in urls) 