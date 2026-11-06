---
name: ask-the-board
description: "Advisory board skill. Two modes: recommend (suggest 2 expert advisors for a context) or consult (get each advisor's take on a decision in their own voice). Bias toward creators for consumer-product questions, senior professionals for career questions. Setup: none required; optional: /web-scraping and /ingest-resource for recommend mode (if missing, use built-in WebSearch and skip ingestion), and filling the \"User profile\" section in this SKILL.md with your own background (check: the section still contains the placeholder lines). Run /ask-the-board setup after installing."
---

# /ask-the-board

## Tutorial mode

- Runs when the user types `/ask-the-board tutorial`, or asks to learn the skill.
- First run only: if `.tutorial_offered` does not exist in this skill folder, ask once "Want a short guided tutorial for /ask-the-board? (yes / no)" before the setup check, then create that file so it is never asked again.
- On yes: read `TUTORIAL.md` in this skill folder and walk the user through it one step at a time, waiting for them after each step. Then return to their original request, if any.

## Setup check (first run)

When it runs: when the user types `/ask-the-board setup`, or automatically before the first real run when the marker file `.setup_ok` in this skill's own folder (the folder holding this SKILL.md, user or project install) does not exist.

| Item | Required or optional | How to check |
|---|---|---|
| No required items | Required | none; continue |
| User profile in this SKILL.md | Optional | `grep -n "Role and years of experience" <this skill folder>/SKILL.md` (placeholder present means MISSING) |

Interactive rules: print the checklist with OK / MISSING per item. If a REQUIRED item is missing, stop before doing the task, explain what it is for in one line, and offer to set it up now, step by step, asking the user before installing anything, editing settings.json, or creating files outside the skill folder. Never install silently. If only OPTIONAL items are missing, say in one line what is lost and continue.

When every required item passes, write the marker file with today's date, then continue with the user's original request (if any).

## Two modes

### Recommend mode
Triggered when: "who should be on my board for X?" or starting a new context without an existing board.

1. Use `/web-scraping` to research 3-5 candidates relevant to the situation. If `/web-scraping` is not installed, use built-in WebSearch instead.
2. Select 2 who best fit the user's specific context (see profile below)
3. For each advisor deliver:
   - **Who they are**, name, title, why they're relevant
   - **Their philosophy**, 2-3 sentences on their core worldview
   - **Best 5 pieces of content** to ingest via `/ingest-resource`. If `/ingest-resource` is not installed, skip ingestion.
4. Save the board to `~/.claude/knowledge/board/<topic>-board.md`

### Consult mode
Triggered when a decision or question is asked and a board exists for that context.

1. Read the saved board profiles from `~/.claude/knowledge/board/<topic>-board.md`
2. Write each advisor's response **in their own voice**, their actual style, not a generic answer
3. Advisors should disagree where they genuinely would
4. Synthesize at the end

---

## Context routing

| Context | Advisor bias |
|---|---|
| Consumer product / branding / social | Instagram/TikTok creators with product business experience |
| Job hunting / CV / career moves | Recruiters, hiring managers, career coaches, senior engineers |
| Tech / engineering / software projects | Technical founders, senior engineers, startup CTOs |
| General business / strategy | Mix of operator and marketer |
| Personal decision / life | Generalist thinkers, not domain-specific |

---

## User profile (always consider when recommending)
Edit this list once with your own background:
- Role and years of experience
- Location and citizenship (for job or market advice)
- Current goals (job search, side business, project)
- Values: direct, practical, no fluff

---

## Response format (consult mode)

```
**[Advisor Name], [Their title/platform]**
> "[Their honest take in their own voice and style]"

**[Advisor Name], [Their title/platform]**
> "[Their honest take in their own voice and style]"

---
[OK] **They agree on:** [what both say]
[NO] **They disagree on:** [where they split and why]
-> **What you should actually do:** [concrete synthesis]
```
