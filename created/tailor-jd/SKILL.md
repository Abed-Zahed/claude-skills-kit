---
name: tailor-jd
description: Tailors a master CV to one or more job descriptions (JDs). Produces a fit score, ATS keyword coverage before and after, a tailored markdown CV, and an honesty audit. Use when the user pastes JDs or job links and asks for a tailored CV or runs /tailor-jd.
---

# tailor-jd

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
