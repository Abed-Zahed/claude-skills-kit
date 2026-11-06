# tailor-jd Ollama add-on

Load this file only when ~/.claude/CLAUDE.md contains a section named "Ollama Cloud delegation". If that section is absent, ignore this file and run the vanilla SKILL.md only.

Read the delegation table in that section. The writer model is the one named in the table's routine row. Never hardcode a model name in a prompt, command, or saved file.

## Drafting

Step 4 of SKILL.md is drafting work and goes to an Ollama Cloud writer. Steps 2 (fit score) and 3 (ATS baseline and keyword list) stay on Claude.

For each JD, build a prompt with:
- the master CV text,
- the JD text and title,
- the output format from step 7,
- the honesty constraints from steps 4 and 6.

Ask for a markdown draft. Plain ASCII only.

Send the prompt by one of these routes:

1. Track A drop folder. Write a task file to <TRACK_A_DIR>/tasks using the task file format in ~/.claude/ollama-addon/README.md, section Task file format. Poll for the matching done file. Do not redesign the format.
2. Local Ollama HTTP API. POST to http://localhost:11434/api/chat with stream false:

curl -s http://localhost:11434/api/chat -H "Content-Type: application/json" -d @request.json

request.json must contain "model" set to the routine row model, "stream": false, and a messages array with the prompt. Build the JSON with a proper encoder, not string concatenation.

## Fan-out

For N JDs, run up to the lane cap in <TRACK_A_DIR>/max_parallel.txt (default 3). Queue the rest and start the next when a lane frees. Do not exceed the cap.

## Required re-checks

Claude always re-runs step 5 (ATS coverage after) and step 6 (honesty audit) itself against the returned draft before showing anything. Before steps 5 and 6, Claude re-verifies that every quoted evidence line and every claim in the draft appears in the master CV. Discard any line that fails. Never show raw writer output.

## Data handling

CV content is personal data. Only send it to models and endpoints the user has approved. If the table is missing, the endpoint is not approved, or approval is unclear, stop and ask. CV text goes only to the Ollama endpoint the user approved, nowhere else. Delete any temp request file after the call.
