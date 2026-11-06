---
name: web-scraping
description: "Research tool router for web fetches. Checks a local cache first, then uses free tools (WebSearch, WebFetch, curl plus pypdf for PDFs), then optional paid tools (Exa, Gemini, Firecrawl) only when installed and inside budget. Use when a task needs current information, page content, or text from a PDF. Setup: none required; optional: Exa MCP server, Gemini MCP server, Firecrawl MCP server or claude.ai connector, curl, Python 3 with pypdf, Firecrawl budget hook, RESEARCH_HOME env var. Run /web-scraping setup after installing."
---

# /web-scraping

## Setup check (first run)
When it runs: when the user types `/web-scraping setup`, or before the first real run when `.setup_ok` in this skill's own folder (the folder holding this SKILL.md) is absent. Required: none; WebSearch and WebFetch are built in.

| Item | Required or optional | How to check |
|---|---|---|
| Exa MCP server | optional | is a tool whose name starts with `mcp__exa__` or `mcp__claude_ai_Exa__` available in this session |
| Gemini MCP server | optional | is a tool whose name starts with `mcp__gemini__` available in this session |
| Firecrawl MCP server or claude.ai connector | optional | is a tool whose name starts with `mcp__firecrawl__` or `mcp__claude_ai_Firecrawl__` available in this session |
| curl | optional | `curl --version` |
| Python 3 with pypdf | optional | `python -c "import pypdf"` |
| Firecrawl budget hook | optional | `grep firecrawl_budget_gate ~/.claude/settings.json` |
| RESEARCH_HOME env var | optional | `printf '%s\n' "${RESEARCH_HOME:-$HOME/research_cache}"` |

Print OK/MISSING per item. If a required item is missing, stop before the task, explain its purpose in one line, and offer step-by-step setup, asking before installing, editing settings.json, or creating files outside the skill folder. Never install silently. If only optional items are missing, say what is lost in one line and continue. When every required item passes, write today's date to the marker file and continue with the original request.

Free first, cache first, paid last. If a tool is not installed, skip that rung silently and continue down the ladder.

## Cache first

Before any fetch, look for `$RESEARCH_HOME/<sha256(url)[0:16]>/` (default `$HOME/research_cache/<sha256(url)[0:16]>/`). If `text.txt` is there and fresh, read it and cite it. Never re-fetch a cached URL. Freshness by kind: standards and papers 180 days, ordinary pages 14 days, news or dated paths 3 days.

```bash
RESEARCH_HOME="${RESEARCH_HOME:-$HOME/research_cache}"
H=$(printf '%s' "$URL" | sha256sum | cut -c1-16)
D="$RESEARCH_HOME/$H"; mkdir -p "$D"
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
command -v cygpath >/dev/null && D=$(cygpath -m "$D")
python -c "
import sys, pypdf
r = pypdf.PdfReader(sys.argv[1])
with open(sys.argv[2], 'w', encoding='utf-8') as f:
    for i, p in enumerate(r.pages, 1):
        f.write(f'\n===== PAGE {i} =====\n' + (p.extract_text() or ''))
print(len(r.pages), 'pages')" "$D/doc.pdf" "$D/text.txt"
grep -n -i -C3 "keyword" "$D/text.txt" | head -60
```

If curl returns HTML or a 403, call `WebFetch` on the URL, then `web_fetch_exa`. If curl, python, or pypdf is missing, say so and stop. Do not fall back to Firecrawl for a PDF. Cite as `source p.NN`. pypdf can garble smart quotes; open the cached PDF when a number is load-bearing.

## Budget gate

A PreToolUse hook may be installed at `~/.claude/hooks/firecrawl_budget_gate.ps1`. When it denies a call, take the free route named in the message. Do not look for a workaround and do not edit the budget state file under `$RESEARCH_HOME/_budget` (default `$HOME/research_cache/_budget`).

## Tools

- Exa: `web_search_exa`, `web_fetch_exa`
- Gemini (daily caps): `gemini-search`, `gemini-analyze-url`, `gemini-extract-from-url`, `gemini-summarize-pdf`, `gemini-analyze-document`, `gemini-youtube`, `gemini-deep-research`
- Firecrawl (budgeted): `firecrawl_scrape`, `firecrawl_search`, `firecrawl_map`, `firecrawl_crawl` (needs a `limit`), `firecrawl_interact`
