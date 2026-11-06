# task-status tutorial
See which background agent tasks you dispatched, and which are still open, by reading a local log.

## Step 1: What it does
- Lists every Agent dispatch from this and earlier sessions, with its description and prompt.
- Marks each one as pending (no completion logged) or finished (a completion was logged).
- Reads a local log file only, so it costs nothing and needs no network or cloud service.

Claude: pause here and ask if the user is ready for the next step.

## Step 2: Try it
Type this exact command for a safe practice run. It reads the log and prints recent dispatches. It writes no files.

```
/task-status
```

If the log is empty because the logging hook is not installed yet, the skill runs its setup check first. It will show OK or MISSING for each item and offer to install the missing pieces. Say yes to install, then run `/task-status` again.

Claude: pause here and ask if the user is ready for the next step.

## Step 3: Read the output
- Each line is one dispatch: timestamp, description, prompt (shortened), model, and subagent type.
- Status shows dispatched, async_launched (background), completed (foreground), or finished.
- An agent ID links a dispatch to its completion line. A dispatch with no matching completion is pending.
- A pending item means only that no completion was logged. It may still be running, or the session may have died first.

Claude: pause here and ask if the user is ready for the next step.

## Step 4: Use it on your own work
- "What agent tasks did I dispatch in the last three days, and which are still open?"
- "Show every dispatch from this session with its outcome."
- "I hit my spend limit mid-run. What background agent work was in flight?"

Claude: pause here and ask if the user is ready for the next step.

## Step 5: Common mistakes
- Expecting results without the hook: the logging hook is required, and without it the log stays empty.
- Treating every pending item as still running: the log cannot tell "running" from "interrupted".
- Forgetting the time window: the default is 24 hours. Use the wider window or the full history option to see older work.

Claude: pause here and ask if the user is ready for the next step.

## Step 6: Where to go next
- Install the required setup so the log fills up: the Windows PowerShell 5.1+ shell, the logging hook script, and the settings entries.
- Check setup any time with `/task-status setup`.
- For live status of background sessions, run `claude agents` in a terminal.

Claude: pause here and ask if the user is ready for the next step.
