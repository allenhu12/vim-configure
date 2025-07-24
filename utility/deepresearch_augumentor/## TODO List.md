## TODO List

- [ ] **Asynchronous Fetching:** For performance with many links (`asyncio`, `aiohttp`).
- [ ] **Advanced Local Content Extraction:** Integrate more sophisticated local libraries like `trafilatura` or `readability-lxml` into a new `AdvancedLocalExtractor`.
- [ ] **Content Caching:** Implement caching for fetched content to avoid re-fetching.
- [ ] **More Granular Configuration:** Allow passing specific parameters to extractors (e.g., Jina's `target_selector`, Firecrawl's `pageOptions`).
- [ ] **Support for Other Input Formats:** (e.g., parsing URLs from PDFs - significantly more complex).
- [ ] **GUI:** A simple web interface (e.g., using Flask/Streamlit) for ease of use by non-developers.