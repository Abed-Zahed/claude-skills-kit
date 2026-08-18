---
description: Batch-review social video links (Instagram/Facebook/YouTube) against per-link free-text instructions. Fetches via Ollama Cloud Track A by default, falls back to real transcription+screenshots when a link's instruction needs exact claim verification or a timestamp. Claude verdicts every link, conditionally creates a Linear ticket, rolls everything into one consolidated report.
---

# /video-review

## When to use
The user gives you a batch of video links (Instagram, Facebook, YouTube), each
paired with a free-text instruction, e.g.:

```
https://instagram.com/reel/abc123 - verify the claim they make about X, screenshot at 25s if true
https://youtube.com/watch?v=xyz - just give me a digest, no ticket
https://facebook.com/watch/def456 - if they're wrong about Y, make a JOB ticket
```

Links + instructions are pasted directly into the skill call. There is no
queue file, every invocation is self-contained.

## Pipeline

### 1. Parse the batch
Split the pasted input into `(link, instruction)` pairs. If a link has no
instruction, treat it as "digest only, no ticket" (the safe default).

### 2. Route each link
Read the instruction text yourself and classify it. This decision stays on
Claude, it's a cheap read of a short string, not worth delegating.

- **Needs real transcription** if the instruction asks to verify a specific
  claim precisely, quotes or paraphrases something exact that was said,
  or asks for a screenshot/frame at a timestamp.
- **Digest only** otherwise, a general "what is this about", "summarize it",
  "is this worth my time" type instruction.

### 3. Check the Ollama Track A watcher (before any digest-only dispatch)
Run:
```powershell
Get-ScheduledTask -TaskName JobHunter_Ollama_DropfolderWatcher | Select-Object TaskName, State
```
- If `Running`, proceed.
- If not, cycle it once:
  ```powershell
  Stop-ScheduledTask -TaskName JobHunter_Ollama_DropfolderWatcher -ErrorAction SilentlyContinue
  Start-ScheduledTask -TaskName JobHunter_Ollama_DropfolderWatcher
  ```
  Re-check state. If still not `Running`, **stop and tell the user** the
  watcher is down and needs manual attention (registering a new task needs an
  interactive credential prompt only they can supply). Do not silently fall
  back to fetching every digest-only link yourself, that defeats the point of
  the delegation and burns tokens without saying so.

Never invoke `run_ollama_batch.ps1` directly, self-invocation is blocked.
Only the watcher process runs it.

### 4. Dispatch digest-only links to Track A
For each digest-only link, write a task file to
`D:\Projects\Agent_Orchestrator\ollama_dropfolder\tasks\<slug>.txt`:
```
<WorkingDir, e.g. D:\Projects\Agent_Orchestrator>
glm-5.2:cloud
Fetch and summarize this video link for a content-review batch: <link>
Give: what the video claims/covers, tone, and anything that looks like a
factual claim worth double-checking. Plain ASCII only, no em dashes.
```
Poll `D:\Projects\Agent_Orchestrator\ollama_dropfolder\done\<slug>_done.txt`
for the result (reasonable timeout, e.g. 3-5 minutes per link; these run
sequentially through the watcher, a big batch takes longer, say so if it's
running long).

### 5. Real transcription for links that need it
For each verification-needed link:
```
py -3 D:\Projects\Shared_Content\video_transcriber\transcribe.py <url> --model small --outdir <dir> --frames N
```
- Always `py -3`, never bare `python`/`python3` (Job Hunter's venv lacks
  yt-dlp/faster-whisper; the system `py -3` has them).
- Use `--model small` for non-English audio, `tiny` can return empty
  transcripts on Arabic.
- Before requesting a screenshot at a specific timestamp, check the video's
  actual duration first (transcribe.py reports it); a timestamp past the end
  will fail. If the instruction's requested timestamp is out of range, say so
  in the verdict rather than silently skipping it.
- Convert any `/tmp/...`-style output path to a real Windows path before
  reading it with the Read tool.

### 6. Verdict (Claude only, never Ollama)
For every link, compare what was fetched/transcribed against that link's own
instruction and produce:
- **Claim status**: verified true / verified false / unverifiable (say why)
- **What the instruction asked for**: did you actually deliver it
  (screenshot taken, claim checked, etc.)
- **One-line verdict summary**

Sanity-check any tool/product name against known real names before calling a
claim unverifiable. Whisper systematically mis-transcribes "Claude" as
"Cloud" in tech-review content, if a transcript says "Cloud" in a context
that's obviously about an AI assistant, treat it as "Claude" and verify
accordingly.

### 7. Conditional Linear ticket
Only create a ticket when the link's own instruction explicitly asks for one
("make a ticket if...", "log this", "ticket it"). Never invent ticket-
worthiness yourself.

Route by instruction content:
- Mentions Job Hunter / CV / application context → Job Hunter, `JOB-`:
  ```
  python -m src.linear_push --update TICKET-ID -d "..."
  ```
  run from `D:\Projects\Job_hunter\`.
- Mentions Azure / chocolates / business context → Azure, `SOLO-`:
  ```
  python linear_push.py --update TICKET-ID -d "..." --project "Azure Projects"
  ```
  run from `D:\Projects\Azure\Azure_projects\`.
- If the instruction says to create a **new** ticket rather than update one,
  follow the same script's create path, still `--update`-style append
  semantics apply once it exists. **Never pass `--replace`.**

### 8. Output
- **1-3 links total**: give every verdict directly in the chat response, no
  file written.
- **More than 3 links**: build one consolidated report using
  `templates/report_template.html` (fill in one section per link: link,
  instruction, fetch method used, verdict, screenshot if any, ticket link if
  any), save to `reports/<date>_batch_review.html` in the current project
  directory (create `reports/` if missing), then open it:
  ```
  start reports/<date>_batch_review.html
  ```
  This is a plain local file, not a hosted Artifact.

## Known gotchas
- Bash's bare `python` resolves to the wrong venv, always use `py -3` for
  video_transcriber calls.
- `/tmp/...` paths need conversion to real Windows paths before Read can load
  them.
- Whisper mis-transcribes "Claude" as "Cloud", sanity-check before flagging a
  claim unverifiable.
- The watcher check is mandatory before every digest-only dispatch batch, not
  just the first link, it can go down mid-session.
