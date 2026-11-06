---
name: research-fanout
description: Research one question by splitting it into independent sub-questions, getting the user's approval on the split, fanning them out to parallel workers, then fanning in once (dedup sources, flag contradictions, rank, cite), verifying the top claims against their sources, and writing one cited report. Resumable from staged files. Use for "research X and pick one", "compare these options", multi-source surveys. Args: the question, optional --vanilla, optional --n <count>.
---

# /research-fanout

One question in, one cited report out. Every claim in the report carries a source. Workers stage their results on disk, so a crash loses no finished work.

## 0. Inputs
- The research question (required). Optional `--n <count>` (sub-question count proposal), optional `--vanilla`.
- **Mode**: if `~/.claude/CLAUDE.md` has an "Ollama Cloud delegation" section and `--vanilla` was not passed, read [ollama_routing.md](ollama_routing.md) now; it replaces sections 3, 5 and the fan-in executor in 6. Otherwise run vanilla mode as written here.
- `<skill>` is this skill's base directory (where this SKILL.md was loaded from).
- **Run folder** `<run>`: vanilla `./research/<YYYYMMDD>_<slug>/`; Ollama mode uses the path in ollama_routing.md. `<slug>` is 2 to 5 lowercase words from the question, joined by hyphens.

## 1. Resume check (always first)
- If `<run>/plan.md` exists, this is a resume: the split was already approved. Run `python <skill>/scripts/dedup_sources.py "<run>" --status`. It lists finished lanes (file ends with `STATUS: DONE`) and unfinished ones (missing or half-written).
- Tell the user in one line that the run resumes and how many sub-questions are left, then go to section 3 with the unfinished lanes only. Never re-run a finished lane.

## 2. Split and approval gate
- Split the question into sub-questions that are independent (a worker needs no other worker's answer) and together cover the question. Default 3, at most 6, or the `--n` value. For a "pick one" question, one sub-question finds the candidates and the rest judge them against named criteria, or each candidate gets its own lane when the candidates are already known.
- Write down the constraints the question carries (time range, region, license, budget, platform) and, for a decision, the ranking criteria.
- Show the user one short list and stop until they approve or edit it:
  ```
  Split for: <question>
  A. <sub-question>
  B. <sub-question>
  Criteria: <criteria, decision questions only>
  Approve, or edit / add / drop items.
  ```
- After approval write `<run>/plan.md`: question, constraints, criteria, and the approved lines with their letters. Nothing is dispatched before this file exists.

## 3. Fan out (vanilla)
- Fill [worker_prompt.md](worker_prompt.md) once per lane: the exact sub-question, the original question and constraints, output path `<run>/agent_<X>.md`, the run folder, a budget of about 25 tool calls, and the research rules. The research rules are the user's own research rules if their CLAUDE.md or a research skill defines them; otherwise "WebSearch to find, WebFetch to read, read files already in the run folder before fetching". Always add: "for GitHub data use the authenticated `gh` CLI, not the anonymous API" (the anonymous API rate-limits after a few lanes).
- Dispatch with the Agent tool, `subagent_type: general-purpose`, `model: sonnet`, foreground, **at most 2 calls per message**. Wait for both, then send the next wave. Never mention waves to the user.

## 4. Lane check and failures
- After the fan-out, run `dedup_sources.py "<run>" --status` again.
- A lane that is not done: retry once with a sharper prompt (name what was missing), then once with a different worker (vanilla: `model: opus`), then drop it. A dropped lane is named in the report's Gaps section. The run continues.

## 5. Dedup sources
- Run `python <skill>/scripts/dedup_sources.py "<run>"`. It writes `<run>/sources.md`: one numbered row per distinct source after URL normalization, with the lanes that cited it. These numbers are the citation numbers for fanin.md and the report.

## 6. Fan in, once
Vanilla: the main session does this. Read `plan.md`, `sources.md` and every finished `agent_<X>.md`, then write `<run>/fanin.md`:
- **Findings** per sub-question, each claim ending with its `[n]` from sources.md. Merge duplicates, keep the best-sourced wording.
- **Contradictions**: table of claim, what lane X says, what lane Y says, their sources. Two lanes differing on a number, date, license or capability counts.
- **Ranking** (decision questions): candidates scored against the plan's criteria, one line of reason each, cited.
- **Weak spots**: claims with a single source, sources that are vendor marketing, data older than the constraints allow.

## 7. Verify (Claude itself, every mode)
- Pick the claims to check: the key claims behind the top pick (up to 5), plus every row in the Contradictions table. For a non-decision question, the 3 claims the answer rests on plus the contradictions.
- Read the cited source for each (cache or run folder first, then WebFetch). Do not trust the ranking or the worker's quote.
- Write `<run>/verify.md`: claim, source `[n]`, verdict (confirmed / partly / not supported / source unreachable), one line of evidence. If the top pick fails verification, re-rank before writing the report.

## 8. Report
- Write `<run>/report.md`:
  1. **Answer** first: the pick or the direct answer, with why, in 3 to 6 bullets.
  2. **Findings** by sub-question.
  3. **Contradictions** and how verification settled each.
  4. **Gaps**: dropped lanes, unverified claims, what would change the answer.
  5. **Sources**: the numbered list from sources.md, only the ones cited.
  Every factual claim carries `[n]`. No claim without a source.
- If the report has several sections and real reading length, also build a self-contained `<run>/report.html` (headings, table of contents, readable type, no external assets) and open it (Windows `start "" "<path>"`, macOS `open`, Linux `xdg-open`).
- Chat reply: the answer in at most 5 bullets plus the report path. Never print lane counts, caps, waves or turn budgets.
