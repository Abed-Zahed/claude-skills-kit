---
name: improve-system
description: "5-mode system improvement skill. Triggered automatically when asked to \"review your work\", \"double check\", or \"improve the process\". Modes: audit, skill-review, experience, historical-review, foundation. Setup: your project memory folder ~/.claude/projects/<project>/memory/ exists (check: ls ~/.claude/projects/*/memory); optional: none. Run /improve-system setup after installing."
---

# /improve-system

## Tutorial mode

- Runs when the user types `/improve-system tutorial`, or asks to learn the skill.
- First run only: if `.tutorial_offered` does not exist in this skill folder, ask once "Want a short guided tutorial for /improve-system? (yes / no)" before the setup check, then create that file so it is never asked again.
- On yes: read `TUTORIAL.md` in this skill folder and walk the user through it one step at a time, waiting for them after each step. Then return to their original request, if any.

## Setup check (first run)

When it runs: when the user types `/improve-system setup`, or automatically before the first real run when the marker file `.setup_ok` in this skill's own folder (the folder holding this SKILL.md, user or project install) does not exist.

| Item | Required or optional | How to check |
|---|---|---|
| Project memory folder `~/.claude/projects/<project>/memory/` | Required | `ls ~/.claude/projects/*/memory` |
| No optional items | Optional | none; continue |

Interactive rules: print the checklist with OK / MISSING per item. If a REQUIRED item is missing, stop before doing the task, explain what it is for in one line, and offer to set it up now, step by step, asking the user before installing anything, editing settings.json, or creating files outside the skill folder. Never install silently. If only OPTIONAL items are missing, say in one line what is lost and continue.

When every required item passes, write the marker file with today's date, then continue with the user's original request (if any).

## Auto-trigger rule
Run this skill automatically when the user says:
- "review your work" / "double check" / "improve the process" -> **skill-review**
- "I just learned" / "we should remember" / "that worked well" -> **experience**
- "what did we miss" / "review our sessions" / "mine past sessions" -> **historical-review**
- "find duplicates" / "clean up notes" / "audit memory" -> **audit**
- "what are we missing" / "fill in the gaps" / "foundational" -> **foundation**

If mode is unclear from context, ask: *"Which mode? audit / skill-review / experience / historical-review / foundation"*

---

## Mode: audit
Find stale, conflicting, or duplicate notes.

1. Scan `~/.claude/projects/<project>/memory/` for:
   - Duplicate topics across files
   - Contradictions between files
   - Notes older than 30 days with time-sensitive claims (dates, job statuses)
   - Memory entries that reference code/files that no longer exist
2. Report findings as a list: **keep / merge / delete / update**
3. Apply changes with confirmation

---

## Mode: skill-review
Improve a specific skill based on recent back-and-forth.

1. Identify which skill underperformed or succeeded in the recent conversation
2. Read the skill's `SKILL.md`
3. Review conversation for: gaps, repeated corrections, what worked
4. Propose specific edits (show before/after)
5. Apply with confirmation

---

## Mode: experience
Capture a story, win, or lesson just shared.

1. Extract from what was shared:
   - What happened (situation)
   - What worked / what failed
   - The lesson or principle
   - Who was involved
2. Format as a memory entry with the standard frontmatter
3. Route to `~/.claude/knowledge/experiences/` or relevant project memory
4. Add [[wikilinks]] to related concepts

---

## Mode: historical-review
Mine recent Claude Code sessions for missed learnings.

1. Review recent git commits, conversation patterns, and corrections in this session
2. Identify:
   - Repeated mistakes that should be in memory
   - Approaches that worked well but weren't saved
   - Decisions made that future sessions would benefit from knowing
3. Propose new memory entries or skill updates for each finding
4. Apply confirmed items

---

## Mode: foundation
Fill in missing foundational content for a project or identity.

Check for and fill in missing entries across these pillars:
- **Brand voice**, how the user writes and speaks
- **Target audience**, who they're talking to
- **Offers/products**, what they're selling or building
- **Core processes**, how they do their key workflows
- **Key people**, team, advisors, frequent collaborators

For each missing item: ask 3-5 targeted questions, save answers to `~/.claude/knowledge/foundation/`.
This content feeds `/ask-the-board` and `/internal-focus-group`.
