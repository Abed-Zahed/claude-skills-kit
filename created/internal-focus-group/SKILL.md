---
name: internal-focus-group
description: "Multi-agent focus group that simulates people from saved notes as parallel agents; it does not contact real people. Each simulated person has their own voice, lens, and history from ingested notes. Call one person or the whole panel. Results synthesized into one report. Setup: at least one member profile at ~/.claude/focus-group/<name>/profile.md (check: ls ~/.claude/focus-group/*/profile.md); optional: the ingest-resource skill to build profiles from notes. Run /internal-focus-group setup after installing."
---

# /internal-focus-group

## Tutorial mode

- Runs when the user types `/internal-focus-group tutorial`, or asks to learn the skill.
- First run only: if `.tutorial_offered` does not exist in this skill folder, ask once "Want a short guided tutorial for /internal-focus-group? (yes / no)" before the setup check, then create that file so it is never asked again.
- On yes: read `TUTORIAL.md` in this skill folder and walk the user through it one step at a time, waiting for them after each step. Then return to their original request, if any.

## Setup check (first run)

When it runs: when the user types `/internal-focus-group setup`, or automatically before the first real run when the marker file `.setup_ok` in this skill's own folder (the folder holding this SKILL.md, user or project install) does not exist.

| Item | Required or optional | How to check |
|---|---|---|
| At least one member profile at `~/.claude/focus-group/<name>/profile.md` | Required | `ls ~/.claude/focus-group/*/profile.md` |
| ingest-resource skill | Optional | `test -f ~/.claude/skills/ingest-resource/SKILL.md` |

Interactive rules: print the checklist with OK / MISSING per item. If a REQUIRED item is missing, stop before doing the task, explain what it is for in one line, and offer to set it up now, step by step, asking the user before installing anything, editing settings.json, or creating files outside the skill folder. Never install silently. If only OPTIONAL items are missing, say in one line what is lost and continue.

When every required item passes, write the marker file with today's date, then continue with the user's original request (if any).

## Setup
Each focus group member lives in their own folder:
`~/.claude/focus-group/{name}/`

Files in that folder define their voice, background, opinions, and known content.

**To add a new member:**
1. Gather notes, interviews, transcripts, or content from/about the person
2. Run `/ingest-resource` then save to `~/.claude/focus-group/{name}/profile.md`
3. The skill picks them up automatically, no manual registration needed

---

## How to call

**One person:** "Ask [Name] what they think about [topic]"
**Whole panel:** "/internal-focus-group [question or decision]"

---

## Agent behavior rules
Each agent must:
- Respond **in character**, their real voice, not a generic assistant voice
- Give honest, sometimes uncomfortable feedback
- Draw on their known expertise and blind spots
- Disagree with other panel members where they genuinely would
- Be brief and direct, no filler

---

## Execution: whole panel

When the whole panel is called:
1. Identify all members from `focus-group/` subfolders
2. Run all agents **in parallel** (spawn simultaneous Agent calls)
3. Each agent reads their own profile and responds independently
4. Collect all responses
5. Synthesize into one report

---

## Synthesis report format

```markdown
## [Name 1], [Their role/lens]
> [In-character response, honest, specific, in their voice]

## [Name 2], [Their role/lens]
> [In-character response, honest, specific, in their voice]

## [Name 3], [Their role/lens]
> [In-character response, honest, specific, in their voice]

---
**Consensus:** [what everyone agrees on]
**Disagreements:** [where they diverge and the core reason]
**Recommended action:** [what to actually do, based on the synthesis]
```

---

## Current members
[Auto-populated from `focus-group/` subfolders, empty until first member added]

To see current members: list folders in `~/.claude/focus-group/`
