# research-fanout

Research one question by splitting it into independent sub-questions, getting your approval on the split, running them in parallel, then merging, verifying and citing one report.

## What it does

1. **Split**: the question becomes 3 to 6 independent sub-questions, one per research lane, plus the constraints it carries and, for a decision question, the ranking criteria.
2. **Approve**: you get one short list, and nothing is dispatched until you approve or edit it.
3. **Fan out**: each lane answers only its own sub-question and writes its own lane file.
4. **Fan in**: sources are deduplicated and numbered, contradictions between lanes are flagged, and candidates are ranked against the criteria.
5. **Verify**: Claude reads the cited source for the key claims and for every contradiction, instead of trusting a worker's quote.
6. **Report**: one report where every factual claim carries a numbered citation, plus a Gaps section naming dropped lanes and unverified claims.

## The two modes

- **Stock mode (default)**: lanes run as Claude subagents, at most 2 in flight at a time, so lanes go out in small batches. Nothing beyond Claude Code is needed.
- **Ollama mode**: lanes and the fan-in run on Ollama Cloud models through the Track A drop folder. Claude keeps the split, the approval gate, verification and the report.

The mode is chosen at run time. If `~/.claude/CLAUDE.md` has an "Ollama Cloud delegation" section, the skill loads `ollama_routing.md` and runs in Ollama mode. `--vanilla` forces stock mode even when that section exists.

## Run folder

All state is written to disk in one folder per run, so a crash loses no finished work.

| File | Contents |
|---|---|
| `plan.md` | Question, constraints, criteria, and the approved lanes with their letters |
| `agent_<X>.md` | One lane's answer, findings, doubts and sources. Its last line is `STATUS: DONE` |
| `sources.md` | The deduplicated, numbered source list. These numbers are the citation numbers |
| `fanin.md` | Merged findings, contradictions and the ranking |
| `verify.md` | The checked claims, their source numbers and the verdict on each |
| `report.md` | The final report |
| `report.html` | Optional self-contained copy of a long report, in HTML (HyperText Markup Language) |

Stock mode puts the run folder at `./research/<YYYYMMDD>_<slug>/`; Ollama mode puts it at `research_cache/runs/<YYYYMMDD>_<slug>/`.

## Resume

A lane is finished only when its file ends with `STATUS: DONE`. To resume a stopped run, start the skill again on the same question: it finds `plan.md`, runs `dedup_sources.py --status` in the run folder, and continues with the unfinished lanes only. A finished lane is never re-run.

## Requirements

- Python 3.10 or newer, for `scripts/dedup_sources.py`, which uses the standard library only.
- Stock mode: Claude Code, with the Agent tool available.
- Ollama mode: the Track A setup described in `ollama-addon/README.md`, and the `TRACK_A_DIR` environment variable pointing at the drop folder.

## Credit

Coordinator and worker pattern inspired by Anthropic's deep-research skill; prompts written fresh for this kit.
