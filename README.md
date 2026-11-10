# Claude Skills Kit

Claude Code skills for engineering, research, job applications and decision making. Every skill works on stock Claude Code. Skills that can hand work to cheaper Ollama Cloud models ship that behaviour as a separate add-on file that loads only when you set it up.

## Layout

| Folder | What is in it |
|---|---|
| `created/` | Skills written for this kit |
| `collected/` | Skills by other authors, redistributed under their license, credited below |
| `ollama-addon/` | Optional: the `CLAUDE.md` delegation section and the Track A drop-folder runner that the add-on files use |
| `report-comments/` | Drop-in comment widget for HTML reports: select text, comment, copy all comments back into the session |

## Created skills

| Skill | What it does | Add-on |
|---|---|---|
| `/polish-prompt` | Rewrites a rough prompt into a specific one, splits bundled tasks, picks model and effort, routes to a matching skill | `ollama_routing.md` |
| `/modern-engineer` | 5-phase build workflow: brainstorm, plan, work, review, debug. Interviews before coding | |
| `/web-scraping` | Research router: cache first, free tools first, paid MCP (Model Context Protocol) tools only when needed | optional Firecrawl budget hook |
| `/research-fanout` | Splits one question into parallel research lanes you approve, then merges, verifies and cites one report. Resumes after a stop | `ollama_routing.md` |
| `/tailor-jd` | Tailors your master CV (curriculum vitae) to one or more JDs (job descriptions) with a fit score, ATS (Applicant Tracking System) coverage and an honesty audit | `ollama_addon.md` |
| `/video-review` | Batch-reviews social video links against per-link instructions, one consolidated report | `ollama_addon.md` |
| `/task-status` | Shows which subagent dispatches are pending or finished, from a local log. No model or API (Application Programming Interface) calls | logging hook (required, the log is empty without it) |
| `/ask-the-board` | Recommends two expert advisors for a context, then gives each one's take on a decision | |
| `/internal-focus-group` | Panel of real people, built from notes you saved, each answering in their own voice | |
| `/ingest-resource` | Files articles, links, PDFs and transcripts into `knowledge/` or `projects/` with a summary block | |
| `/improve-system` | Reviews memory, skills and process in 5 modes: audit, skill-review, experience, historical-review, foundation | |

## Collected skills

| Skill | Author | License |
|---|---|---|
| `/task-observer` | Eoghan Henn, [rebelytics.com](https://rebelytics.com), source [rebelytics/one-skill-to-rule-them-all](https://github.com/rebelytics/one-skill-to-rule-them-all) | CC BY 4.0 (Creative Commons Attribution), [license text](https://creativecommons.org/licenses/by/4.0/) |

The `/polish-prompt` nudge hook in `settings-hook-example.json` is inspired by [claude-code-prompt-improver](https://github.com/severity1/claude-code-prompt-improver) (MIT License).

Kit change to `/task-observer`: a `## Tutorial mode` section and a `TUTORIAL.md` were added; the rest is the original text.

## Install

Copy one skill folder, or all of them, into your skills directory:

```bash
# macOS / Linux
cp -r created/polish-prompt ~/.claude/skills/

# Windows (PowerShell)
Copy-Item -Recurse created\polish-prompt "$env:USERPROFILE\.claude\skills\"
```

After copying a skill, run `/<skill> setup`. Each skill with dependencies checks them on first use and walks you through anything missing, so it never breaks mid-call. Skills with hooks or setup steps also have their own `README.md`.

New to a skill? Each one ships a `TUTORIAL.md`. On first use the skill offers a short guided tutorial once; you can also start it any time with `/<skill> tutorial`. It walks you through a safe practice run and how to read the output, one step at a time.

Optional `/polish-prompt` nudge: merge `settings-hook-example.json` into `~/.claude/settings.json`. Start a prompt with `*` (already specific) or `#` (debugging, keep raw) to skip it.

## Ollama add-on (optional)

Lets the skills route mechanical pieces of a task (drafts, research summaries, boilerplate) to Ollama Cloud models and keep judgment, tests and git on Claude.

1. Copy the whole `ollama-addon/` folder to `~/.claude/ollama-addon/` (the skills read its README and template from there; Track A scripts then live in `~/.claude/ollama-addon/track-a/`).
2. Paste `ollama-addon/CLAUDE_SECTION.md` into `~/.claude/CLAUDE.md` and edit the model roster.
3. For headless background work, set up Track A: [ollama-addon/README.md](ollama-addon/README.md).

Without that section in `CLAUDE.md`, every skill runs on Claude only and never mentions Ollama.

## Requirements

- Claude Code.
- `/web-scraping`: works with built-in WebSearch and WebFetch; Exa, Gemini and Firecrawl MCP servers are optional.
- `/internal-focus-group`: member profiles saved with `/ingest-resource`.
- Track A and the hooks: Windows PowerShell 5.1 or newer.

## License

MIT ([LICENSE](LICENSE)) for `created/` and `ollama-addon/`. Collected skills keep their own license (task-observer: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)).
