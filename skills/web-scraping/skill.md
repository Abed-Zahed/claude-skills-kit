---
description: Semantic web search via Exa and JS-heavy page scraping via Firecrawl. Use proactively whenever research, current information, or URL content is needed.
---

# /web-scraping

## When to use
- Searching for current information, research papers, job postings, news
- Scraping a specific URL (LinkedIn, job boards, company sites, articles)
- Gathering structured data from one or many pages
- Any task where you'd normally say "I don't have current information on this"

## Exa vs Firecrawl — decision table

| Use Exa when... | Use Firecrawl when... |
|---|---|
| Finding relevant pages on a topic | You have a specific URL to scrape |
| Semantic/conceptual search ("best RF engineers") | The page is JS-rendered (React/Angular apps) |
| Discovering what exists across the web | You need clean structured data from a page |
| Research across many sources | Crawling multiple pages of one site |
| Finding people, companies, recent events | Extracting structured JSON from a page |

## Available tools

**Exa tools:**
- `web_search_exa` — semantic search, returns clean content ready to use
- `web_fetch_exa` — fetch full content of a known URL
- `web_search_advanced_exa` — filtered search (date range, domain, content type, category)

**Firecrawl tools:**
- `firecrawl_scrape` — extract clean content from a single URL (handles JS)
- `firecrawl_search` — web search with content extraction
- `firecrawl_crawl` — multi-page extraction from an entire site
- `firecrawl_extract` — structured LLM-powered data extraction from a URL
- `firecrawl_batch_scrape` — process multiple URLs efficiently
- `firecrawl_agent` — autonomous web research agent for complex tasks

## Workflow

1. **Discover** — use `web_search_exa` to find relevant pages semantically
2. **Fetch** — use `firecrawl_scrape` on specific URLs that need JS rendering or clean extraction
3. **Structure** — use `firecrawl_extract` if you need JSON output from a page
4. **Bulk** — use `firecrawl_batch_scrape` or `firecrawl_crawl` for multi-page tasks

## Examples

- "Find top fitness researchers last 3 years" → `web_search_advanced_exa` with date filter
- "Scrape this LinkedIn job posting [URL]" → `firecrawl_scrape`
- "Get all blog posts from firecrawl.dev" → `firecrawl_crawl`
- "Extract structured job data from this page" → `firecrawl_extract`
- "Who is writing about RF antenna design right now?" → `web_search_exa`
