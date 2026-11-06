---
name: polish-prompt
description: 'Rewrites a rough or vague prompt into a clean, specific request for Claude Code. Flags missing context, condenses pastes, splits bundled tasks, recommends model and effort, and routes to a matching skill. Use when the user types /polish-prompt or asks to clean up a prompt before running it. Setup: none required; optional: the usage-live skill (for the Claude usage check), and for the Ollama add-on only: an "Ollama Cloud delegation" section in ~/.claude/CLAUDE.md (template: ~/.claude/ollama-addon/CLAUDE_SECTION.md in the kit), the OLLAMA_API_KEY env var (usage check via https://ollama.com/api/balance), and the Track A drop folder in the TRACK_A_DIR env var for headless delegation. The setup check only checks the add-on items when the CLAUDE.md section exists. Run /polish-prompt setup after installing.'
---

# /polish-prompt

## Setup check (first run)

When it runs: when the user types `/polish-prompt setup`, or automatically before the first real run when the marker file `.setup_ok` in this skill's own folder (the folder holding this SKILL.md, user or project install) does not exist.

| Item | Required or optional | How to check |
|---|---|---|
| Required dependencies | required | none required |
| usage-live skill | optional | `test -d ~/.claude/skills/usage-live` |
| Ollama add-on section | optional, add-on only | `grep -q "Ollama Cloud delegation" ~/.claude/CLAUDE.md` |
| OLLAMA_API_KEY | optional, add-on only | `test -n "$OLLAMA_API_KEY"` |
| TRACK_A_DIR | optional, add-on only | `test -d "$TRACK_A_DIR"` |

Check add-on rows only when the Ollama add-on section exists. Print OK / MISSING per item. If a REQUIRED item is missing, stop before the task, explain its purpose in one line, and offer step-by-step setup, asking before installing, editing settings.json, or creating files outside the skill folder. Never install silently. If only OPTIONAL items are missing, say in one line what is lost and continue.

When every required item passes, write today's date to the marker file (`date +%F > <this skill folder>/.setup_ok`), then continue the user's original request (if any).

Usage: `/polish-prompt <rough text>`.

Bypass prefixes: `*` means the prompt is already specific, execute as-is. `#` means a debugging session, keep the raw prompt.

## Step 0: Fast path

If the prompt starts with `*` or `#`, already names a file and an outcome, is a skill call, or is a plain factual question: skip Steps 1 to 3, print the output lines (Step 5) and execute without waiting.

## Step 1: Diagnose

Flag each one found:
- **Vague reference**: "the script", "it", "the bug" with no path or identifier.
- **Undefined outcome**: "fix it", "make it better" with no success criterion.
- **Missing context**: no current behaviour, nothing on what was already tried.
- **Scope creep**: unrelated tasks bundled together. Split them (Step 5).
- **Long paste**: logs or traces that should be condensed or referenced by path.
- **Wrong entry point**: an installed skill fits better.

## Step 2: Route to a skill

Check the session's available-skills list; route only to skills that are installed. Typical matches: building something new goes to a brainstorm or build skill, code review to `/code-review`, hooks and settings to `/update-config`, research to a research skill. On a match, the clean prompt becomes the skill's argument.

## Step 3: Rewrite

- Name files by path.
- State current and expected behaviour.
- One task per prompt.
- Replace vague verbs with observable outcomes ("returns X", "matches Y").
- Condense pasted logs to the 3 to 5 lines that matter, note where the full log is.

## Step 4: Settings

| Task type | Model | Effort | Thinking |
|---|---|---|---|
| File moves, renames, path or string fixes | haiku | low | off |
| Formatting, CSV or markdown edits | haiku | low | off |
| Status lookups, running a known command, quick factual lookup | haiku | low | off |
| Summarising a log or document | haiku | low | off |
| Explaining code or a concept | sonnet | low | off |
| Bug fix in one function, strategic decision | sonnet | medium | off |
| Simulation or numerical verification | sonnet | high | on |
| Architecture, multi-file refactor, security or cross-module design, new feature | opus | high | on |
| Reviewing a security or migration diff, consolidating conflicting reviews | opus | high | on |

Pick the lowest tier that can check its own output by inspection. Settings describe the work the main session itself does, not the overall difficulty of the task: if the hard pieces go elsewhere, Settings drop.

**Ollama add-on**: if `~/.claude/CLAUDE.md` has an "Ollama Cloud delegation" section, read [ollama_routing.md](ollama_routing.md) now and use it to decide who does each piece. Without that section, every piece runs on Claude and the Delegation lines are skipped.

## Step 5: Output and execute

**Single prompt.** Print only these lines, then wait for the go-ahead:

```
Settings: <model> / <effort> / thinking <on|off>
Delegation: ~X% (Ollama: <pieces>; Claude: <pieces>)    (Ollama add-on only)
Executing: <one sentence>
```

- The Delegation line appears only with the Ollama add-on, under 25 words.
- Nothing else: no polished prompt, no routing table, no cap notes. "show routing" prints the per-piece table.
- Fast-path and bypass prompts execute without waiting.
- Skill-routed: print the lines, then `/<skill> <clean prompt>`, and invoke it with the Skill tool.
- A Settings model other than the one running: dispatch a real subagent on that model (Agent tool `model` parameter) and put the effort level in its prompt as a rigor instruction. Do not imitate the tier yourself.
- After the result, with the add-on: `Delegation actual: ~X% (reason)` plus the one-line dispatch report from ollama_routing.md.

**Split prompts.** If Step 1 found scope creep, do not execute anything, even if the tasks look small or related. Claude never decides on its own to run a split "in one pass". Print:

```
## Issues found
- <problems in the original>

## Split into N prompts, send each separately:
1. <clean prompt>
   *Settings: <model> / <effort> / thinking <on|off>*
   *Delegation: ~X% (Ollama: <pieces>; Claude: <pieces>)*    (Ollama add-on only)
2. ...
```

If the user replies "run all", run them in order, and hold any prompt that needs the user's answer to an earlier one.

## Notes

- Infer intent through typos; never ask about obvious misspellings.
