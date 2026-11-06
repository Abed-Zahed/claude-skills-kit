# polish-prompt tutorial
Rewrites a rough prompt into a clean, specific request before Claude Code runs it.
## Step 1: What it does
- Finds gaps in your prompt, such as vague references, missing context, and bundled tasks.
- Rewrites it with file paths, current and expected behaviour, and one task only.
- Recommends a model and effort level, and routes to a matching installed skill.
Claude: pause here and ask if the user is ready for the next step.
## Step 2: Try it
Type this made-up prompt:
`/polish-prompt make the script better`
On first use you also see a one-time setup checklist and a tutorial offer. This does not write any files. It only prints three lines (Settings, Executing, and Delegation if the Ollama add-on is present) and then waits.
Claude: pause here and ask if the user is ready for the next step.
## Step 3: Read the output
- `Settings: <model> / <effort> / thinking <on|off>`: the model and effort level picked for the work, plus whether extended thinking is on.
- `Delegation: ...` (only with the Ollama add-on): the share of pieces sent to Ollama versus Claude.
- `Executing: <one sentence>`: what will run next. Give the go-ahead or correct it.
- If your prompt bundles tasks, expect an "Issues found" list and a numbered split instead of execution. Send each clean prompt separately.
Claude: pause here and ask if the user is ready for the next step.
## Step 4: Use it on your own work
- `/polish-prompt the parser breaks on empty lines in src/parse.py, it should return an empty list`
- `/polish-prompt # the build fails after my edit, keep the raw prompt`
- `/polish-prompt * rename report.csv to summary.csv and update the path in scripts/load.py`
Claude: pause here and ask if the user is ready for the next step.
## Step 5: Common mistakes
- Pasting a huge log instead of the 3 to 5 lines that matter and a path to the full log.
- Bundling unrelated tasks; the skill splits them and will not run them in one pass.
- Using `*` or `#` when the prompt is still vague; bypass prefixes skip the rewrite.
Claude: pause here and ask if the user is ready for the next step.
## Step 6: Where to go next
Nothing is required to start. Optional items unlock more:
- The usage-live skill (external skill, not part of this kit) adds the Claude usage check.
- The Ollama add-on (a section in `~/.claude/CLAUDE.md`, the `OLLAMA_API_KEY` environment variable, and the `TRACK_A_DIR` drop folder) adds delegation lines and headless delegation.
Run `/polish-prompt setup` to check each item.
Claude: pause here and ask if the user is ready for the next step.
