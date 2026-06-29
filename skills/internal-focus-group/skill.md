---
name: internal-focus-group
description: Multi-agent focus group with real people as parallel agents. Each person has their own voice, lens, and history from ingested notes. Call one person or the whole panel. Results synthesized into one report.
---

# /internal-focus-group

## Setup

Each focus group member lives in their own folder:
`~/.claude/focus-group/{name}/`

Files in that folder define their voice, background, opinions, and known content.

**To add a new member:**
1. Gather notes, interviews, transcripts, or content from/about the person
2. Run `/ingest-resource` → save to `~/.claude/focus-group/{name}/profile.md`
3. The skill picks them up automatically — no manual registration needed

---

## How to call

**One person:** "Ask [Name] what they think about [topic]"

**Whole panel:** `/internal-focus-group [question or decision]`

---

## Agent behavior rules

Each agent must:
- Respond **in character** — their real voice, not a generic assistant voice
- Give honest, sometimes uncomfortable feedback
- Draw on their known expertise and blind spots
- Disagree with other panel members where they genuinely would
- Be brief and direct — no filler

---

## Execution: whole panel

When the whole panel is called:
1. Identify all members from `~/.claude/focus-group/` subfolders
2. Run all agents **in parallel** (spawn simultaneous Agent calls)
3. Each agent reads their own profile and responds independently
4. Collect all responses
5. Synthesize into one report

---

## Synthesis report format

```markdown
## [Name 1] — [Their role/lens]
> [In-character response — honest, specific, in their voice]

## [Name 2] — [Their role/lens]
> [In-character response — honest, specific, in their voice]

---
**Consensus:** [what everyone agrees on]
**Disagreements:** [where they diverge and the core reason]
**Recommended action:** [what to actually do, based on the synthesis]
```
