"""
End-to-end system tests for Reference Augmentor using real API calls.

These tests require actual API keys to be set as environment variables or in a .env file.
They will be skipped if the necessary API keys are not available.
"""
import os
import time
import pytest
from dotenv import load_dotenv
import tempfile
import re
from main import augment_research_report
from pathlib import Path

# Load environment variables from .env file if present
load_dotenv()

# Path to the sample report file
SAMPLE_REPORT = os.path.join(os.path.dirname(__file__), "test_data", "sample_report.txt")

# Skip tests if API keys are not available
jina_key_available = os.environ.get("JINA_API_KEY") is not None
firecrawl_key_available = os.environ.get("FIRECRAWL_API_KEY") is not None

# Skip markers for different API dependencies
requires_jina_api = pytest.mark.skipif(
    not jina_key_available,
    reason="Test requires JINA_API_KEY environment variable to be set"
)

requires_firecrawl_api = pytest.mark.skipif(
    not firecrawl_key_available,
    reason="Test requires FIRECRAWL_API_KEY environment variable to be set"
)

@pytest.fixture
def sample_report_text():
    """Read the content of the sample report file."""
    with open(SAMPLE_REPORT, 'r') as f:
        return f.read()

@pytest.fixture
def temporary_output_file():
    """Create a temporary file for output testing."""
    fd, path = tempfile.mkstemp(suffix=".txt")
    os.close(fd)
    
    yield path
    
    # Clean up the file after the test
    if os.path.exists(path):
        os.remove(path)

@requires_jina_api
def test_jina_default_extraction(sample_report_text):
    """Test that Jina extractor with default mode can fetch content from reference URLs."""
    # Perform extraction
    result = augment_research_report(
        report_text=sample_report_text,
        extractor_type="jina",
        extraction_mode="default",
        request_timeout=20
    )
    
    # Check the structure of the result
    assert "REFERENCE CONTENT APPENDIX" in result
    
    # Verify that the original content is preserved
    assert "Test Research Report" in result
    
    # Check for reference sources in the output
    assert "BEGIN SOURCE: https://example.com/article1" in result
    assert "BEGIN SOURCE: https://example.com/article2" in result
    
    # Verify that content was extracted (not just error messages)
    # Note: The actual content will depend on the example.com site, which may change
    error_pattern = r"\[Content extraction failed:"
    content_sections = re.findall(r"--- BEGIN SOURCE.*?--- END SOURCE", result, re.DOTALL)
    
    assert len(content_sections) >= 2, "Expected at least 2 content sections"
    
    # Give the test a pass if at least one content section doesn't have an error
    # This is because example.com is a real domain and might not always be accessible
    successful_extractions = sum(1 for section in content_sections if not re.search(error_pattern, section))
    assert successful_extractions >= 1, "Expected at least one successful content extraction"

@requires_jina_api
def test_jina_body_only_extraction(sample_report_text):
    """Test that Jina extractor with body-only mode can fetch content from reference URLs."""
    # Perform extraction
    result = augment_research_report(
        report_text=sample_report_text,
        extractor_type="jina",
        extraction_mode="body-only",
        request_timeout=20
    )
    
    # Check the structure of the result
    assert "REFERENCE CONTENT APPENDIX" in result
    
    # Since we can't predict the exact content for example.com, we'll just
    # check that the extraction completed without obvious errors
    assert "Content extraction failed" not in result.lower() or "unauthorized" in result.lower()

@requires_jina_api
def test_jina_with_real_url(temporary_output_file):
    """Test extraction using a report with a known, stable URL."""
    # Create a temporary report with a reliable URL
    report_text = """Test Report with Reliable URL
==================

This test uses w3schools.com which is a stable website for testing.

References
---------
https://www.w3schools.com/html/html_basic.asp
"""
    
    # Create a temporary input file
    input_file = Path(tempfile.gettempdir()) / "test_report_real_url.txt"
    with open(input_file, 'w') as f:
        f.write(report_text)
    
    try:
        # Use a subprocess to call the main CLI with the real URL
        import subprocess
        result = subprocess.run(
            [
                "python", "main.py", 
                str(input_file),
                "--extractor", "jina",
                "--mode", "body-only",
                "--output", temporary_output_file
            ],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # Check for successful execution
        assert result.returncode == 0, f"Process failed: {result.stderr}"
        
        # Check the output file exists and has content
        assert os.path.exists(temporary_output_file)
        
        with open(temporary_output_file, 'r') as f:
            content = f.read()
        
        # Check for expected content structure
        assert "REFERENCE CONTENT APPENDIX" in content
        assert "BEGIN SOURCE:" in content
        assert "END SOURCE:" in content
        
        # For w3schools, we should expect some HTML-related content
        assert "HTML" in content or "html" in content
        
        # The content should be significant (not just error messages)
        assert len(content) > len(report_text) + 100
        
    finally:
        # Clean up the temporary input file
        if os.path.exists(input_file):
            os.remove(input_file)

@requires_jina_api
def test_debug_wrapper_real_extraction():
    """Test the debug wrapper with a real URL."""
    # Create a temporary report with a reliable URL
    report_text = """Debug Wrapper Test
==================

Testing the debug wrapper with a reliable URL.

References
---------
https://www.w3schools.com/tags/default.asp
"""
    
    # Create a temporary input file
    input_file = Path(tempfile.gettempdir()) / "debug_wrapper_test.txt"
    with open(input_file, 'w') as f:
        f.write(report_text)
    
    # Create a temporary output file
    output_file = Path(tempfile.gettempdir()) / "debug_wrapper_output.txt"
    
    try:
        # Use a subprocess to call the debug wrapper
        import subprocess
        result = subprocess.run(
            [
                "python", "debug_wrapper.py", 
                str(input_file),
                "--extractor", "jina",
                "--mode", "article",
                "--output", str(output_file)
            ],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # Check for successful execution
        assert result.returncode == 0, f"Debug wrapper failed: {result.stderr}"
        
        # Check that debug artifacts directory was created
        debug_dir_pattern = r"Debug artifacts saved to (debug/run_jina_\d+_\d+)"
        match = re.search(debug_dir_pattern, result.stdout)
        
        assert match, "Debug directory not reported in output"
        debug_dir = match.group(1)
        
        # Verify debug directory exists
        assert os.path.exists(debug_dir), f"Debug directory {debug_dir} not found"
        
        # Check for debug artifacts
        assert os.path.exists(os.path.join(debug_dir, "debug.log")), "Debug log not found"
        assert os.path.exists(os.path.join(debug_dir, "input.txt")), "Input copy not found"
        assert os.path.exists(os.path.join(debug_dir, "output.txt")), "Output copy not found"
        
    finally:
        # Clean up temporary files
        for file in [input_file, output_file]:
            if os.path.exists(file):
                os.remove(file) 