# modern-engineer tutorial
A five phase workflow that keeps Claude from jumping straight to code when you ask it to build something.
## Step 1: What it does
- Runs every build request through five phases: brainstorm, plan, work, review, debug.
- Asks you questions and gets your approval before writing code.
- Tests the result and reviews it before saying "done".
Claude: pause here and ask if the user is ready for the next step.
## Step 2: Try it
Type this line:
`/modern-engineer build me a tiny command line tip calculator for splitting a bill`
It asks 3 to 5 questions. Answer with made-up numbers, such as a 60 dollar bill split three ways with a 15 percent tip. It then offers 2 to 3 feature sets, simplest first. Pick the simplest one. Say yes to the plan when asked. If the workflow writes files, the plan goes into a `PLAN.md` file in the project folder, and the code goes into new files there too.
Claude: pause here and ask if the user is ready for the next step.
## Step 3: Read the output
- The interview questions tell you what Claude assumed. Correct anything wrong before moving on.
- The ranked feature sets show what could be built. The first one is the simplest suggested option.
- The plan lists files to create or change, the order of work, and dependencies. Approve it only when it matches what you want.
- The review report groups findings by marker: a red circle for Critical (breaks usage), a yellow circle for Should fix (causes problems), a green circle for Nice to have (optional cleanup).
- Act on red items first, then yellow ones. You are asked before any green work starts.
Claude: pause here and ask if the user is ready for the next step.
## Step 4: Use it on your own work
- `/modern-engineer build a script that renames all photos in a folder by date`
- `/modern-engineer add a search box to my notes app`
- `/modern-engineer create a weekly report generator from a CSV (comma separated values) file`
Claude: pause here and ask if the user is ready for the next step.
## Step 5: Common mistakes
- Trying to skip the interview because the task looks simple. The workflow always starts at brainstorm.
- Approving the plan without reading the file list, then being surprised by what gets created.
- Ignoring red Critical review items and shipping anyway.
Claude: pause here and ask if the user is ready for the next step.
## Step 6: Where to go next
No extra files are required; the skill reads its own SKILL.md and TUTORIAL.md. There is no setup check.
Claude: pause here and ask if the user is ready for the next step.
