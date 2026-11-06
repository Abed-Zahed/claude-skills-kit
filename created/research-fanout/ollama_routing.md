# Ollama add-on for /research-fanout

Loaded by SKILL.md when `~/.claude/CLAUDE.md` has an "Ollama Cloud delegation" section. Workers and fan-in run on Ollama Cloud through the Track A drop folder; Claude splits, gates, verifies and writes the report.

## Paths
- `TRACK_A_DIR` (environment variable) is the drop folder; `<TRACK_A_HOME>` is its parent and holds the runner, `dispatch_ollama_task.py` and `check_watcher.ps1`.
- Run folder: `<TRACK_A_HOME>/research_cache/runs/<YYYYMMDD>_<slug>/`. The shared URL cache lives one level up, so workers reuse what earlier jobs fetched.

## Who does what
| Piece | Who |
|---|---|
| Resume check, split, approval gate, plan.md | Claude |
| Lane research (section 3) | Track A, writer of the "Routine code, docs, research" row |
| Dedup (section 5) | the script, run by Claude |
| Fan-in (section 6) | Track A, reviewer of the "Final review" row |
| Verify, re-rank, report | Claude |

Model names come from the "Ollama Cloud delegation" table in `~/.claude/CLAUDE.md` at run time. Never write a model name into this skill.

## Before dispatch
- Run `powershell -NoProfile -File "<TRACK_A_HOME>/check_watcher.ps1"`. If it exits non-zero, tell the user Track A is down and ask whether to wait or run this research in vanilla mode. Never fall back silently.

## Fan out (replaces SKILL.md section 3)
- Lane prompt = the text below the dashed line of the Track A research preamble (`<TRACK_A_HOME>/docs/track_a_research_preamble.txt` when present), then the filled `worker_prompt.md`. Budget line in the worker prompt: "about 40 tool calls". Research rules line: "the RESEARCH TOOL POLICY at the top of this prompt; for GitHub data use the authenticated `gh` CLI, not the anonymous API".
- Retries and resumes reuse the lane's slug: the helper moves a stale `done/` file to `reviewed/` before queueing, so an old result is never returned.
- One background Bash call per lane, all in one message (the watcher enforces the lane cap on its own, so no waves here):
  ```
  python "<TRACK_A_HOME>/dispatch_ollama_task.py" --slug rf_<slug>_<X> --working-dir "<run>" --model <row writer>
    --header MaxTurns=45 --header TimeoutMinutes=20
    --header OutFile=<TRACK_A_DIR>/logs/rf_<slug>_<X>.jsonl
    --header BudgetKey=rf_<slug> --header BudgetBase=60
    --timeout <seconds> --prompt-file "<run>/prompt_<X>.txt"
  ```
  Write each prompt to `<run>/prompt_<X>.txt` first. `--timeout` = 1500 times the number of waves the cap implies (read `<TRACK_A_DIR>/max_parallel.txt`, default 3), so a queued lane is not timed out while it waits.
- Size `MaxTurns` per "Track A turn caps and long-context tasks" in the Track A owner's CLAUDE.md when the lane differs from a plain research lane.

## Lane failures (replaces the worker rotation in SKILL.md section 4)
- Attempt 2: same model, sharper prompt naming what was missing, same BudgetKey. Attempt 3: the row's "Rotate to" model. A timeout skips straight to attempt 3. After that, drop the lane.

## Fan in (replaces the executor in SKILL.md section 6)
- One Track A task on the "Final review" row's reviewer model, `--header MaxTurns=30 --header TimeoutMinutes=20`, same BudgetKey. Prompt: the section 6 instructions from SKILL.md verbatim, the absolute paths of `plan.md`, `sources.md` and the finished agent files, output path `<run>/fanin.md`, last line `STATUS: DONE`, and "read the files, do not fetch the web".
- Claude reads fanin.md before verifying. If it lacks `STATUS: DONE` or a section, rerun once, then do the fan-in in the main session and say so in the report's Gaps.

## Dispatch line
After the report, one line: `Delegated: <writer> x<lanes>, <reviewer> x1, escalated: no|yes, attempts: <N>`.
