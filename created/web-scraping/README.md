# web-scraping

A Claude Code skill that sends every research fetch through a free-first ladder, keeps a local cache of everything it reads, and reaches for paid tools only when the free path fails. An optional hook enforces a credit budget on Firecrawl and daily call caps on Gemini.

## What it does

- Checks `$RESEARCH_HOME/<sha256(url)[0:16]>/` before any fetch, where `RESEARCH_HOME` defaults to `~/research_cache`, so the same URL is never paid for twice. SHA-256 (Secure Hash Algorithm, 256 bit) gives the cache key.
- Routes discovery to WebSearch, ordinary pages to WebFetch, and PDF (Portable Document Format) files to `curl` plus pypdf, at zero cost.
- Uses Exa for semantic discovery, Gemini under daily caps, and Firecrawl only for JS-rendered (JavaScript) or bot-blocked pages, site maps, and budgeted interactive sessions.
- Never sends a PDF or document URL to Firecrawl, which bills per PDF page.
- Skips any rung whose tool is not installed, silently.

## Install

1. Copy the `web-scraping` folder into `~/.claude/skills/` (personal) or `.claude/skills/` (project).
2. Start a new Claude Code session so the skill is picked up.

The skill works on stock Claude Code with no MCP (Model Context Protocol) servers and no hooks. The paid rungs simply never appear.

### Optional: Firecrawl and Gemini budget gate hook

This hook is Windows only and runs under Windows PowerShell. Skip it on other platforms; the skill still works.

1. Copy `hooks/firecrawl_budget_gate.ps1` to `%USERPROFILE%\.claude\hooks\` (that is `$env:USERPROFILE\.claude\hooks\`).
2. Merge `hooks/settings-snippet.json` into `%USERPROFILE%\.claude\settings.json`. Keep any existing `hooks` entries and add this `PreToolUse` entry to the array. The file is JSON (JavaScript Object Notation).
3. Start a new Claude Code session. Hooks are read at session start.

State and log files are created on first use under `%USERPROFILE%\research_cache\_budget\` by default (or `$env:RESEARCH_HOME\_budget\` when `RESEARCH_HOME` is set), not next to the settings file. The default paths are:

- `%USERPROFILE%\research_cache\_budget\research_budget_state.json`, the budget ledger.
- `%USERPROFILE%\research_cache\_budget\research_tool_log.jsonl`, one JSON line per gated call, appended.

## Setup

Required: none. WebSearch and WebFetch are built in.

| Item | Required or optional | Install command and check |
|---|---|---|
| Exa MCP server | optional | Install it in Claude Code MCP settings, for example `claude mcp add exa -- <exa-server-command>`, then confirm a tool whose name starts with `mcp__exa__` or `mcp__claude_ai_Exa__` is available in this session. |
| Gemini MCP server | optional | `claude mcp add gemini -- <gemini-server-command>`, then confirm a tool whose name starts with `mcp__gemini__` is available in this session. |
| Firecrawl MCP server or claude.ai connector | optional | `claude mcp add firecrawl -- <firecrawl-server-command>`, or enable the Firecrawl connector in Claude settings, then confirm a tool whose name starts with `mcp__firecrawl__` or `mcp__claude_ai_Firecrawl__` is available in this session. |
| curl | optional | Install with Git for Windows or `winget install curl.curl`; check `curl --version`. |
| Python 3 with pypdf | optional | Install Python 3, then run `python -m pip install pypdf`; check `python -c "import pypdf"`. |
| Firecrawl budget hook | optional | Copy `hooks/firecrawl_budget_gate.ps1` to `~/.claude/hooks/`, merge `hooks/settings-snippet.json` into `~/.claude/settings.json`, restart Claude Code, then check `grep firecrawl_budget_gate ~/.claude/settings.json`. |
| RESEARCH_HOME environment variable | optional | Set `export RESEARCH_HOME="$HOME/research_cache"` in your shell profile if you want a non-default cache; check `printf '%s\n' "${RESEARCH_HOME:-$HOME/research_cache}"`. |

Run `/web-scraping setup` after installing to print a status for each item and write the marker file when all required items pass.

## How the budget gate decides

The hook runs before a tool call, reads the tool name and its input from standard input, and answers allow (no output) or deny (a JSON decision with a reason). It ignores any tool that does not match `mcp__(firecrawl|claude_ai_Firecrawl|gemini)__.*`. Both Firecrawl tool prefixes, the MCP server (`mcp__firecrawl__*`) and the claude.ai connector (`mcp__claude_ai_Firecrawl__*`), are gated.

1. Hard denies that need no state:
   - `pdfOptions` is set or a `pdf` parser is requested, because the cost cannot be sized before the call.
   - `firecrawl_crawl` has no `limit`.
   - Any URL ends in `.pdf`, `.ps`, `.djvu`, `.doc`, `.docx`, `.ppt`, `.pptx`, or `.epub`, in any position of a URL list.
2. Per-call estimate in credits:
   - scrape 1, plus 4 when a JSON schema is supplied.
   - search the requested limit, else 5.
   - map 1.
   - crawl the requested `limit`.
   - interact `max(4, minutes times rate)`, with 2 credits per minute code only and 7 with a prompt.
   - other Firecrawl tools a fixed policy charge.
3. Limits: the session cap is `min(base + 25 per grant, 150)` credits, and the day ceiling is 400 credits summed over every session. Gemini has a separate daily cap per bucket (deep research, search, URL reading, PDF reading, YouTube).
4. On a deny, the message names the free route to take instead. Every decision, allow or deny, is written to the log.

The hook fails open on any internal error or lock timeout, so research is never bricked, but the failure is logged.

## How to change the budget

- Base allowance: 60 credits for an interactive session, 25 when `RESEARCH_BUDGET_KEY` is set. Override per call with the `RESEARCH_BASE` environment variable.
- Hard ceilings: `$SessionCeiling` (150) and `$DayCeiling` (400) at the top of the script. Edit the script to change them.
- Softer ceilings: `session_ceiling` and `day_ceiling` in the state file. These can only lower the hard ceilings, never raise them.
- Grants: a job may request extra credits up to 3 times, 25 each. Edit `grants` for that session key in the state file by hand, after writing a justification line to the log. The script caps the usable count at 3.
- Gemini caps: edit `gemini_caps` in the state file, for example raise `deep-research` from 2 to 4.
- Reset: delete the state file. It is recreated on the next gated call.
- Log rotation: the log is rotated to a single `.old` file when it passes 2 megabytes (MB).
