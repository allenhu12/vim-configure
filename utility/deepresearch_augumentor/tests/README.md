# Reference Augmentor Test Suite

This directory contains the test suite for the Reference Augmentor project, following the comprehensive test plan.

## Structure

- `conftest.py`: Common fixtures and utilities for all tests
- `unit/`: Unit tests for individual components
  - `test_parser.py`: Tests for the parse_report function
  - `test_formatter.py`: Tests for the format_output function
  - `test_extractor_factory.py`: Tests for the get_extractor function
  - `test_config_loading.py`: Tests for configuration and API key loading
  - `test_extractors/`: Tests for individual extractor implementations
    - `test_bs4_extractor.py`: Tests for BeautifulSoupExtractor
    - `test_jina_extractor.py`: Tests for JinaAIExtractor
    - `test_firecrawl_extractor.py`: Tests for FirecrawlExtractor
- `integration/`: Tests for interactions between components
- `system/`: End-to-end tests for the full application
- `test_data/`: Sample data for testing

## Running Tests

### Requirements

Make sure you have pytest installed:

```
pip install pytest pytest-mock requests-mock
```

### Running All Tests

```
pytest
```

### Running Specific Test Categories

Run unit tests only:
```
pytest tests/unit/
```

Run integration tests only:
```
pytest tests/integration/
```

Run system tests only:
```
pytest tests/system/
```

### Running a Specific Test File

```
pytest tests/unit/test_parser.py
```

### Running a Specific Test

```
pytest tests/unit/test_parser.py::test_parse_report_single_url
```

## Test Data

The tests use fixtures defined in `conftest.py` to provide sample data for testing. You can examine these fixtures to understand the test data structure.

## Adding Tests

When adding new tests:

1. Follow the existing patterns and naming conventions
2. Use appropriate fixtures from `conftest.py`
3. Mock external dependencies where appropriate
4. For API tests, use the provided mock responses

## Notes

- API keys for tests are mock values and won't work with real APIs
- Tests run with mocked HTTP requests to avoid actual external API calls
- If you need to test with real APIs, use the debug wrapper in the main application 