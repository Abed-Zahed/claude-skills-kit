# improve-system tutorial
Review and clean up the notes Claude keeps about your project, so future sessions work better.

## Step 1: What it does
- Checks the project memory folder that Claude Code uses to remember things about your project.
- Finds notes that are stale, conflicting, duplicated, or missing.
- Can save new lessons and improve other skills, with your confirmation before any change.

Claude: pause here and ask if the user is ready for the next step.

## Step 2: Try it
Type this to run the setup check first:

`/improve-system setup`

It prints a checklist of required items with OK or MISSING, then writes a small marker file named `.setup_ok` inside the skill's own folder so it does not check again every run.

Claude: pause here and ask if the user is ready for the next step.

## Step 3: Read the output
- Each checklist line names an item and shows OK or MISSING. MISSING on a required item stops the task.
- The required item is the project memory folder at `~/.claude/projects/<project>/memory/`. If it is missing, the skill explains why it matters and offers to set it up, asking you before creating anything.
- Optional items: none here, so nothing else can block you.
- Later runs (for example `audit`) report findings as keep, merge, delete, or update, and apply changes only after you confirm.

Claude: pause here and ask if the user is ready for the next step.

## Step 4: Use it on your own work
- `review your work` runs skill-review mode on the skill used last in the conversation.
- `what did we miss` runs historical-review mode and mines recent sessions for unsaved lessons.
- `find duplicates` runs audit mode on your memory notes.

Claude: pause here and ask if the user is ready for the next step.

## Step 5: Common mistakes
- Skipping setup: run `/improve-system setup` once so the required memory folder is confirmed.
- Unclear wording: vague phrases may not match a mode, so the skill asks which mode you want. Answer with one of audit, skill-review, experience, historical-review, or foundation.
- Expecting silent edits: every mode applies changes only with your confirmation, so approve each one.

Claude: pause here and ask if the user is ready for the next step.

## Step 6: Where to go next
- No optional setup items exist, so setup unlocks nothing extra beyond the required memory folder.
- Re-run `/improve-system setup` any time to re-check items and refresh the marker file.
- Try foundation mode with `what are we missing` to fill gaps in brand voice, audience, offers, processes, and key people.

Claude: pause here and ask if the user is ready for the next step.
