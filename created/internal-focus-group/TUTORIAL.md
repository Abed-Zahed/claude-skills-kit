# internal-focus-group tutorial
Run a panel of simulated people, each with their own voice, to pressure-test a question or decision.
## Step 1: What it does
- Each panel member is an agent (an automated worker) that reads a profile file built from that person's notes and speaks in their voice.
- You can call one member alone, or the whole panel at once, and they run in parallel.
- All responses come back as one synthesized report with consensus, disagreements, and a recommended action.
Claude: pause here and ask if the user is ready for the next step.
## Step 2: Try it
First create one practice member profile at `~/.claude/focus-group/practice/profile.md` with these five lines:
```
Name: Practice Member
Role: Team operations lead
Lens: Meeting load and team focus
Voice: Direct, practical, skeptical of extra meetings
Notes: Prefers fewer recurring meetings with clear written updates
```
Then run this made-up example:
`/internal-focus-group Should our team switch from weekly to daily status meetings?`
The profile is made-up; no paid services or personal data are needed. The skill only builds a report; it does not write files to your work folders.
Claude: pause here and ask if the user is ready for the next step.
## Step 3: Read the output
- Each section is one member: their name, their role or lens (the angle they judge from), and a quoted response in their voice.
- **Consensus** lists what every member agrees on. High agreement means the answer is likely robust.
- **Disagreements** shows where members split and why. Treat these as open risks, not errors.
- **Recommended action** is the synthesis: the concrete next step to take. Act on this line first, then read the sections above to understand why.
Claude: pause here and ask if the user is ready for the next step.
## Step 4: Use it on your own work
- `/internal-focus-group Which of these two pricing plans is easier for new customers to understand?`
- `Ask [member name] what they think about our new onboarding email.`
- `/internal-focus-group We are cutting the feature list for launch. What should stay and what should go?`
Claude: pause here and ask if the user is ready for the next step.
## Step 5: Common mistakes
- Calling the panel with zero member profiles. At least one profile is required; setup will stop and offer to help.
- Expecting agreement. Members are built to disagree honestly; use the disagreements section, do not skip it.
- Using the panel for facts. It reflects the profiles you gave it, so thin notes give thin answers.
Claude: pause here and ask if the user is ready for the next step.
## Step 6: Where to go next
- Optional: install the ingest-resource skill (`~/.claude/skills/ingest-resource/SKILL.md`) to build profiles from notes, transcripts, or interviews. Without it you lose the easy profile-building path.
- Run `/internal-focus-group setup` to add a new member: gather notes, run `/ingest-resource`, then save the profile to `~/.claude/focus-group/<name>/profile.md`. Members are picked up automatically.
Claude: pause here and ask if the user is ready for the next step.
