"""
Comprehensive tests for error conditions in the Reference Augmentor system.

This test suite focuses on how the system handles various error conditions:
1. Network issues (timeouts, connection errors, DNS failures)
2. API authentication problems (invalid/expired keys)
3. API service limits (rate limiting, quota exhaustion)
4. Malformed API responses
5. Very slow responses
"""

import os
import pytest
import requests
import json
from unittest.mock import patch, MagicMock
import time

from extractors.jina_extractor import JinaAIExtractor
from extractors.firecrawl_extractor import FirecrawlExtractor
from main import augment_research_report

# Sample test data
TEST_URL = "https://example.com/test-article"
SAMPLE_REPORT = """Test Report

This is a test report with a reference.

References
----------
https://example.com/test-article
"""

class MockResponse:
    """Mock HTTP response with configurable attributes"""
    def __init__(self, status_code, json_data=None, text="", raise_for_status=None):
        self.status_code = status_code
        self._json_data = json_data
        self.text = text
        self.raise_for_status_mock = raise_for_status
        self.elapsed = MagicMock()
        self.elapsed.total_seconds.return_value = 0.1
        
    def json(self):
        if self._json_data is None:
            raise ValueError("No JSON data available")
        return self._json_data
        
    def raise_for_status(self):
        if self.raise_for_status_mock:
            raise self.raise_for_status_mock()


class TestNetworkErrors:
    """Test how the system handles network-related errors"""
    
    @patch('requests.post')
    def test_connection_timeout(self, mock_post):
        """Test that connection timeouts are properly handled"""
        # Configure mock to raise timeout exception
        mock_post.side_effect = requests.exceptions.ConnectTimeout("Connection timed out")
        
        # Test with Jina extractor
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "Connection timed out" in error
    
    @patch('requests.post')
    def test_connection_error(self, mock_post):
        """Test that connection errors are properly handled"""
        # Configure mock to raise connection error
        mock_post.side_effect = requests.exceptions.ConnectionError("Failed to establish connection")
        
        # Test with Jina extractor
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "connection" in error.lower()
    
    @patch('requests.post')
    def test_dns_failure(self, mock_post):
        """Test that DNS resolution failures are properly handled"""
        # Configure mock to raise DNS resolution error
        mock_post.side_effect = requests.exceptions.ConnectionError("Name or service not known")
        
        # Test with Firecrawl extractor
        firecrawl_extractor = FirecrawlExtractor()
        result, error = firecrawl_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "Name or service not known" in error or "connection" in error.lower()


class TestAPIErrors:
    """Test how the system handles API-specific errors"""
    
    @patch('requests.post')
    def test_invalid_api_key(self, mock_post):
        """Test that invalid API keys are properly handled"""
        # Configure mock to return unauthorized response
        mock_response = MockResponse(
            status_code=401,
            json_data={"error": "Invalid API key", "status": "unauthorized"},
            text="Unauthorized"
        )
        mock_post.return_value = mock_response
        
        # Test with Jina extractor
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "invalid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "API" in error and "key" in error.lower() or "unauthorized" in error.lower() or "401" in error
    
    @patch('requests.post')
    def test_rate_limit_exceeded(self, mock_post):
        """Test that rate limit errors are properly handled"""
        # Configure mock to return rate limit response
        mock_response = MockResponse(
            status_code=429,
            json_data={"error": "Rate limit exceeded", "status": "too_many_requests"},
            text="Too Many Requests"
        )
        mock_post.return_value = mock_response
        
        # Test with Jina extractor
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "rate limit" in error.lower() or "429" in error or "too many requests" in error.lower()
    
    @patch('requests.post')
    def test_quota_exceeded(self, mock_post):
        """Test that quota exhaustion errors are properly handled"""
        # Configure mock to return quota exceeded response
        mock_response = MockResponse(
            status_code=403,
            json_data={"error": "Quota exceeded", "status": "forbidden"},
            text="Forbidden - Quota exceeded"
        )
        mock_post.return_value = mock_response
        
        # Test with Firecrawl extractor
        firecrawl_extractor = FirecrawlExtractor()
        result, error = firecrawl_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "quota" in error.lower() or "403" in error or "forbidden" in error.lower()
    
    @patch('requests.post')
    def test_server_error(self, mock_post):
        """Test that server errors are properly handled"""
        # Configure mock to return server error
        mock_response = MockResponse(
            status_code=500,
            json_data={"error": "Internal server error"},
            text="Internal Server Error"
        )
        mock_post.return_value = mock_response
        
        # Test with Jina extractor
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "server error" in error.lower() or "500" in error


