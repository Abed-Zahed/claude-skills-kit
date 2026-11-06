# video-review tutorial
Review a batch of social video links against your own written instructions, one verdict per link.
## Step 1: What it does
- Takes several video links (Instagram, Facebook, YouTube), each with a free-text instruction you write.
- Reads page text and metadata, and can check exact claims, quotes, and timestamps when optional tools are installed.
- Gives one verdict per link, and a single report when you send more than three links.
Claude: pause here and ask if the user is ready for the next step.
## Step 2: Try it
Type this practice run. The link is a real, harmless public video, not made-up data; no optional tools are needed:
`/video-review https://www.youtube.com/watch?v=dQw4w9WgXcQ digest the topic and tone only`
This asks for a digest only, so page-text review runs with built-in WebFetch. Nothing is written to disk for a single link; verdicts appear in chat.
Claude: pause here and ask if the user is ready for the next step.
## Step 3: Read the output
- Claim status: verified true, verified false, or unverifiable, with the reason. "Unverifiable" means it could not be confirmed, not that it is false.
- Instruction fit: did the work deliver what that link's instruction asked for.
- One-line verdict summary: the short takeaway.
- For more than three links you also get a report at `reports/YYYY-MM-DD_batch_review.md` with link, instruction, fetch method, verdict, screenshot path, and ticket reference.
Act on any "unverifiable" by checking the source yourself before relying on it.
Claude: pause here and ask if the user is ready for the next step.
## Step 4: Use it on your own work
- `/video-review https://www.youtube.com/watch?v=abc123 summarize the main topic and tone`
- `/video-review Check the claim at 2:10 that the tool is free, and screenshot that frame. https://www.youtube.com/watch?v=abc123`
- `/video-review review the pairs in links.txt` (one link and instruction per line)
Claude: pause here and ask if the user is ready for the next step.
## Step 5: Common mistakes
- Expecting exact claim checks or screenshots without yt-dlp, ffmpeg, or a Whisper build (speech-to-text tool) installed. The verdict states the limitation instead.
- Forgetting that a missing instruction means digest only, with no ticket.
- Assuming a ticket gets created. It only happens when that link's instruction explicitly asks and a ticket tool or MCP (Model Context Protocol) server is configured.
Claude: pause here and ask if the user is ready for the next step.
## Step 6: Where to go next
Optional setup unlocks more. Run `/video-review setup` to check each item:
- yt-dlp and ffmpeg: enable metadata, downloads, and screenshots.
- Whisper build: enables transcription for exact claim checks and timestamps.
- Ticket tool or MCP server: enables ticket creation.
- Ollama add-on section, TRACK_A_DIR env var, watcher scheduled task: optional extras.
Claude: pause here and ask if the user is ready for the next step.
