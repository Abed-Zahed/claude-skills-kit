# video-review — setup notes

Unlike the other 7 skills in this kit, `video-review` is **not zero-config**.
It was built for one person's machine and hardcodes three pieces of personal
infrastructure. This file explains what those pieces are and what you'd need
to build to adapt the skill to your own setup. `skill.md` itself is the
actual skill logic, this file is just the "what's missing" map.

## The three hardcoded dependencies

### 1. Ollama Cloud batch delegation ("Track A")

`skill.md` dispatches digest-only links to a background process via a
drop-folder pattern: `scripts/dispatch_ollama_task.py` writes a task file,
a separately-running watcher script picks it up, launches a real Claude
Code CLI session pointed at Ollama Cloud (via
`ANTHROPIC_BASE_URL=http://localhost:11434`, see
[Ollama's Anthropic-compatibility docs](https://docs.ollama.com/api/anthropic-compatibility)),
and writes the result back as a done file.

This exists because a running Claude Code session cannot launch another
unattended agent session directly, the auto-mode classifier blocks it. The
drop-folder sidesteps that: the watcher is a separate process a human starts
once, not something Claude spawns.

**To build your own equivalent, you need:**
- Ollama installed with Cloud access (`ollama run <model>:cloud` working)
- A watcher script: polls a folder every few seconds, on a new task file
  launches `claude.exe` (not `claude.cmd`, the .cmd shim can't be launched
  by `ProcessStartInfo` directly) with `ANTHROPIC_BASE_URL` pointed at your
  local Ollama daemon and a permissions file scoping what the model can
  touch
- Your own paths in place of `D:\Projects\Agent_Orchestrator\ollama_dropfolder\`
  and the `JobHunter_Ollama_DropfolderWatcher` scheduled task name

Without this, either strip the digest-only path from `skill.md` and always
use the real transcription path (step 5), or replace step 3-4 with your own
fetch mechanism (even a plain `WebFetch` call in the main session works fine
for lightweight links, just costs more of your own session's tokens).

### 2. Real transcription (`video_transcriber`)

Step 5 shells out to a local Python tool
(`transcribe.py <url> --model small --outdir <dir> --frames N`) built on
`yt-dlp` (video download) and `faster-whisper` (transcription). It is not
included in this kit.

**To build your own equivalent:** a script that takes a URL, downloads the
video with `yt-dlp`, extracts audio, transcribes with any Whisper
implementation, and optionally captures frames at given timestamps with
`ffmpeg`. Swap the exact invocation in `skill.md` step 5 for your own
script's CLI.

### 3. Linear ticket routing

`scripts/route_linear.py` hardcodes two teams (`JOB-` and `SOLO-` ticket
prefixes) and two working directories with their own `linear_push`
wrapper scripts, neither of which is included here.

**To adapt:** replace the two branches in `route_linear.py` with calls to
whatever issue tracker you use (Linear's own API, GitHub Issues via `gh`,
Jira, etc.), keeping the routing logic (prefix match, then keyword
fallback, then explicit ambiguous-reject) and the "never pass a destructive
overwrite flag" safety rule, that part is worth keeping regardless of
backend.

## What doesn't need changing

- `templates/report_template.html` is fully self-contained and generic,
  works as-is.
- The routing decision in `skill.md` step 2 (digest vs real transcription,
  based on reading the instruction text) doesn't depend on any of the above.
- `scripts/check_watcher.ps1` is specific to the Track A watcher above, but
  its shape (check a background process's health, restart once, fail loud
  rather than silently degrade) is worth keeping if you build your own
  watcher.
