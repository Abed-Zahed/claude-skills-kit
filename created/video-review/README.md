# video-review

Batch-review social video links against per-link free-text instructions. The skill fetches page text and metadata, optionally transcribes video or audio locally, takes screenshots when asked, and writes one verdict per link plus a consolidated report.

## Install

Copy the `created/video-review` folder into your Claude Code skills directory, for example:

- Unix-like systems: `~/.claude/skills/video-review`
- Windows: `$env:USERPROFILE\.claude\skills\video-review`

Restart Claude Code or reload skills if your setup requires it.

## Use

Call the skill with one link and instruction per line:

```
/video-review
https://www.youtube.com/watch?v=example - summarize the main claim
https://www.instagram.com/reel/example - check the claim about product X and screenshot at 25 seconds if true
```

You can also pass a path to a plain text file that contains the same link and instruction lines. A link with no instruction is treated as digest only with no ticket.

## Optional tools

The vanilla skill works with stock Claude Code. These tools improve results when installed:

- yt-dlp: downloads video or audio and returns metadata.
- ffmpeg: captures a single frame at a timestamp.
- Whisper: a local speech-to-text build for exact claim checks and quotes.

If yt-dlp is missing, the skill uses WebFetch page text and metadata. If Whisper is missing, exact claim checks may be limited to page text and metadata.

## Optional Ollama Cloud add-on

If `~/.claude/CLAUDE.md` contains an "Ollama Cloud delegation" section, the skill loads `ollama_addon.md` and sends per-link fetch and first-pass summary work to Track A. The model choice comes from the delegation table in `~/.claude/CLAUDE.md`, not from this skill. The add-on uses `scripts/dispatch_ollama_task.py` and `scripts/check_watcher.ps1`. Set `TRACK_A_DIR` to the Track A dropfolder. Set `TRACK_A_TASK_NAME` if your watcher task name differs from the default.

## Ticket creation

Ticket creation is optional and happens only when a link's own instruction explicitly asks for it. The skill uses a configured ticket tool or MCP (Model Context Protocol) server. No ticket-routing script is included. Routing to a specific ticket system is left to the user.

## Report location

For 1 to 3 links, verdicts appear in the chat response. For more than 3 links, the skill writes a consolidated Markdown report to `reports/YYYY-MM-DD_batch_review.md` under the current working directory.

## Weekly scheduled run (optional)

You can run the skill on a schedule with Windows Task Scheduler. The task runs Claude Code with a prompt that points at a links file.

1. Create a working directory for the scheduled run, for example:
   `$env:USERPROFILE\video-review`

2. Create a links file in that directory, for example:
   `$env:USERPROFILE\video-review\links.txt`

   Put one video URL (Uniform Resource Locator) and instruction pair per line. Blank lines are allowed.

3. Register a weekly task. Run PowerShell as the user who will own the task:

   ```powershell
   $workDir = "$env:USERPROFILE\video-review"
   $linksFile = "$workDir\links.txt"
   New-Item -ItemType Directory -Force -Path $workDir | Out-Null

   $action = New-ScheduledTaskAction `
     -Execute "powershell.exe" `
     -Argument "-NoProfile -Command `"claude -p '/video-review $linksFile' --allowedTools 'WebFetch,Bash,Read,Write'`"" `
     -WorkingDirectory $workDir

   $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am

   Register-ScheduledTask `
     -TaskName "ClaudeSkills_VideoReview_Weekly" `
     -Action $action `
     -Trigger $trigger
   ```

   A headless `claude -p` run denies tools unless they are allowed. The example above allows WebFetch, Bash, Read, and Write; narrow `--allowedTools` to only the tools this run needs.

   If the task account cannot find `claude` in its command search path, replace `claude` with the full path to the Claude Code executable.

4. The report lands in:
   `$env:USERPROFILE\video-review\reports\YYYY-MM-DD_batch_review.md`

Notes:
- The scheduled task must run as a user who can run Claude Code with the same permissions as an interactive session.
- Keep the links file in a stable location that the task account can read.
- Ticket routing is not included. If you want tickets, configure a ticket tool or MCP server and update the skill instructions to match your system.
