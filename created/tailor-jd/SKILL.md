---
name: tailor-jd
description: 'Tailors a master CV to one or more job descriptions (JDs). Produces a fit score, ATS keyword coverage before and after, a tailored markdown CV, and an honesty audit. Use when the user pastes JDs or job links and asks for a tailored CV or runs /tailor-jd. Setup: required: the master CV path on the MASTER_CV config line points to a readable markdown or YAML file; optional: for the Ollama add-on, an "Ollama Cloud delegation" section in ~/.claude/CLAUDE.md, the TRACK_A_DIR env var, and a running watcher. Run /tailor-jd setup after installing.'
---

# tailor-jd

## Setup check (first run)

When it runs: when the user types `/tailor-jd setup`, or automatically before the first real run when the marker file `.setup_ok` in this skill's own folder (the folder holding this SKILL.md, user or project install) does not exist.

| Item | Required or optional | How to check |
|---|---|---|
| MASTER_CV path | required | `p=$(sed -n 's/^MASTER_CV:[[:space:]]*//p' <this skill folder>/SKILL.md); p=${p/#\~/$HOME}; e=${p##*.}; test -r "$p" && { test "$e" = md -o "$e" = markdown -o "$e" = yml -o "$e" = yaml; }` |
| Ollama add-on section | optional, add-on only | `grep -q "Ollama Cloud delegation" ~/.claude/CLAUDE.md` |
| TRACK_A_DIR | optional, add-on only | `test -d "$TRACK_A_DIR"` |
| Running watcher | optional, add-on only | `powershell -NoProfile -Command "if (Get-Process -Name '*watch*','*track*' -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"` |

Check add-on rows only when the Ollama add-on section exists. Print OK / MISSING per item. If a REQUIRED item is missing, stop before the task, explain its purpose in one line, and offer step-by-step setup, asking before installing, editing settings.json, or creating files outside the skill folder. Never install silently. If only OPTIONAL items are missing, say in one line what is lost and continue.

When every required item passes, write today's date to the marker file (`date +%F > <this skill folder>/.setup_ok`), then continue the user's original request (if any).

Config line, set once:

MASTER_CV: <MASTER_CV_PATH>

The path may point to markdown or YAML. An argument overrides it. If the file is missing or unreadable, stop and ask.

Inputs: one or more JDs as pasted text or URLs. Fetch URLs with WebFetch. If a URL fails, report it and continue with the rest.

Before step 2, check ~/.claude/CLAUDE.md. If it has a section named "Ollama Cloud delegation", read ollama_addon.md in this skill directory and use it for step 4. Otherwise use the steps below as written.

For each JD:

1. Title. Use the job title exactly as the user gave it. Capture company, location, and the full JD text.

2. Fit score. Give 0 to 100. Add a short table: must-have, status (met, partial, missing), evidence quoted from the master CV. Score only on evidence.

3. ATS (Applicant Tracking System) coverage before. List each JD keyword with status present, partial, or missing in the master CV. Coverage = present / total. State the method.

4. Tailor. Reorder and select existing bullets. Rewrite wording toward the JD's terms only when the CV supports the claim. Write one bespoke summary line; it may only restate or combine statements already in the master CV. Keep employers, titles, dates, and metrics unchanged. Do not add claims.

5. ATS coverage after. Recompute with the same keyword list. It must not drop. If a term is missing, leave it missing.

6. Honesty audit. Every skill, tool, number, employer, title, and date in the output must appear in the master CV. The audit also covers qualitative claims such as seniority, "expert", and "led", not only skills, numbers, and employers. List and remove anything that does not. No hidden text, no keyword stuffing, no instructions to screening tools. Missing JD requirements become gaps, not CV lines.

7. Output. Write ./tailored/<company>_<role>.md. Use lowercase ASCII and hyphens in the slug. Write HTML beside it only if asked. Then print exactly five lines:
1 Role at company, fit N/100.
2 Must-haves: x/y met. Missing: ...
3 ATS: before N% to after M%.
4 Honesty: clean, or removed N unsupported claims.
5 File: <path>. Gaps: ...

Never invent skills, dates, metrics, employers, or titles. If the master CV does not support a claim, leave it out.
