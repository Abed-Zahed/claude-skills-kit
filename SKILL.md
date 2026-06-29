---
name: claude-skills-kit
description: A complete Claude Code skill kit — prompt polishing with auto-routing, 5-phase engineering workflow, web research, knowledge ingestion, advisory board simulation, and multi-agent focus group. Skills work standalone or as an integrated system.
---

# Claude Skills Kit

Seven interconnected Claude Code skills that form a complete workflow system.

## Skills in this kit

- `/polish-prompt` — rewrites vague prompts, routes to the right skill, auto-executes clean outputs
- `/modern-engineer` — 5-phase build workflow (brainstorm → plan → work → review → debug)
- `/web-scraping` — semantic search via Exa + JS scraping via Firecrawl
- `/ingest-resource` — saves any resource to structured knowledge/ or projects/ folders
- `/improve-system` — 5-mode process review skill
- `/ask-the-board` — advisory board simulator with advisor research and consult modes
- `/internal-focus-group` — multi-agent panel from ingested people profiles

## Install all skills

```bash
# macOS / Linux
cp -r skills/* ~/.claude/skills/

# Windows
Copy-Item -Recurse skills\* "$env:USERPROFILE\.claude\skills\"
```

See README.md for individual skill setup and the optional UserPromptSubmit hook.
