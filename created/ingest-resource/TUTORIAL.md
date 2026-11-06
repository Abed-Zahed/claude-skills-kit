# ingest-resource tutorial
Save any article, link, transcript, PDF (Portable Document Format), or note to the right folder with a structured summary and cross-links.

## Step 1: What it does
- Reads external content (a link, a file, or pasted text) and decides whether it is stable reference material or active project work.
- Adds a summary block at the top of the file plus cross-links to related notes.
- Saves a dated markdown file in your own Claude folder so you can find it later.

Claude: pause here and ask if the user is ready for the next step.

## Step 2: Try it
Type this with made-up input:

`/ingest-resource A short note: our team meets Fridays and we track ideas in a shared doc.`

If the classification is unclear, Claude will ask whether it belongs in `knowledge/` or `projects/`. The skill creates `~/.claude/knowledge/` or `~/.claude/projects/` on first save after asking you. Files land under a kebab-case topic folder, named with the date and a title.

Claude: pause here and ask if the user is ready for the next step.

## Step 3: Read the output
- The saved path tells you where the file went; open it to confirm.
- The classification decision (knowledge or projects) explains why it was filed there.
- Key concepts are the main ideas pulled from the content.
- Wikilinks are the related notes it connected; follow them to see the link.
- Related suggestions are 1 to 2 existing notes worth cross-linking; add them if useful.

Claude: pause here and ask if the user is ready for the next step.

## Step 4: Use it on your own work
- `/ingest-resource https://example.com/article-on-planning`
- `/ingest-resource Here is the transcript of our launch meeting: ...`
- `/ingest-resource Paste a PDF or paper and summarize it for my research folder.`

Claude: pause here and ask if the user is ready for the next step.

## Step 5: Common mistakes
- Skipping the classification when unsure: answer Claude's question so the file lands in the right place.
- Forgetting the summary block matters: it is what makes the note findable later.
- Assuming folders exist already: the skill creates them, so no manual setup is needed.

Claude: pause here and ask if the user is ready for the next step.

## Step 6: Where to go next
No required or optional setup items exist, so nothing extra is needed to unlock more. If you want to confirm the checklist, run `/ingest-resource setup`, which prints OK or MISSING per item and writes a marker file with today's date.

Claude: pause here and ask if the user is ready for the next step.
