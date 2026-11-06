# ask-the-board tutorial
Get advice on a decision from two made-up expert advisors, each speaking in their own voice.

## Step 1: What it does
- Recommends two advisors that fit your situation, such as creators for product questions or senior professionals for career questions.
- Consults those advisors on a decision and writes each one's honest take in their own style.
- Ends with where they agree, where they disagree, and one concrete action.

Claude: pause here and ask if the user is ready for the next step.

## Step 2: Try it
Type this exactly, using made-up input:

`/ask-the-board I run a small handmade candle shop and I cannot decide whether to start posting short videos to grow sales. Should I?`

This is consult mode. If no board exists yet, the skill may first research candidates with a web tool and save the board to `~/.claude/knowledge/board/`. Nothing is charged and no personal data is needed. A marker file `.setup_ok` may be written in the skill's own folder.

Claude: pause here and ask if the user is ready for the next step.

## Step 3: Read the output
- Advisor header: each advisor's name and title or platform, so you know who is speaking.
- Quoted take: that advisor's opinion in their own voice. Expect the two to differ.
- They agree on: the shared ground both advisors reached.
- They disagree on: where they split and why that matters.
- What you should actually do: the skill's single concrete recommendation. Act on this one first.

Claude: pause here and ask if the user is ready for the next step.

## Step 4: Use it on your own work
- `/ask-the-board Who should be on my board for a career move from support into engineering?`
- `/ask-the-board I have two job offers, one stable and one risky startup. Which fits someone three years into their career?`
- `/ask-the-board Should I raise prices on my freelance design work or keep them low to win more clients?`

Claude: pause here and ask if the user is ready for the next step.

## Step 5: Common mistakes
- Asking a vague question. Name the decision and the context so the right advisors are chosen.
- Expecting agreement. Advisors are meant to disagree where they genuinely would.
- Skipping the profile. Without it, recommendations are generic rather than fitted to you.

Claude: pause here and ask if the user is ready for the next step.

## Step 6: Where to go next
- Optional setup: fill the "User profile" section in the skill's SKILL.md with your role, years of experience, location, goals, and values. This makes advisor picks sharper.
- Run `/ask-the-board setup` to see the setup check with OK or MISSING per item. No items are required, so it continues either way.

Claude: pause here and ask if the user is ready for the next step.
