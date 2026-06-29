---
description: Save any article, link, transcript, PDF, or note to the right folder. Routes to knowledge/ (stable) or projects/ (active). Adds a structured summary block at the top and cross-links with [[wikilinks]].
---

# /ingest-resource

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

1. **Fetch content** — use `/web-scraping` if a URL; read if a file; accept if pasted
2. **Classify** — knowledge/ or projects/? (see table above)
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
5. **Create folder** if it doesn't exist (no error — just create it)
6. **Save** to the correct path:
   - `C:\Users\Administrator\.claude\knowledge\<topic>\<YYYY-MM-DD-title>.md`
   - `C:\Users\Administrator\.claude\projects\<project-name>\<YYYY-MM-DD-title>.md`

## Naming conventions
- Folder: kebab-case topic (`rf-engineering`, `job-hunting`, `azure-chocolates`, `fitness`)
- File: date-prefixed kebab-case (`2026-06-18-exa-ai-overview.md`)

## After saving
- Report: saved path, classification decision, key concepts extracted, and any [[wikilinks]] created
- Suggest 1-2 related existing notes to cross-link if found
