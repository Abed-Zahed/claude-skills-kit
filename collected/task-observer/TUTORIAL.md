# task-observer tutorial
A helper that watches your work and quietly records ideas for improving skills.

## Step 1: What it does
- Watches a work session and notices patterns, corrections, and workflow ideas worth saving.
- Writes each one to an observation log file in your workspace folder, one entry at a time.
- At the end of the session, gives you a grouped summary of what it noticed.

## Step 2: Try it
In a chat with Claude Code, type:

`/task-observer watch this session and log one observation: "when I ask for a table, I always want dates in ISO format"`

Claude will create a `skill-observations/` folder in your workspace and add `log.md` with one numbered entry. It will also create `last-review-date.txt` containing `never`. Nothing leaves your machine.

Claude: pause here and ask if the user is ready for the next step.

## Step 3: Read the output
- `### Observation N: title` is the entry header. N is its number in the log.
- `**Status:** OPEN` means it has not been acted on yet.
- `**Issue:**` describes what happened.
- `**Suggested improvement:**` is the concrete change Claude proposes.
- `**Principle:**` is the general lesson, the most important field.
- `**Type:**` is `open-source` (useful to anyone) or `internal` (contains your specifics).
- Act on: anything marked OPEN that you agree with. You can ask Claude to act on it, or leave it for the next review.

Claude: pause here and ask if the user is ready for the next step.

## Step 4: Use it on your own work
- `/task-observer` then work normally: Claude logs silently as you go, then summarizes at the end of the session.
- "Review the observation log and tell me which OPEN entries cluster on one skill."
- "Update the notes skill based on observation 3" (explicit request, so Claude acts).

Claude: pause here and ask if the user is ready for the next step.

## Step 5: Common mistakes
- Assuming it only runs when called: it is meant to be invoked at the start of a task session, ideally via a CLAUDE.md instruction.
- Expecting Claude to apply fixes automatically: by default it logs and defers to a later review.
- Running it from a temporary checkout: the log lives at the stable project path, not the current working directory, so state survives.

Claude: pause here and ask if the user is ready for the next step.

## Step 6: Where to go next
- Add a CLAUDE.md instruction so task-observer activates at every session start. See the skill's SKILL.md for activation guidance.
- Keep the three reference files (weekly-review, skill-authoring, environments) in this skill folder; the skill reads them from there.

Claude: pause here and ask if the user is ready for the next step.
