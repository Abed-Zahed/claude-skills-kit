# tailor-jd

Tailors a master CV (curriculum vitae) to one or more JDs (job descriptions). For each JD it gives a fit score, ATS (Applicant Tracking System) keyword coverage before and after, a tailored markdown file, and an honesty audit. The base skill runs on stock Claude Code with no Ollama, hooks, or MCP (Model Context Protocol) servers.

## Setup

Required:
- The `MASTER_CV` config line points to a readable markdown or YAML (YAML Ain't Markup Language) file.

Optional, only for the Ollama add-on:
- An "Ollama Cloud delegation" section in `~/.claude/CLAUDE.md`.
- The `TRACK_A_DIR` environment variable for the Track A drop folder.
- A running watcher.

Install commands:

```bash
mkdir -p ~/.claude/skills
cp -r created/tailor-jd ~/.claude/skills/tailor-jd
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force $env:USERPROFILE\.claude\skills | Out-Null
Copy-Item -Recurse created\tailor-jd $env:USERPROFILE\.claude\skills\tailor-jd
```

Set the config line in `<this skill folder>/SKILL.md`:

```
MASTER_CV: <MASTER_CV_PATH>
```

Reload Claude Code.

## Config

Open `<this skill folder>/SKILL.md` and set the config line:

```
MASTER_CV: <MASTER_CV_PATH>
```

Use a markdown or YAML (YAML Ain't Markup Language) file. A path passed as an argument overrides the config line. Keep the master CV outside this repo if it has personal data.

## Example run

```
/tailor-jd ./master_cv.md
```

Then paste one or more JDs, or URLs (Uniform Resource Locators) to job posts. Example:

```
/tailor-jd ./master_cv.md
https://example.com/jobs/data-analyst
```

The skill writes `./tailored/example-company_data-analyst.md` and prints a five-line report. Add "also give me HTML (HyperText Markup Language)" if you want an HTML copy. For several JDs, repeat the output per JD.

## Optional Ollama

If `~/.claude/CLAUDE.md` has a section named "Ollama Cloud delegation", the skill reads `ollama_addon.md` and may delegate drafting to an Ollama Cloud writer. Without that section, the vanilla skill runs alone. Model choice comes from that section's table, not from this skill.

## Honesty rules

- Never invent skills, tools, dates, metrics, employers, or job titles.
- Reorder and select bullets that already exist in the master CV; do not create achievements.
- Rewrite wording toward JD terms only when the master CV supports the claim.
- A skill missing from the master CV stays a gap. It is not added to the CV.
- Every number, tool, employer, title, and date in the output must appear in the master CV.
- No hidden text, keyword stuffing, or instructions to automated screening tools.
- The honesty audit lists and removes unsupported claims before output.
- Generated files are ASCII (American Standard Code for Information Interchange) only.
