---
name: web-scraping
description: Research tool router for web fetches. Checks a local cache first, then uses free tools (WebSearch, WebFetch, curl plus pypdf for PDFs), then optional paid tools (Exa, Gemini, Firecrawl) only when installed and inside budget. Use when a task needs current information, page content, or text from a PDF.
---

# /web-scraping

Free first, cache first, paid last. If a tool is not installed, skip that rung silently and continue down the ladder.

## Cache first

Before any fetch, look for `~/.claude/research_cache/<sha256(url)[0:16]>/`. If `text.txt` is there and fresh, read it and cite it. Never re-fetch a cached URL. Freshness by kind: standards and papers 180 days, ordinary pages 14 days, news or dated paths 3 days.

```bash
H=$(printf '%s' "$URL" | sha256sum | cut -c1-16)
D="$HOME/.claude/research_cache/$H"; mkdir -p "$D"
printf '%s\n' "$URL" > "$D/url.txt"
```

## Routing

| Need | First choice | Only if installed and budgeted | Never |
|---|---|---|---|
| Find sources | `WebSearch` | `web_search_exa` (semantic) | `firecrawl_search` as the opener |
| Read a normal page | `WebFetch` | `web_fetch_exa` | `firecrawl_scrape` before the free path failed |
| Read a PDF | `curl` into the cache, extract with pypdf | `web_fetch_exa` | `firecrawl_scrape` on a `.pdf`, ever |
| JS-rendered or bot-blocked page | `WebFetch` | `firecrawl_scrape` | `firecrawl_agent` for one page |
| Logged-in or interactive flow | Ask the user for the content | `firecrawl_interact` | unattended interact |
| Site crawl | `firecrawl_map` for the URL list, then scrape only what you need | `firecrawl_crawl` with a `limit` | crawl with no limit |
| Deep multi-source synthesis | `WebSearch` plus cached reads | `gemini-deep-research` | `firecrawl_agent` |
| YouTube | `gemini-youtube` | `gemini-youtube-summary` | Firecrawl on a video URL |

## PDF recipe

Zero cost, and it produced text comparable to a paid scrape in one test on a long standards document. Tables and equations are unvalidated, so verify before citing.

```bash
[ -f "$D/doc.pdf" ] || curl -sL --max-time 120 -A "Mozilla/5.0" -o "$D/doc.pdf" "$URL"
python -c "
import pypdf
r = pypdf.PdfReader(r'$D/doc.pdf')
with open(r'$D/text.txt', 'w', encoding='utf-8') as f:
    for i, p in enumerate(r.pages, 1):
        f.write(f'\n===== PAGE {i} =====\n' + (p.extract_text() or ''))
print(len(r.pages), 'pages')"
grep -n -i -C3 "keyword" "$D/text.txt" | head -60
```

If curl returns HTML or a 403, call `WebFetch` on the URL, then `web_fetch_exa`. If curl, python, or pypdf is missing, say so and stop. Do not fall back to Firecrawl for a PDF. Cite as `source p.NN`. pypdf can garble smart quotes; open the cached PDF when a number is load-bearing.

## Budget gate

A PreToolUse hook may be installed at `~/.claude/hooks/firecrawl_budget_gate.ps1`. When it denies a call, take the free route named in the message. Do not look for a workaround and do not edit the budget state file.

## Tools

- Exa: `web_search_exa`, `web_fetch_exa`
- Gemini (daily caps): `gemini-search`, `gemini-analyze-url`, `gemini-extract-from-url`, `gemini-summarize-pdf`, `gemini-analyze-document`, `gemini-youtube`, `gemini-deep-research`
- Firecrawl (budgeted): `firecrawl_scrape`, `firecrawl_search`, `firecrawl_map`, `firecrawl_crawl` (needs a `limit`), `firecrawl_interact`
