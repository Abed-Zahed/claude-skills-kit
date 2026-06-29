---
name: ask-the-board
description: Advisory board skill. Two modes — recommend (research and suggest 2 expert advisors for any context) or consult (get each advisor's honest take on a decision in their own voice). Works for engineering, business, career, and personal decisions.
---

# /ask-the-board

## Two modes

### Recommend mode
Triggered when: "who should be on my board for X?" or starting a new context.

1. Use `/web-scraping` to research 3-5 relevant candidates
2. Select 2 who best fit the user's specific context
3. For each advisor deliver:
   - **Who they are** — name, title, why they're relevant
   - **Their philosophy** — 2-3 sentences on their core worldview
   - **Best 5 pieces of content** to ingest via `/ingest-resource`
4. Save board to `~/.claude/knowledge/board/<topic>-board.md`

### Consult mode
Triggered when a decision or question is asked and a board exists for that context.

1. Read saved board profiles from `knowledge/board/<topic>-board.md`
2. Write each advisor's response **in their own voice** — their actual style, not a generic answer
3. Advisors should disagree where they genuinely would
4. Synthesize at the end

---

## Context routing

| Context | Advisor bias |
|---|---|
| Product / branding / social media | Creators with product business experience |
| Job hunting / CV / career moves | Recruiters, hiring managers, career coaches, senior engineers |
| Tech / engineering / software | Technical founders, senior engineers, startup CTOs |
| General business / strategy | Mix of operator and marketer |
| Personal decision / life | Generalist thinkers, not domain-specific |

---

## Customizing for your context

Edit the "Context routing" table above to match your situation — add rows for your specific domains (e.g. your industry, your business type, your career stage).

---

## Response format (consult mode)

```
**[Advisor Name] — [Their title/platform]**
> "[Their honest take in their own voice and style]"

**[Advisor Name] — [Their title/platform]**
> "[Their honest take in their own voice and style]"

---
✓ **They agree on:** [what both say]
✗ **They disagree on:** [where they split and why]
→ **What you should actually do:** [concrete synthesis]
```
