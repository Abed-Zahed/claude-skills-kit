# web-scraping tutorial
This skill fetches web pages and PDFs (Portable Document Format) for research, using a local cache and free tools first.

## Step 1: What it does
- Checks a local cache before fetching, so the same URL is never downloaded twice.
- Uses free tools first: WebSearch, WebFetch, and curl with pypdf for PDFs.
- Uses paid tools (Exa, Gemini, Firecrawl) only if installed and inside budget.

Claude: pause here and ask if the user is ready for the next step.

## Step 2: Try it
Run the setup check first, it needs nothing installed:

`/web-scraping setup`

Then ask a real question with made-up input:

`/web-scraping find the release date of Python 3.12 from python.org`

Any cache files go under `$HOME/research_cache/` by default. Nothing is written outside it unless a PDF is fetched.

Claude: pause here and ask if the user is ready for the next step.

## Step 3: Read the output
- Setup prints OK or MISSING per item. Optional items missing only cost you a paid shortcut, not the task.
- The answer shows which source it used. A cache hit means no fetch happened.
- PDF quotes are cited as `source p.NN` (page number). Verify tables and equations yourself.

Claude: pause here and ask if the user is ready for the next step.

## Step 4: Use it on your own work
- `/web-scraping summarize this standards PDF: <url>`
- `/web-scraping find three recent articles about <topic> and note their dates`
- `/web-scraping map this docs site and scrape the install page: <url>`

Claude: pause here and ask if the user is ready for the next step.

## Step 5: Common mistakes
- Expecting Firecrawl on a PDF. It is never used for PDFs, use the curl and pypdf route.
- Re-running a fetch that is already cached. The cache is checked first, and stale entries expire by content kind.
- Ignoring a budget denial. When the budget hook denies a call, take the free route it names, do not work around it.

Claude: pause here and ask if the user is ready for the next step.

## Step 6: Where to go next
Optional setup unlocks more:
- Exa or Gemini MCP (Model Context Protocol) server: semantic search and deep research.
- Firecrawl server or claude.ai connector: JS-rendered and bot-blocked pages.
- curl plus Python 3 with pypdf: the zero-cost PDF path.
- `RESEARCH_HOME` env var: move the cache elsewhere.

Run `/web-scraping setup` to check all of these.

Claude: pause here and ask if the user is ready for the next step.
