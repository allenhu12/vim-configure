# Reference Augmentor

A tool to enhance research reports by automatically fetching content from URLs listed in their reference section, creating a consolidated document intended to serve as comprehensive contextual knowledge for Large Language Models (LLMs).

## Features

- Process plain text and Markdown formatted input reports
- Identify HTTP/HTTPS URLs in the reference section
- Extract content from referenced URLs using configurable extraction methods
- Append fetched content to the original report
- Support for multiple content extractors:
  - Jina AI Reader API
  - Firecrawl API
  - Local extraction using BeautifulSoup

## Installation

1. Clone the repository
2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
3. Set up API keys:
   - Copy `.env.example` to `.env`
   - Add your API keys to the `.env` file
   
## Usage

### As a Python Module

```python
from main import augment_research_report
import os

# Using default local BeautifulSoup extractor
result = augment_research_report(
    report_text="Your research report with references..."
)

# Using Jina AI extractor
result = augment_research_report(
    report_text="Your research report with references...",
    extractor_type="jina",
    extractor_config={"api_key": os.getenv("JINA_API_KEY")}
)
```

### Command Line

```bash
# Set API key in environment
export JINA_API_KEY=your_key_here

# Process a report using Jina AI extractor
python main.py report.txt --extractor jina --output augmented_report.txt

# Use local BeautifulSoup extractor (no API key needed)
python main.py report.txt --extractor local_bs4
```

## API Key Management

For extractors requiring API keys (Jina AI, Firecrawl), you have two options:

1. Set environment variables:
   ```bash
   export JINA_API_KEY=your_key_here
   export FIRECRAWL_API_KEY=your_key_here
   ```

2. Use a `.env` file in the project root (do not commit this file with real keys):
   ```
   JINA_API_KEY=your_key_here
   FIRECRAWL_API_KEY=your_key_here
   ```

Get your Jina AI API key for free: https://jina.ai/?sui=apikey

## Security Notice

- API keys should never be hardcoded in your application.
- Always use environment variables or `.env` files for sensitive configuration.
- Never commit `.env` files containing actual API keys to version control. 