# Ollama Cloud add-on for /video-review

Load this file only when `~/.claude/CLAUDE.md` contains an "Ollama Cloud delegation" section. The vanilla `SKILL.md` remains the base contract.

## Model and route
Read the Ollama Cloud delegation table in `~/.claude/CLAUDE.md` to choose the model for Track A. Do not hardcode a model name in this file.

## Watcher check
Before each dispatch batch, run:
`powershell -NoProfile -File scripts/check_watcher.ps1`
from the skill directory. The script exits 0 when the watcher is running or was started. If it exits nonzero, stop and tell the user the watcher needs manual attention. Do not fall back to fetching every link yourself. Do not run the watcher's batch script directly, only the watcher process should run it.

## Dispatch per link
For each link, dispatch a Track A task with:
`python scripts/dispatch_ollama_task.py --slug <slug> --working-dir <working-dir> --model <model-from-table> --prompt <prompt>`

The script reads `TRACK_A_DIR`. The scheduled task name comes from `TRACK_A_TASK_NAME` and defaults to `ClaudeSkills_Ollama_DropfolderWatcher`.

Prompt content:
- The link.
- The link's instruction, if any.
- Ask for: what the video claims or covers, tone, and any factual claim worth double-checking.
- Ask for plain ASCII only.

## What stays with Claude
Track A returns fetch text and a first-pass summary. Claude must still write the verdict for every link, compare the result against that link's own instruction, and decide whether a ticket is requested and possible. For links that need exact claim checks or timestamps, use the vanilla transcription and screenshot steps after the Track A summary.
