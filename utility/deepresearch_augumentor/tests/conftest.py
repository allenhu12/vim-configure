"""
Common test fixtures and utilities for the Reference Augmentor test suite.
"""
import os
import pytest
import tempfile
from unittest.mock import patch

# Sample report text for testing
@pytest.fixture
def sample_report_no_urls():
    return """
    This is a sample research report.
    It contains no URLs in the references.
    """

@pytest.fixture
def sample_report_single_url():
    return """
    This is a sample research report.
    
    References:
    https://example.com/article
    """

@pytest.fixture
def sample_report_multiple_urls():
    return """
    This is a sample research report.
    
    References:
    https://example.com/article1
    https://example.com/article2
    http://another-site.org/page
    """

@pytest.fixture
def sample_report_duplicate_urls():
    return """
    This is a sample research report.
    
    References:
    https://example.com/article
    https://example.com/article
    https://another-example.com/page
    """

@pytest.fixture
def sample_report_mixed_format_urls():
    return """
    This is a sample research report.
    
    References:
    [Example Link](https://example.com/article)
    Plain URL: https://plain-example.com/page
    <a href="https://html-example.com/page">HTML Link</a>
    """

@pytest.fixture
def sample_report_special_char_urls():
    return """
    This is a sample research report.
    
    References:
    https://example.com/search?q=test&page=1
    https://example.com/article(2023).html
    https://example.com/path/with/[brackets].pdf
    """

@pytest.fixture
def mock_html_content():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Page</title>
        <style>
            body { font-family: Arial; }
        </style>
        <script>
            console.log("This should be removed");
        </script>
    </head>
    <body>
        <header>Header content</header>
        <nav>Navigation menu</nav>
        <main>
            <h1>Main Article Title</h1>
            <p>This is the main content paragraph.</p>
            <p>This is another paragraph with <a href="https://example.com">a link</a>.</p>
        </main>
        <footer>Footer content</footer>
    </body>
    </html>
    """

@pytest.fixture
def mock_jina_response_success():
    return {
        "code": 200,
        "status": 20000,
        "data": {
            "title": "Test Page",
            "description": "Test page description",
            "url": "https://example.com/page",
            "content": "This is the extracted content from Jina AI Reader API.",
            "usage": {"tokens": 150}
        }
    }

@pytest.fixture
def mock_jina_response_error():
    return {
        "code": 401,
        "status": 40100,
        "message": "Unauthorized: Invalid API key"
    }

@pytest.fixture
def mock_firecrawl_response_success():
    return {
        "content": "This is the extracted content from Firecrawl API."
    }

@pytest.fixture
def mock_firecrawl_response_error():
    return {
        "error": "Unauthorized: Invalid API key"
    }

@pytest.fixture
def temp_env_variables():
    """Fixture to temporarily set and clean up environment variables."""
    original_environ = os.environ.copy()
    
    # Set test environment variables
    os.environ["JINA_API_KEY"] = "test-jina-api-key"
    os.environ["FIRECRAWL_API_KEY"] = "test-firecrawl-api-key"
    
    yield
    
    # Restore original environment
    os.environ.clear()
    os.environ.update(original_environ)

@pytest.fixture
def temp_dotenv_file():
    """Fixture to create a temporary .env file."""
    # Create a temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create a .env file
        env_path = os.path.join(temp_dir, ".env")
        with open(env_path, "w") as f:
            f.write("JINA_API_KEY=test-dotenv-jina-api-key\n")
            f.write("FIRECRAWL_API_KEY=test-dotenv-firecrawl-api-key\n")
        
        # Patch os.path.exists to return True for .env
        with patch("os.path.exists", return_value=True):
            # Patch open to return our temp file when .env is requested
            def mock_open(file, *args, **kwargs):
                if file == ".env":
                    return open(env_path, *args, **kwargs)
                return open(file, *args, **kwargs)
            
            with patch("builtins.open", mock_open):
                yield env_path 