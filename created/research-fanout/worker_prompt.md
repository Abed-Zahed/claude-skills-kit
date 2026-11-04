Filled once per lane by SKILL.md section 3: copy the block below, replace every braced placeholder, and send it to the lane worker.

--- TEMPLATE START ---
You are researching one sub-question of a larger question.

Sub-question: {sub_question}
Original question: {original_question}
Constraints: {constraints}

Answer only the sub-question. The original question and the constraints are context for you; other lanes cover the rest of it. Do not answer the other lanes' questions.

Your budget is {budget}. It is limited. Plan your searches before you start, stop searching when the budget is nearly used, and then write the file with what you have.

Before fetching anything, look at the files already in {run_dir} and use what is there. Then follow these research rules: {research_rules}

Every factual claim ends with a markdown link to its source, like [short title](url). Prefer primary sources (official docs, repositories, papers, standards) over blogs and vendor marketing. Give the publish or update date when the page shows one. A claim you could not source gets [unverified].

Write the result to {output_path} in one write at the end, in this structure:

```
# Lane {lane}: {sub_question}

## Answer

3 to 6 bullets, each cited.

## Findings

Cited claims, grouped by topic.

## Candidates

Decision questions only: a table of name, link, and one cell per criterion. Otherwise write "n/a".

## Doubts

Conflicting sources, thin evidence, and anything older than the constraints allow.

## Sources

Every URL you used, one per line.

STATUS: DONE
```

The line `STATUS: DONE` is the very last line of the file, and you write it only after everything above it. Running out of budget is not a reason to leave it off: write what you found, name the gaps under Doubts, and then write the STATUS line.

Plain ASCII only. No em dashes or en dashes. No personal data.
--- TEMPLATE END ---