class TestMalformedResponses:
    """Test how the system handles malformed API responses"""
    
    @patch('requests.post')
    def test_invalid_json_response(self, mock_post):
        """Test handling of invalid JSON responses"""
        # Configure mock to return valid status but invalid JSON
        mock_response = MockResponse(
            status_code=200,
            text="This is not valid JSON",
        )
        # Make the json method raise an exception
        mock_response.json = MagicMock(side_effect=json.JSONDecodeError("Invalid JSON", "", 0))
        mock_post.return_value = mock_response
        
        # Test with Jina extractor
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "json" in error.lower() or "parse" in error.lower() or "decode" in error.lower()
    
    @patch('requests.post')
    def test_missing_data_in_response(self, mock_post):
        """Test handling of responses missing expected data fields"""
        # Configure mock to return valid status but missing expected fields
        mock_response = MockResponse(
            status_code=200,
            json_data={"status": "success", "meta": {"request_id": "123"}},
            # No 'data' field with content
        )
        mock_post.return_value = mock_response
        
        # Test with Jina extractor
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key")
        
        # Verify we get the expected error response
        assert result is None
        assert "response format error" in error.lower() or "missing" in error.lower() or "not found" in error.lower() or "schema" in error.lower() or "invalid" in error.lower()


class TestTimeoutScenarios:
    """Test how the system handles various timeout scenarios"""
    
    @patch('requests.post')
    def test_request_exceeds_timeout(self, mock_post):
        """Test that requests exceeding timeout are properly handled"""
        # Configure mock to raise timeout exception
        mock_post.side_effect = requests.exceptions.ReadTimeout("Request timed out")
        
        # Test with Jina extractor with very short timeout
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key", timeout=1)
        
        # Verify we get the expected error response
        assert result is None
        assert "timed out" in error.lower() or "timeout" in error.lower()
    
    @patch('requests.post')
    def test_slow_but_successful_response(self, mock_post):
        """Test handling of slow but eventually successful responses"""
        # Configure mock to simulate a slow but successful response
        def slow_response(*args, **kwargs):
            # Check if there's a timeout arg and ensure we delay less than that
            timeout = kwargs.get('timeout', 10)
            delay = timeout * 0.8  # 80% of timeout
            time.sleep(delay)
            return MockResponse(
                status_code=200,
                json_data={"code": 200, "data": {"content": "This is the content of the page"}}
            )
        
        mock_post.side_effect = slow_response
        
        # Test with Jina extractor with a 5 second timeout
        jina_extractor = JinaAIExtractor()
        result, error = jina_extractor.extract_text(TEST_URL, "valid_key", timeout=5)
        
        # Verify we got a successful response despite it being slow
        assert result is not None
        assert error is None
        assert "content" in result


class TestEndToEndErrorHandling:
    """Test how errors are handled in the end-to-end research report augmentation process"""
    
    @patch('extractors.jina_extractor.JinaAIExtractor.extract_text')
    def test_extraction_error_in_augmentation(self, mock_extract):
        """Test that extraction errors are properly handled in the main augmentation function"""
        # Configure the mock to return an error for any URL
        mock_extract.return_value = (None, "API error: Service unavailable")
        
        # Perform augmentation
        result = augment_research_report(
            report_text=SAMPLE_REPORT,
            extractor_type="jina",
            extraction_mode="default"
        )
        
        # Verify error is properly formatted in the output
        assert "REFERENCE CONTENT APPENDIX" in result
        assert "BEGIN SOURCE: https://example.com/test-article" in result
        assert "Content extraction failed" in result
        assert "API error: Service unavailable" in result
    
    @patch('extractors.jina_extractor.JinaAIExtractor.extract_text')
    def test_mixed_success_and_failure(self, mock_extract):
        """Test handling of mixed successful and failed extractions"""
        # Prepare a report with multiple references
        multi_ref_report = """Test Report

This is a test report with multiple references.

References
----------
https://example.com/success-article
https://example.com/error-article
"""
        
        # Configure the mock to return success for one URL and error for another
        def mock_extract_impl(url, *args, **kwargs):
            if "success" in url:
                return ("Successful content extraction", None)
            else:
                return (None, "API error: Not found")
        
        mock_extract.side_effect = mock_extract_impl
        
        # Perform augmentation
        result = augment_research_report(
            report_text=multi_ref_report,
            extractor_type="jina",
            extraction_mode="default"
        )
        
        # Verify both success and error cases are properly handled
        assert "REFERENCE CONTENT APPENDIX" in result
        assert "BEGIN SOURCE: https://example.com/success-article" in result
        assert "Successful content extraction" in result
        assert "BEGIN SOURCE: https://example.com/error-article" in result
        assert "Content extraction failed" in result
        assert "API error: Not found" in result 