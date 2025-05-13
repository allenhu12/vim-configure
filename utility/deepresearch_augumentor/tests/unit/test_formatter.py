"""
Unit tests for the format_output function in utils.py
"""
import pytest
from utils import format_output

def test_format_output_no_references():
    """Test formatting output with no references."""
    original_content = "This is the original report content."
    url_contents = []
    
    result = format_output(original_content, url_contents)
    
    # Check that original content is preserved
    assert result.startswith(original_content)
    # Check that delimiters are added
    assert "REFERENCE CONTENT APPENDIX" in result
    # Check that no reference content is added
    assert "BEGIN SOURCE" not in result
    assert "END SOURCE" not in result

def test_format_output_one_success():
    """Test formatting output with one successful reference."""
    original_content = "This is the original report content."
    url = "https://example.com/article"
    content = "This is the extracted content."
    url_contents = [(url, content, None)]
    
    result = format_output(original_content, url_contents)
    
    # Check that original content is preserved
    assert result.startswith(original_content)
    # Check that delimiters are added
    assert "REFERENCE CONTENT APPENDIX" in result
    # Check that reference content is added with correct delimiters
    assert f"BEGIN SOURCE: {url}" in result
    assert content in result
    assert f"END SOURCE: {url}" in result
    # Check that error message is not included
    assert "Content extraction failed" not in result

def test_format_output_one_failure():
    """Test formatting output with one failed reference."""
    original_content = "This is the original report content."
    url = "https://example.com/article"
    error = "Connection timeout"
    url_contents = [(url, None, error)]
    
    result = format_output(original_content, url_contents)
    
    # Check that original content is preserved
    assert result.startswith(original_content)
    # Check that delimiters are added
    assert "REFERENCE CONTENT APPENDIX" in result
    # Check that reference content includes error message
    assert f"BEGIN SOURCE: {url}" in result
    assert f"Content extraction failed: {error}" in result
    assert f"END SOURCE: {url}" in result

def test_format_output_multiple_mixed():
    """Test formatting output with multiple references (mix of success/failure)."""
    original_content = "This is the original report content."
    url1 = "https://example.com/article1"
    content1 = "This is the first extracted content."
    url2 = "https://example.com/article2"
    error2 = "HTTP error: 404"
    url3 = "https://example.com/article3"
    content3 = "This is the third extracted content."
    
    url_contents = [
        (url1, content1, None),
        (url2, None, error2),
        (url3, content3, None)
    ]
    
    result = format_output(original_content, url_contents)
    
    # Check that original content is preserved
    assert result.startswith(original_content)
    # Check that delimiters are added
    assert "REFERENCE CONTENT APPENDIX" in result
    
    # Check first reference (success)
    assert f"BEGIN SOURCE: {url1}" in result
    assert content1 in result
    assert f"END SOURCE: {url1}" in result
    
    # Check second reference (failure)
    assert f"BEGIN SOURCE: {url2}" in result
    assert f"Content extraction failed: {error2}" in result
    assert f"END SOURCE: {url2}" in result
    
    # Check third reference (success)
    assert f"BEGIN SOURCE: {url3}" in result
    assert content3 in result
    assert f"END SOURCE: {url3}" in result

def test_format_output_none_content_and_error():
    """Test formatting output with a reference having both content and error as None."""
    original_content = "This is the original report content."
    url = "https://example.com/article"
    url_contents = [(url, None, None)]
    
    result = format_output(original_content, url_contents)
    
    # Check that original content is preserved
    assert result.startswith(original_content)
    # Check that delimiters are added
    assert "REFERENCE CONTENT APPENDIX" in result
    # Check that reference has default message for no content
    assert f"BEGIN SOURCE: {url}" in result
    assert "[No content available]" in result
    assert f"END SOURCE: {url}" in result

def test_format_output_llm_friendly_formatting():
    """Test that the output is formatted in an LLM-friendly way with clear delimiters."""
    original_content = "This is the original report content."
    url = "https://example.com/article"
    content = "This is the extracted content."
    url_contents = [(url, content, None)]
    
    result = format_output(original_content, url_contents)
    
    # Check that there are clear section delimiters
    assert "="*10 in result  # Some delimiter pattern of equal signs
    
    # Verify the structure: original content, then delimiter, then appendix heading,
    # then delimiter, then reference content with its own delimiters
    sections = result.split("REFERENCE CONTENT APPENDIX")
    assert len(sections) == 2
    
    # Original content should be before the appendix heading
    assert original_content in sections[0]
    
    # Reference content should be after the appendix heading
    reference_section = sections[1]
    assert f"BEGIN SOURCE: {url}" in reference_section
    assert content in reference_section
    assert f"END SOURCE: {url}" in reference_section 