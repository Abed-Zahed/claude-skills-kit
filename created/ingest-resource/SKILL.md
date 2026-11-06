---
name: ingest-resource
description: "Save any article, link, transcript, PDF, or note to the right folder. Routes to knowledge/ (stable) or projects/ (active). Adds a structured summary block at the top and cross-links with [[wikilinks]]. Setup: none required; optional: none; it creates ~/.claude/knowledge/ and ~/.claude/projects/ on first save after asking. Run /ingest-resource setup after installing."
---

# /ingest-resource

## Tutorial mode

- Runs when the user types `/ingest-resource tutorial`, or asks to learn the skill.
- First run only: if `.tutorial_offered` does not exist in this skill folder, ask once "Want a short guided tutorial for /ingest-resource? (yes / no)" before the setup check, then create that file so it is never asked again.
- On yes: read `TUTORIAL.md` in this skill folder and walk the user through it one step at a time, waiting for them after each step. Then return to their original request, if any.

## Setup check (first run)

When it runs: when the user types `/ingest-resource setup`, or automatically before the first real run when the marker file `.setup_ok` in this skill's own folder (the folder holding this SKILL.md, user or project install) does not exist.

| Item | Required or optional | How to check |
|---|---|---|
| No required items | Required | none; continue |
| No optional items | Optional | none; continue |

Interactive rules: print the checklist with OK / MISSING per item. If a REQUIRED item is missing, stop before doing the task, explain what it is for in one line, and offer to set it up now, step by step, asking the user before installing anything, editing settings.json, or creating files outside the skill folder. Never install silently. If only OPTIONAL items are missing, say in one line what is lost and continue.

When every required item passes, write the marker file with today's date, then continue with the user's original request (if any).

## When to use
Any time external content should be saved for future reference:
- Articles, blog posts, research papers, documentation
- YouTube links or video transcripts
- PDFs or pasted documents
- Notes, ideas, raw data
- Results from /web-scraping

## Routing decision

| Save to `knowledge/` | Save to `projects/` |
|---|---|
| Stable frameworks, methodologies | Active project deliverables |
| Reference material (voice, brand, audience) | Launch plans, campaign briefs |
| Research papers, evergreen content | Newsletters, videos in production |
| People profiles (advisors, experts) | Time-sensitive work in progress |
| Processes and how-tos | Meeting notes, decision logs |

Ask if the classification is unclear.

## Steps

1. **Fetch content**, use `/web-scraping` if a URL; read if a file; accept if pasted
2. **Classify**, knowledge/ or projects/? (see table above)
3. **Generate the summary block** and place it at the very top of the file:

```markdown
---
source: [URL or "direct input" or "pasted text"]
date: [YYYY-MM-DD]
key_people: [comma-separated names mentioned]
key_concepts: [3-5 main ideas, comma-separated]
related: [[concept-1]], [[person-1]], [[project-1]]
---

## Summary
[3-5 sentence summary of what this is and why it matters]
```

4. **Add [[wikilinks]]** on first mention of any person, concept, or project that has an existing note
5. **Create folder** if it doesn't exist (no error, just create it)
6. **Save** to the correct path:
   - `~/.claude/knowledge/<topic>/<YYYY-MM-DD-title>.md`
   - `~/.claude/projects/<project-name>/<YYYY-MM-DD-title>.md`

## Naming conventions
- Folder: kebab-case topic (`rf-engineering`, `job-hunting`, `side-business`, `fitness`)
- File: date-prefixed kebab-case (`2026-06-18-exa-ai-overview.md`)

## After saving
- Report: saved path, classification decision, key concepts extracted, and any [[wikilinks]] created
- Suggest 1-2 related existing notes to cross-link if found
