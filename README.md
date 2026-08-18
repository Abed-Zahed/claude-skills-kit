# Claude Skills Kit

A set of 8 Claude Code skills covering engineering, research, and
decision-making workflows. Each skill is useful on its own. Seven of them
are zero-config and portable, the eighth (`/video-review`) is included as a
worked example of a more involved, personal-infrastructure-dependent skill,
see its own note below before expecting it to run as-is.

## Skills included

| Skill | What it does |
|---|---|
| `/polish-prompt` | Rewrites vague prompts into specific, actionable requests. Routes to the right skill automatically. Auto-executes if single clean output. |
| `/modern-engineer` | 5-phase engineering workflow: brainstorm → plan → work → review → debug. Never skips to code without interviewing first. |
| `/web-scraping` | Semantic search (Exa) and JS-heavy page scraping (Firecrawl). Use for any research or URL fetch task. |
| `/ingest-resource` | Saves articles, links, PDFs, transcripts, and notes into structured knowledge/ or projects/ folders. |
| `/improve-system` | 5-mode process review: audit, skill-review, experience, historical-review, foundation. |
| `/ask-the-board` | Advisory board simulator. Recommend 2 expert advisors for any context, then consult them on decisions in their own voice. |
| `/internal-focus-group` | Multi-agent panel of real people (built from ingested notes). Each person responds in character. Results synthesized into one report. |
| `/video-review` | Batch-reviews social video links against per-link instructions: fetch/transcribe, verify, conditional ticket, one consolidated report. **Personal, not zero-config**, see [`skills/video-review/README.md`](skills/video-review/README.md) for the three hardcoded dependencies and how to adapt them. |

## The linchpin: /polish-prompt

`/polish-prompt` is the skill that ties the kit together. It:
- Detects vague or scoped-out prompts before they reach the model
- Routes to the right skill automatically (e.g. routes "build X" to `/modern-engineer`)
- Auto-executes single clean prompts instead of showing them to you
- Splits multi-task prompts and hands them back for sequential sending

A `UserPromptSubmit` hook is also included to nudge you on short/vague prompts without breaking flow.

## Installation

### Option A — Install all skills at once

Copy the `skills/` folder into your Claude Code skills directory:

```bash
# macOS / Linux
cp -r skills/* ~/.claude/skills/

# Windows (PowerShell)
Copy-Item -Recurse skills\* "$env:USERPROFILE\.claude\skills\"
```

### Option B — Install one skill

Copy the individual skill folder:

```bash
cp -r skills/polish-prompt ~/.claude/skills/
```

### Option C — Install the UserPromptSubmit hook (optional, recommended)

Add the hook from `settings-hook-example.json` to your `~/.claude/settings.json`. It fires on every prompt and injects a nudge when your prompt is short or vague. Bypass it with `*` or `#` as the first character.

## Bypass prefixes (polish-prompt + hook)

| Prefix | Effect |
|---|---|
| `*` | Skip polishing — prompt is already specific |
| `#` | Skip — debugging session, preserve raw prompt |

## Requirements

- Claude Code (any version)
- `/web-scraping` requires Exa and Firecrawl MCP tools configured
- `/internal-focus-group` requires member profiles saved via `/ingest-resource`
- `/video-review` requires the personal infrastructure described in
  [`skills/video-review/README.md`](skills/video-review/README.md) (an
  Ollama Cloud batch-delegation setup, a video transcription tool, and an
  issue tracker integration), none of which is included in this kit

## Attribution

Hook architecture inspired by [claude-code-prompt-improver](https://github.com/severity1/claude-code-prompt-improver) (MIT License).

## License

MIT
