"""
Unit tests for configuration loading in augment_research_report function
"""
import os
import pytest
from unittest.mock import patch, MagicMock
from dotenv import load_dotenv
from main import augment_research_report

@pytest.fixture
def mock_parse_report():
    """Mock the parse_report function to return fixed values."""
    with patch("utils.parse_report") as mock:
        mock.return_value = ("Original content", ["https://example.com"])
        yield mock

@pytest.fixture
def mock_extractor():
    """Mock extractor with a spy on extract_text."""
    with patch("main.get_extractor") as mock_get_extractor:
        mock_extract_text = patch("extractors.base.ContentExtractorInterface.extract_text")
        mock_extractor = mock_extract_text.start()
        mock_extractor.return_value = ("Extracted content", None)
        mock_get_extractor.return_value.extract_text = mock_extractor
        
        yield mock_extractor
        
        mock_extract_text.stop()

def test_config_loading_from_env(temp_env_variables, mock_parse_report, mock_extractor):
    """Test loading API key from environment variables."""
    # Call the function
    augment_research_report("Test report", extractor_type="jina")
    
    # Check API key was passed correctly from environment variables
    _, kwargs = mock_extractor.call_args
    assert kwargs["api_key"] == "test-jina-api-key"

def test_config_loading_from_dotenv(mock_parse_report, mock_extractor):
    """Test loading API key from .env file."""
    # Create a clean environment without any API keys
    with patch.dict(os.environ, {}, clear=True):
        # Mock the load_dotenv function to set the environment variable
        with patch("main.load_dotenv") as mock_load_dotenv:
            def fake_load_dotenv():
                os.environ["JINA_API_KEY"] = "test-dotenv-jina-api-key"
                return True
            mock_load_dotenv.side_effect = fake_load_dotenv
            
            # Call the function
            augment_research_report("Test report", extractor_type="jina")
            
    # Check API key was loaded and passed correctly
    _, kwargs = mock_extractor.call_args
    assert kwargs["api_key"] == "test-dotenv-jina-api-key"

def test_config_loading_from_param(mock_parse_report, mock_extractor):
    """Test loading API key from the config parameter."""
    # Call the function with a config dictionary
    augment_research_report(
        "Test report", 
        extractor_type="jina",
        extractor_config={"api_key": "param-api-key"}
    )
    
    # Check API key was passed correctly from parameter
    _, kwargs = mock_extractor.call_args
    assert kwargs["api_key"] == "param-api-key"

def test_config_param_precedence(temp_env_variables, mock_parse_report, mock_extractor):
    """Test that config parameter takes precedence over environment variables."""
    # Call the function with both environment variables and config parameter
    augment_research_report(
        "Test report", 
        extractor_type="jina",
        extractor_config={"api_key": "param-api-key"}
    )
    
    # Check that parameter API key was used (not environment variable)
    _, kwargs = mock_extractor.call_args
    assert kwargs["api_key"] == "param-api-key"

def test_missing_api_key(mock_parse_report, mock_extractor):
    """Test behavior when API key is missing."""
    # Ensure environment is clean
    with patch.dict(os.environ, {}, clear=True):
        # Mock dotenv to not load anything
        with patch("main.load_dotenv"):
            augment_research_report("Test report", extractor_type="jina")
    
    # Check that None was passed as API key
    _, kwargs = mock_extractor.call_args
    assert kwargs["api_key"] is None

def test_extraction_mode_config(mock_parse_report, mock_extractor):
    """Test that extraction mode configuration is applied correctly."""
    # Define a mock for EXTRACTION_MODES
    mock_modes = {
        "test-mode": {
            "target_selector": "test-selector",
            "remove_selector": "test-remover"
        }
    }
    
    # Patch the EXTRACTION_MODES dictionary
    with patch("main.EXTRACTION_MODES", mock_modes):
        # Call with the test mode
        augment_research_report(
            "Test report", 
            extractor_type="jina",
            extraction_mode="test-mode"
        )
    
    # Check that target_selector and remove_selector were passed correctly
    _, kwargs = mock_extractor.call_args
    assert kwargs["target_selector"] == "test-selector"
    assert kwargs["remove_selector"] == "test-remover"

def test_extraction_mode_ignored_for_non_jina(mock_parse_report, mock_extractor):
    """Test that extraction mode is ignored for non-Jina extractors."""
    # Define a mock for EXTRACTION_MODES
    mock_modes = {
        "test-mode": {
            "target_selector": "test-selector",
            "remove_selector": "test-remover"
        }
    }
    
    # Patch the EXTRACTION_MODES dictionary
    with patch("main.EXTRACTION_MODES", mock_modes):
        # Call with a non-Jina extractor
        augment_research_report(
            "Test report", 
            extractor_type="local_bs4",
            extraction_mode="test-mode"
        )
    
    # Check that target_selector and remove_selector were not passed
    _, kwargs = mock_extractor.call_args
    assert "target_selector" not in kwargs or kwargs["target_selector"] is None
    assert "remove_selector" not in kwargs or kwargs["remove_selector"] is None 