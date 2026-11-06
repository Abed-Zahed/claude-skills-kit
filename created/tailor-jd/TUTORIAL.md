# tailor-jd tutorial
Tailors your master CV (curriculum vitae) to job descriptions (JDs) with a fit score, keyword coverage, and an honesty check.

## Step 1: What it does
- Scores how well your master CV fits each job description, using only evidence already in the CV.
- Rewrites and reorders existing CV content to match the job's terms, without adding claims.
- Measures ATS (Applicant Tracking System) keyword coverage before and after, and audits the result for honesty.

Claude: pause here and ask if the user is ready for the next step.

## Step 2: Try it
Run a safe practice pass with made-up input. The skill reads your master CV path from the MASTER_CV line in its SKILL.md, so set that first if you have not. Then type:

`/tailor-jd Junior Data Analyst at Acme Corp. Must have: SQL, Excel, dashboards, clear communication.`

The tailored CV is written to ./tailored/acme-corp_junior-data-analyst.md in your current folder.

Claude: pause here and ask if the user is ready for the next step.

## Step 3: Read the output
After the file is saved, you get exactly five lines:
1. Role at company, fit N/100. The fit score is 0 to 100, based only on evidence quoted from your CV.
2. Must-haves: x/y met, plus any missing ones. Missing items are gaps, not new CV lines.
3. ATS: before N% to after M%. This is present keywords divided by total keywords; the after number must not drop.
4. Honesty: clean, or the count of unsupported claims that were removed.
5. File path, plus gaps to consider addressing yourself.

Act on the gaps and the fit detail, not on invented content.

Claude: pause here and ask if the user is ready for the next step.

## Step 4: Use it on your own work
- `/tailor-jd` and paste a job description you are actually applying to.
- `/tailor-jd https://example.com/job/123` to fetch a JD from a link (if the link fails, the skill reports it and continues).
- Paste two or more JDs at once to get one tailored CV per job.

Claude: pause here and ask if the user is ready for the next step.

## Step 5: Common mistakes
- Leaving the MASTER_CV path unset or pointing at an unreadable or wrong-format file (only .md, .markdown, .yml, .yaml work).
- Expecting the skill to fill JD gaps with new skills or metrics; it will not, and it will remove unsupported claims.
- Assuming optional add-on setup (Ollama, TRACK_A_DIR, watcher) is required; it is not.

Claude: pause here and ask if the user is ready for the next step.

## Step 6: Where to go next
Run `/tailor-jd setup` to check your configuration and write the .setup_ok marker. Optional add-on items (an "Ollama Cloud delegation" section in ~/.claude/CLAUDE.md, the TRACK_A_DIR environment variable, a running watcher) unlock extra behaviour; without them you simply lose that add-on.

Claude: pause here and ask if the user is ready for the next step.
