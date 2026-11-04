# Ollama add-on and Track A setup

This add-on lets `/polish-prompt` use the Ollama Cloud delegation table in `~/.claude/CLAUDE.md`. The vanilla skill works without it. ## What Track A is

Track A is a headless Claude Code process pointed at an Ollama Cloud model, fed by a drop folder. You write a small task file into `tasks/`. A watcher claims it and runs it. The result lands in `done/`. Up to three tasks can run at once.

## Prerequisites

- Windows.
- PowerShell 5.1 or newer.
- Claude Code CLI (command line interface).
- Ollama with `ollama signin` completed.
- An Ollama Cloud plan.
- An Ollama API (Application Programming Interface) key in the `OLLAMA_API_KEY` environment variable, for the usage check. Create one at ollama.com/settings/keys.

## Install

1. Paste `ollama-addon/CLAUDE_SECTION.md` into `~/.claude/CLAUDE.md` and edit the model roster to the models on your plan. The skills look for that section to switch the add-on on.
2. Copy `ollama-addon/track-a/` to a folder of your choice, for example `$env:USERPROFILE\track-a`. Call that folder `<TRACK_A_HOME>`.
3. Create the drop folder: `<TRACK_A_HOME>\ollama_dropfolder\` with `tasks\`, `done\`, `reviewed\` and `logs\` inside. This drop folder is `<TRACK_A_DIR>` in the skills.
4. Set the environment variable `TRACK_A_DIR` to that drop folder path (used by the video-review scripts):
   `[Environment]::SetEnvironmentVariable('TRACK_A_DIR', "$env:USERPROFILE\track-a\ollama_dropfolder", 'User')`
5. Optional: create `<TRACK_A_DIR>\max_parallel.txt` with `1`, `2` or `3`. This caps concurrent tasks. Default is 3.
6. Open PowerShell in `<TRACK_A_HOME>` and run the smoke test:
   `powershell -ExecutionPolicy Bypass -File .\run_ollama_batch.ps1 -SmokeTest`
7. Register the watcher once, in your own terminal, because it prompts for your Windows password (Task Scheduler stores it, the script does not):
   `powershell -ExecutionPolicy Bypass -File .\register_ollama_watcher_task.ps1`
8. Start it now with `Start-ScheduledTask -TaskName ClaudeSkills_Ollama_DropfolderWatcher`, or log off and on.

## Safety

The worker settings file `ollama_batch_permissions.json` uses JavaScript Object Notation (JSON). It denies `git commit`, `git push`, `git merge`, writes to `~/.claude`, and reads of `.env` files. Review every result in `done/` before applying it. The worker can still edit files in the working directory, so use a clean branch or a copy you can discard.

## Turn caps

Default caps are 25 turns and 8 minutes, 60 turns and 20 minutes for deepseek models. Explicit `-MaxTurns` and `-TimeoutMinutes` win. Size them to the task: small edits need fewer turns, research or multi-file work needs more. Long tasks that will exceed the caps should use a handover instead.

## Check usage

`curl.exe -s -H "Authorization: Bearer $env:OLLAMA_API_KEY" https://ollama.com/api/balance`

The response has `included.session` and `included.weekly`, each with `remaining_percent` and `resets_at`. These fields may be absent on credit-pool plans. Do not exceed 10 calls a minute. If the `usage-live` skill is installed, it can show the Claude side.

## Troubleshooting

- A `429` rate limit can surface as an `unrecognized_model` error. Wait for the reset, then retry.
- The watcher is not running: check the `ClaudeSkills_Ollama_DropfolderWatcher` scheduled task and start it.
- A task stays in `tasks/`: check that the watcher process is running and that `max_parallel.txt` is not full.
- A result is missing: check `logs/` and the `done/` file for a watcher-level error.
