### Ollama Cloud delegation

Example roster: edit the model names in this table to match the models your Ollama Cloud plan can call. The table is the single source of model names; do not hardcode them in skills or add-on routing files.

Every delegation prompt opens with:

```
Output plain ASCII only. Never use em dash (U+2014) or en dash (U+2013), use a comma, period, or the word 'to' instead. No other non-ASCII punctuation unless explicitly part of the requested content.
```

Add any project rule that applies.

| Category | Writer | Reviewer (never the writer) | Rigor | Rotate to (attempt 3) |
|---|---|---|---|---|
| Routine code, docs, research, scaffolding, Track A code tasks | `deepseek-v4.1-flash:cloud` | `glm-5.3:cloud` | R2 | `glm-5.3-flash:cloud` |
| Boilerplate, reformatting, first-draft text | `deepseek-v4.1-flash:cloud` | inspect it yourself | R1 | `glm-5.3-flash:cloud` |
| High-stakes code (security, 3+ files, migration, billing, payments) | `glm-5.3-flash:cloud` @ R3 | `deepseek-v4-pro:0813-cloud` | R3 | `deepseek-v4-pro:0813-cloud` |
| Math, STEM, scoring, numeric correctness | `deepseek-v4-pro:0813-cloud` | `glm-5.3:cloud` | R3 | `glm-5.3-flash:cloud` |
| Final review, testing verdicts, ticket review | n/a | `glm-5.3:cloud` (`deepseek-v4-pro` for math or migrations) | R3 | `deepseek-v4-pro:0813-cloud` |

Rigor:
- R1 mechanical: thinking off.
- R2 default: "think it through, state assumptions, flag ambiguity".
- R3 max: step by step plus a self-flagged uncertainty list.

- **Never delegate:** git/deploy/merge/PR actions; physics/simulation correctness (mandatory multi-layer review); data belonging to anyone other than the user; anything under `.claude/**` (Claude's to edit).
- **Size floor:** above XS goes to Ollama by default; skip only when the round trip honestly costs more than the fix.
- **Failure ladder:** attempt 1 default, attempt 2 same model with a sharper prompt and rigor up one, attempt 3 rotate, attempt 4 ask the user. Timeouts rotate immediately. Never silently self-execute after all fail.
- **Turn caps and long tasks:** default 25 turns and 8 minutes, deepseek models 60 turns and 20 minutes; explicit `-MaxTurns` and `-TimeoutMinutes` win. A task that will plausibly pass about 60 turns is split, or handed to a Cline handover instead (Cline: an open-source VS Code coding agent that can run on the same Ollama Cloud models in an interactive session; Claude writes the handover file, you run it).
- **Explicit-call-only expensive model:** the most expensive model in the roster (`kimi-k3:cloud` in this example) is called only when the user names it, or when Claude recommends it and the user approves, for one end-of-project review. Never default, never fallback.
- **Security/policy reviews:** paste the project's standing rules into the reviewer prompt; the reviewer cannot infer them.
- **Report every dispatch:** after the result, print exactly this one line: `Delegated: <model> @ <rigor> x<calls>, escalated: no|yes, attempts: <N>`.
- **Bare `ollama run`** cannot reach MCP tools, Skills or hooks; Track A (`run_ollama_batch.ps1`) can when the worker settings allow it.
