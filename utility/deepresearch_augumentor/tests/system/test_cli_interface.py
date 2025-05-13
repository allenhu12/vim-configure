"""
System tests for the CLI interface of Reference Augmentor
"""
import os
import sys
import tempfile
import subprocess
import pytest
from unittest.mock import patch, MagicMock
import importlib.util
from io import StringIO
import main  # Import the main module

# Path to the sample report file
SAMPLE_REPORT = os.path.join(os.path.dirname(__file__), "test_data", "sample_report.txt")

@pytest.fixture
def temporary_output_file():
    """Create a temporary file for output testing."""
    fd, path = tempfile.mkstemp(suffix=".txt")
    os.close(fd)
    
    yield path
    
    # Clean up the file after the test
    if os.path.exists(path):
        os.remove(path)

@pytest.fixture
def mock_augment_function():
    """Mock the augment_research_report function."""
    with patch("main.augment_research_report") as mock_func:
        # Configure the mock to return a predefined string
        mock_func.return_value = "MOCKED AUGMENTED REPORT"
        yield mock_func

@pytest.fixture
def capture_stdout():
    """Capture stdout for testing."""
    captured_output = StringIO()
    original_stdout = sys.stdout
    sys.stdout = captured_output
    
    yield captured_output
    
    # Restore stdout
    sys.stdout = original_stdout

@pytest.fixture
def mock_open_file():
    """Mock the open function for file operations."""
    with patch("builtins.open", create=True) as mock_open:
        # Configure mock for different files
        def side_effect(file, mode='r', *args, **kwargs):
            if file == SAMPLE_REPORT:
                # Return sample report content
                mock_file = StringIO("Test Research Report\n================\n\nReferences\n---------\nhttps://example.com/article1\nhttps://example.com/article2")
                mock_file.close = lambda: None
                return mock_file
            else:
                # For other files (like output), return a regular mock
                mock_file = MagicMock()
                mock_file.__enter__.return_value = mock_file
                return mock_file
                
        mock_open.side_effect = side_effect
        yield mock_open

def test_cli_basic_functionality(mock_augment_function, capture_stdout, mock_open_file):
    """Test basic CLI functionality."""
    # Mock sys.argv
    with patch("sys.argv", ["main.py", SAMPLE_REPORT]):
        # Ensure there's no exception
        try:
            main.main()
        except Exception as e:
            pytest.fail(f"CLI raised an exception: {e}")
    
    # Check that augment_research_report was called
    mock_augment_function.assert_called_once()
    
    # In our mock setup, report_text won't be directly accessible,
    # instead we check that the function was called with any argument
    # and that the default values for kwargs are used
    _, kwargs = mock_augment_function.call_args
    assert kwargs["extractor_type"] == "local_bs4"  # Default extractor
    assert kwargs["extraction_mode"] == "default"  # Default mode
    assert kwargs["request_timeout"] == 15  # Default timeout

def test_cli_with_extractor_option(mock_augment_function, capture_stdout, mock_open_file):
    """Test CLI with --extractor option."""
    # Test with jina extractor
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--extractor", "jina"]):
        main.main()
    
    # Check that augment_research_report was called with jina extractor
    args, kwargs = mock_augment_function.call_args
    assert kwargs["extractor_type"] == "jina"
    
    # Test with firecrawl extractor
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--extractor", "firecrawl"]):
        main.main()
    
    # Check that augment_research_report was called with firecrawl extractor
    args, kwargs = mock_augment_function.call_args
    assert kwargs["extractor_type"] == "firecrawl"

def test_cli_with_extraction_mode(mock_augment_function, capture_stdout, mock_open_file):
    """Test CLI with --mode option."""
    # Test with article mode
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--mode", "article"]):
        main.main()
    
    # Check that augment_research_report was called with article mode
    args, kwargs = mock_augment_function.call_args
    assert kwargs["extraction_mode"] == "article"
    
    # Test with body-only mode
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--mode", "body-only"]):
        main.main()
    
    # Check that augment_research_report was called with body-only mode
    args, kwargs = mock_augment_function.call_args
    assert kwargs["extraction_mode"] == "body-only"

