"""
System tests for the debug wrapper functionality
"""
import os
import sys
import tempfile
import json
import pytest
from unittest.mock import patch, MagicMock
import importlib.util
from io import StringIO

# Path to the sample report file
SAMPLE_REPORT = os.path.join(os.path.dirname(__file__), "test_data", "sample_report.txt")

# Import debug_wrapper module
try:
    import debug_wrapper
except ImportError:
    pytest.skip("debug_wrapper module not available", allow_module_level=True)

@pytest.fixture
def mock_open_file():
    """Mock the open function for file operations."""
    with patch("builtins.open", create=True) as mock_open:
        # Configure mock for different files
        def side_effect(file, mode='r', *args, **kwargs):
            if file == SAMPLE_REPORT:
                # Return sample report content
                mock_file = StringIO("Test Research Report\n================\n\nReferences\n---------\nhttps://example.com/article1")
                mock_file.close = lambda: None
                return mock_file
            else:
                # For other files (like output), return a regular mock
                mock_file = MagicMock()
                mock_file.__enter__.return_value = mock_file
                return mock_file
                
        mock_open.side_effect = side_effect
        yield mock_open

def test_debug_wrapper_basic_cli():
    """Test the debug wrapper CLI argument parsing."""
    # We'll mock the run_with_debug function to avoid actual execution
    # and focus on CLI argument parsing
    with patch("debug_wrapper.run_with_debug") as mock_run:
        # Configure the mock to return a successful result
        debug_dir = "debug/test_dir"
        mock_run.return_value = ("MOCKED RESULT", debug_dir)
        
        # Test with basic arguments
        with patch("sys.argv", ["debug_wrapper.py", SAMPLE_REPORT]):
            # Ensure no exceptions are raised
            try:
                debug_wrapper.main()
            except Exception as e:
                pytest.fail(f"Debug wrapper CLI raised an exception: {e}")
        
        # Check run_with_debug was called with correct base parameters
        mock_run.assert_called_once()
        assert mock_run.call_args[0][0] == SAMPLE_REPORT  # Input file

def test_debug_wrapper_cli_with_extractor():
    """Test debug wrapper CLI with --extractor argument."""
    with patch("debug_wrapper.run_with_debug") as mock_run:
        debug_dir = "debug/test_dir"
        mock_run.return_value = ("MOCKED RESULT", debug_dir)
        
        # Test with jina extractor
        with patch("sys.argv", ["debug_wrapper.py", SAMPLE_REPORT, "--extractor", "jina"]):
            debug_wrapper.main()
        
        # Verify run_with_debug was called with jina extractor
        assert mock_run.call_args[0][1] == "jina"  # extractor_type is the second positional arg

def test_debug_wrapper_cli_with_output():
    """Test debug wrapper CLI with --output argument."""
    with patch("debug_wrapper.run_with_debug") as mock_run:
        debug_dir = "debug/test_dir"
        mock_run.return_value = ("MOCKED RESULT", debug_dir)
        
        # Test with output file
        output_file = "test_output.txt"
        with patch("sys.argv", ["debug_wrapper.py", SAMPLE_REPORT, "--output", output_file]):
            debug_wrapper.main()
        
        # Verify run_with_debug was called with output file
        assert mock_run.call_args[0][2] == output_file  # output_file is the third positional arg

def test_debug_wrapper_cli_with_timeout():
    """Test debug wrapper CLI with --timeout argument."""
    with patch("debug_wrapper.run_with_debug") as mock_run:
        debug_dir = "debug/test_dir"
        mock_run.return_value = ("MOCKED RESULT", debug_dir)
        
        # Test with custom timeout
        with patch("sys.argv", ["debug_wrapper.py", SAMPLE_REPORT, "--timeout", "30"]):
            debug_wrapper.main()
        
        # Verify run_with_debug was called with custom timeout
        assert mock_run.call_args[0][3] == 30  # timeout is the fourth positional arg

def test_debug_wrapper_cli_with_mode():
    """Test debug wrapper CLI with --mode argument."""
    with patch("debug_wrapper.run_with_debug") as mock_run:
        debug_dir = "debug/test_dir"
        mock_run.return_value = ("MOCKED RESULT", debug_dir)
        
        # Test with article mode
        with patch("sys.argv", ["debug_wrapper.py", SAMPLE_REPORT, "--mode", "article"]):
            debug_wrapper.main()
        
        # Verify run_with_debug was called with article mode
        assert mock_run.call_args[0][4] == "article"  # extraction_mode is the fifth positional arg

def test_debug_wrapper_cli_with_multiple_options():
    """Test debug wrapper CLI with multiple options."""
    with patch("debug_wrapper.run_with_debug") as mock_run:
        debug_dir = "debug/test_dir"
        mock_run.return_value = ("MOCKED RESULT", debug_dir)
        
        # Test with multiple options
        output_file = "test_output.txt"
        with patch("sys.argv", ["debug_wrapper.py", SAMPLE_REPORT, 
                              "--extractor", "jina",
                              "--mode", "article",
                              "--timeout", "30",
                              "--output", output_file]):
            debug_wrapper.main()
        
        # Verify run_with_debug was called with all options
        args = mock_run.call_args[0]
        assert args[0] == SAMPLE_REPORT  # input_file
        assert args[1] == "jina"  # extractor_type
        assert args[2] == output_file  # output_file
        assert args[3] == 30  # timeout
        assert args[4] == "article"  # extraction_mode

def test_debug_wrapper_cli_missing_file():
    """Test debug wrapper CLI with missing input file."""
    # Test with no input file
    with patch("sys.argv", ["debug_wrapper.py"]):
        with pytest.raises(SystemExit) as exc_info:
            debug_wrapper.main()
    
    # Verify exit code is non-zero
    assert exc_info.value.code != 0 