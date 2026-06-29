---
name: polish-prompt
description: Analyze and rewrite a rough or vague prompt into a clean, specific, actionable request for Claude Code. Flags missing context, condenses pasted text, recommends model/effort settings, routes to the right skill, and auto-executes single clean outputs.
---

# /polish-prompt

Improve any rough, half-formed, or vague prompt before sending it. Works on:
- Requests with unclear scope ("fix the thing", "make it better")
- Long pastes that need condensing
- Prompts missing critical context (file paths, what already failed, expected output)
- Requests that would benefit from a model or effort recommendation
- Requests that should be routed to another skill instead of sent directly

---

## How to use

Type `/polish-prompt` followed by your rough text.

```
/polish-prompt
can you fix the bug in my script and also make the output better and add some tests maybe
```

---

## Bypass prefixes

Prefix your prompt with one of these to skip polishing entirely:

| Prefix | Meaning |
|---|---|
| `*` | Skip — prompt is already specific, execute as-is |
| `#` | Skip — debugging session, preserve raw prompt |

Example: `* fix the null pointer in src/auth.js line 42`

---

## What this skill does

### Step 0 — Fast-path check

Skip all diagnosis and execute immediately if ANY of these are true:
- Prompt starts with `*` or `#`
- Prompt already names a specific file path and a specific outcome
- Prompt is a direct skill invocation (starts with `/`)
- Prompt is a simple factual question with no ambiguity

### Step 1 — Diagnose the rough prompt

Flag each issue found:
- **Vague reference**: "the script", "the bug", "it" with no file path
- **Undefined outcome**: "make it better" with no success criterion
- **Missing context**: no mention of what failed, what was tried, expected output
- **Scope creep**: multiple unrelated tasks bundled (split them)
- **Long pasted text**: raw logs/traces that should be summarised
- **Missing effort/model signal**: complex tasks benefit from explicit flags
- **Wrong entry point**: prompt should invoke a specific skill first

### Step 2 — Skill routing check

| If the prompt is about... | Route to |
|---|---|
| Building, creating, or starting anything new | `/modern-engineer` |
| A strategic or product decision needing outside perspective | `/ask-the-board` |
| Saving an article, link, transcript, PDF, or note | `/ingest-resource` |
| Feedback from a specific person or a panel review | `/internal-focus-group` |
| Reviewing code quality, bugs, or a PR diff | `/code-review` |
| Verifying a fix works in the running app | `/verify` |
| Running or launching the app | `/run` |
| Researching current information or scraping a URL | `/web-scraping` |
| Reviewing work or improving process | `/improve-system` |
| Configuring hooks or settings.json | `/update-config` |
| Claude API usage, model IDs, pricing | `/claude-api` |

### Step 3 — Rewrite the prompt

- Name specific files by path
- State current behaviour and expected/desired behaviour
- Limit scope to one task
- Replace vague verbs with observable outcomes
- Condense pasted logs to 3-5 most relevant lines
- For skill-routed prompts, write as `/<skill> <clean-prompt>`

### Step 4 — Recommend settings

- Bug fix in one function: sonnet, medium
- Design decision or architecture: opus, high, think
- Refactor across multiple files: opus, high, think
- Quick lookup or explanation: sonnet, low
- New feature (routes to /modern-engineer): opus, high, think

### Step 5 — Auto-execute decision

- **Single prompt**: print `Settings: [model] / [effort] / thinking [on|off]` (from Step 4), then print `Executing: [one-sentence summary]`, then execute inline. User sees settings + summary + result, not the full polished prompt.
- **Multiple prompts (scope creep)**: stop. Print numbered list. Let user send each separately.
- **Skill-routed**: invoke the skill directly using the Skill tool.

### Step 6 — Output format (multiple prompts only)

```
## Issues found
- [bullet list]

## Split into N prompts — send each separately:
1. [first clean prompt]
2. [second clean prompt]
```

---

## Attribution

Bypass prefix concept and fast-path approach inspired by [claude-code-prompt-improver](https://github.com/severity1/claude-code-prompt-improver) (MIT).