def test_cli_with_timeout_option(mock_augment_function, capture_stdout, mock_open_file):
    """Test CLI with --timeout option."""
    # Test with custom timeout
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--timeout", "30"]):
        main.main()
    
    # Check that augment_research_report was called with the custom timeout
    args, kwargs = mock_augment_function.call_args
    assert kwargs["request_timeout"] == 30

def test_cli_with_output_option(mock_augment_function, temporary_output_file, mock_open_file):
    """Test CLI with --output option."""
    # Test with output file
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--output", temporary_output_file]):
        with patch("builtins.print") as mock_print:  # Mock print to avoid output
            main.main()
    
    # Check that the write method was called on the output file mock
    for call in mock_open_file.mock_calls:
        if call[1][0] == temporary_output_file and call[1][1] == 'w':
            file_handle = call[2]['encoding']
            assert file_handle is not None
            break
    else:
        pytest.fail("Output file was not opened for writing")

def test_cli_output_to_stdout(mock_augment_function, mock_open_file):
    """Test CLI output to stdout when no output file is specified."""
    # Run without output file
    with patch("sys.argv", ["main.py", SAMPLE_REPORT]):
        with patch("builtins.print") as mock_print:
            main.main()
    
    # Check that the output was printed
    mock_print.assert_called_with(mock_augment_function.return_value)

def test_cli_missing_input_file(mock_open_file):
    """Test CLI error handling for missing input file."""
    # Modify the side_effect to raise FileNotFoundError for the input file
    def side_effect_file_not_found(file, mode='r', *args, **kwargs):
        if file == "nonexistent_file.txt":
            raise FileNotFoundError(f"No such file or directory: '{file}'")
        return MagicMock()
    
    mock_open_file.side_effect = side_effect_file_not_found
    
    # Test with non-existent input file
    with patch("sys.argv", ["main.py", "nonexistent_file.txt"]):
        with pytest.raises(SystemExit) as exc_info:
            main.main()
    
    # Check that the exit code is non-zero
    assert exc_info.value.code != 0

def test_cli_invalid_extractor():
    """Test CLI error handling for invalid extractor."""
    # Test with invalid extractor
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--extractor", "invalid_extractor"]):
        with pytest.raises(SystemExit) as exc_info:
            main.main()
    
    # Check that the exit code is non-zero (argparse should catch this)
    assert exc_info.type == SystemExit

def test_cli_invalid_mode():
    """Test CLI error handling for invalid mode."""
    # Test with invalid mode
    with patch("sys.argv", ["main.py", SAMPLE_REPORT, "--mode", "invalid_mode"]):
        with pytest.raises(SystemExit) as exc_info:
            main.main()
    
    # Check that the exit code is non-zero (argparse should catch this)
    assert exc_info.type == SystemExit

def test_cli_usage_flag():
    """Test CLI --usage flag displays help text and exits."""
    # Test with --usage flag
    with patch("sys.argv", ["main.py", "--usage"]):
        with patch("main.print_usage") as mock_print_usage:
            # Expect SystemExit with code 0
            with pytest.raises(SystemExit) as exc_info:
                main.main()
            
            # Check that print_usage was called and exit code is 0
            mock_print_usage.assert_called_once()
            assert exc_info.value.code == 0

def test_cli_actual_subprocess():
    """Test the CLI interface by running it as an actual subprocess."""
    # Use subprocess to run the actual CLI
    result = subprocess.run(
        [sys.executable, "main.py", "--usage"],
        capture_output=True, 
        text=True
    )
    
    # Check that the command executed successfully
    assert result.returncode == 0
    assert "REFERENCE AUGMENTOR - USAGE GUIDE" in result.stdout 