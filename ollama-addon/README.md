# Ollama add-on and Track A setup

This add-on lets `/polish-prompt` use the Ollama Cloud delegation table in `~/.claude/CLAUDE.md`. The vanilla skill works without it.

## What Track A is

Track A is a headless Claude Code process pointed at an Ollama Cloud model, fed by a drop folder. You write a small task file into `tasks/`. A watcher claims it and runs it. The result lands in `done/`. Up to three tasks can run at once.

## Task file format

- Line 1: working directory.
- Line 2: model.
- Optional `KEY=value` override lines: `TimeoutMinutes`, `MaxTurns`, `OutFile`, `BudgetKey`, `BudgetBase`.
- Then the prompt.

Write the file as `<slug>.txt.tmp` then rename it to `<slug>.txt` so the watcher never reads a half-written file. The watcher renames a claimed task to `<slug>.txt.inflight`; the result lands in `done/<slug>_done.txt`. Move results into `reviewed/` yourself after you check them. `OutFile` receives the run transcript, never point it at a report path.

## Shared dispatch helpers

`track-a/dispatch_ollama_task.py` and `track-a/check_watcher.ps1` live in `track-a/` and are shared by the video-review and research-fanout skills. Both read `TRACK_A_DIR`; the dispatcher also reads `TRACK_A_TASK_NAME` and defaults it to `ClaudeSkills_Ollama_DropfolderWatcher`. Run them from `<TRACK_A_HOME>` with `python` and `powershell -NoProfile -File`, and run `--selftest` once after install.

- `--header KEY=VALUE` adds one optional task file header line. It is repeatable, and the lines are written in the order given, after the model line and before the prompt. KEY must be one of `TimeoutMinutes`, `MaxTurns`, `OutFile`, `BudgetKey`, `BudgetBase`; any other key, an empty value or a newline in the value exits 2 before a task file is written.
- `--prompt-file PATH` reads the prompt from a UTF-8 file instead of `--prompt`, for prompts too long to pass on one command line. Pass exactly one of the two.

## Prerequisites

- Windows.
- PowerShell 5.1 or newer.
- Claude Code CLI (command line interface).
- Ollama with `ollama signin` completed.
- An Ollama Cloud plan.
- An Ollama API (Application Programming Interface) key in the `OLLAMA_API_KEY` environment variable, for the usage check. Create one at ollama.com/settings/keys.

## Install

1. Paste `ollama-addon/CLAUDE_SECTION.md` into `~/.claude/CLAUDE.md` and edit the model roster to the models on your plan. The skills look for that section to switch the add-on on.
2. Copy the whole `ollama-addon/` folder to `~/.claude/ollama-addon/`. Track A scripts then live in `~/.claude/ollama-addon/track-a/`. Call that Track A folder `<TRACK_A_HOME>`.
3. Create the drop folder: `<TRACK_A_HOME>\ollama_dropfolder\` with `tasks\`, `done\`, `reviewed\` and `logs\` inside. This drop folder is `<TRACK_A_DIR>` in the skills.
4. Set the environment variable `TRACK_A_DIR` to that drop folder path (used by the video-review scripts):
   `[Environment]::SetEnvironmentVariable('TRACK_A_DIR', "$env:USERPROFILE\.claude\ollama-addon\track-a\ollama_dropfolder", 'User')`
5. Optional: create `<TRACK_A_DIR>\max_parallel.txt` with `1`, `2` or `3`. This caps concurrent tasks. Default is 3.
6. Open PowerShell in `<TRACK_A_HOME>` and run the smoke test with a model: `powershell -ExecutionPolicy Bypass -File .\run_ollama_batch.ps1 -SmokeTest -Model <model>:cloud`, or set the `TRACK_A_DEFAULT_MODEL` environment variable. Real runs need `-Model` or that environment variable too.
7. Register the watcher once, in your own terminal, because it prompts for your Windows password (Task Scheduler stores it, the script does not):
   `powershell -ExecutionPolicy Bypass -File .\register_ollama_watcher_task.ps1`
8. Start it now with `Start-ScheduledTask -TaskName ClaudeSkills_Ollama_DropfolderWatcher`, or log off and on.

## Safety limits

The worker settings file `ollama_batch_permissions.json` uses JavaScript Object Notation (JSON). Its deny list is text-pattern matching on commands, best-effort only, not a sandbox. A worker can still write and run a script that does what a deny blocks. The list covers both the Bash and PowerShell tools: `git commit`, `git push`, `git merge`, `git rebase`, `git reset --hard`, `gh pr create`, `gh pr merge`, `gh pr close`, `rm -rf`, secret reads, and any shell command naming a `.claude` path. It also denies Write and Edit under `~/.claude`. Run workers only on repos you can restore from git, never with secrets in the working folder. Review every diff and run Track A on a branch or a disposable copy.

`ollama_batch_permissions.json` calls `$USERPROFILE/.claude/hooks/firecrawl_budget_gate.ps1`, so install the web-scraping hook first or delete that hook block.

## Turn caps and long tasks

Default caps are 25 turns and 8 minutes. Deepseek models get 60 turns and 20 minutes. Explicit `-MaxTurns` and `-TimeoutMinutes` win. A task that will plausibly pass about 60 turns is split, or handed to a Cline handover instead. Cline is an open-source VS Code coding agent that can run on the same Ollama Cloud models in an interactive session; Claude writes the handover file, you run it.

## Check usage

`curl.exe -s -H "Authorization: Bearer $env:OLLAMA_API_KEY" https://ollama.com/api/balance`

The response has `included.session` and `included.weekly`, each with `remaining_percent` and `resets_at`. These fields may be absent on credit-pool plans. Do not exceed 10 calls a minute. If the `usage-live` skill is installed, it can show the Claude side.

## Troubleshooting

- A `429` rate limit can surface as an `unrecognized_model` error. Wait for the reset, then retry.
- The watcher is not running: check the `ClaudeSkills_Ollama_DropfolderWatcher` scheduled task and start it.
- A task stays in `tasks/`: check that the watcher process is running and that `max_parallel.txt` is not full.
- A result is missing: check `logs/` and the `done/` file for a watcher-level error.
