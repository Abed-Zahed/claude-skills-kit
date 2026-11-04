---
name: video-review
description: Batch-review social video links (Instagram, Facebook, YouTube) against per-link free-text instructions. Fetches page text and metadata with WebFetch or yt-dlp when installed, transcribes locally with yt-dlp plus a Whisper build for exact claim checks or timestamps, takes screenshots with ffmpeg, and writes one verdict per link plus a consolidated report. Use when the user pastes several video links with review instructions or points to a links file. Optional ticket creation only when a ticket tool or MCP server is configured.
---

# /video-review

## When to use
Use this skill when the user gives a batch of video links (Instagram, Facebook, YouTube), each paired with a free-text instruction. The user may paste the pairs or give a path to a plain text file with one pair per line.

A missing instruction means "digest only, no ticket".

## Optional Ollama Cloud add-on
If `~/.claude/CLAUDE.md` contains an "Ollama Cloud delegation" section, read `ollama_addon.md` next to this file and follow its routing before the vanilla fetch steps. Otherwise use the vanilla pipeline below.

## Vanilla pipeline

1. Parse the batch.
   Split the input into `(link, instruction)` pairs. If the input is a file path, read the file. Treat blank lines as separators.

2. Classify each link.
   Read the instruction and decide:
   - Needs exact verification: it asks to check a specific claim precisely, quote or paraphrase exact words, or take a screenshot or frame at a timestamp.
   - Digest only: it asks for a summary, topic, tone, or general opinion.

3. Fetch page text and metadata.
   Use WebFetch on the link. If yt-dlp is installed, also run:
   `yt-dlp --dump-single-json --no-warnings <link>`
   Use the result for title, author, description, duration, and other available metadata. Keep temporary files in a runtime temporary directory.

4. Handle exact verification.
   If the instruction needs exact claim checking or a timestamp:
   - Download audio or video with yt-dlp if the user has it.
   - Transcribe with a Whisper build the user has installed. Use a multilingual model when the audio is not English.
   - Check the real duration before taking a screenshot.
   - Take a screenshot with ffmpeg:
     `ffmpeg -ss <seconds> -i <video-file> -frames:v 1 <output-file>`
   - If a requested timestamp is past the end, say so in the verdict. Do not silently skip it.
   - If yt-dlp or Whisper is missing, state the limitation in the verdict instead of guessing.

5. Write a verdict for every link. This step is always done by Claude, never by a fetch helper.
   For each link include:
   - Claim status: verified true, verified false, or unverifiable, with the reason.
   - Instruction fit: did the work deliver what that link's instruction asked for.
   - One-line verdict summary.

   Sanity-check product and tool names before calling a claim unverifiable. Speech-to-text tools can mishear product names.

6. Create a ticket only when the link's own instruction explicitly asks for one.
   Use a configured ticket tool or MCP (Model Context Protocol) server. Do not invent ticket identifiers, team identifiers, or project identifiers. If no ticket tool is configured, state that the ticket was not created.

7. Output.
   - For 1 to 3 links, give every verdict in the chat response.
   - For more than 3 links, write one consolidated Markdown report with one section per link: link, instruction, fetch method, verdict, screenshot path if any, and ticket reference if any. Save it to `reports/YYYY-MM-DD_batch_review.md` in the current working directory, create `reports/` if missing, and tell the user the path.

## Gotchas
- Use the Python interpreter that has yt-dlp and Whisper installed. Do not assume `python` and `python3` point to the same environment.
- Convert temporary paths to paths your file reader can open.
- Check video duration before requesting a screenshot at a timestamp.
- The Ollama add-on is optional. The vanilla path must work with stock Claude Code, with no Ollama, no hooks, and no MCP servers.
