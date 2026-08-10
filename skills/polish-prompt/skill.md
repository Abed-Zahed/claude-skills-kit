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

### Step 5 — Ollama Cloud delegation check

Delegable: a scoped code fix, research/log summarization, boilerplate, or first-draft task, not touching security-sensitive code, real PII, git/deploy actions, final accuracy-critical output, or architecture decisions. Not eligible, keep on Claude, no matter how small it looks.

Tool-access gap (any Claude Code-specific tool, skill, or hook Ollama can't reach: MCP tools like Exa/Firecrawl, Artifact, Workflow, skill invocations, hooks): Claude always runs it itself. Delegate the post-fetch synthesis only when the fetched content is large (a crawl, a long doc, a bulk log) and the remaining work is mechanical drafting. Small fetches or judgment calls stay on Claude.

If delegable: draft one precise, fully-scoped prompt, run it via the best-fit Ollama Cloud model, review the result. Apply directly with small fixes made in-place, or re-delegate once with a sharper prompt if substantially wrong, then finish it directly rather than loop again. Testing and any git action always stay on Claude.

### Step 6 — Auto-execute decision

- **Single prompt**: print `Settings: [model] / [effort] / thinking [on|off]` (from Step 4), then print `Executing: [one-sentence summary]`. If settings name the model the main agent is already running as, execute directly. If settings name a different model (opus, haiku, fable), dispatch a real subagent on that exact model via the Agent tool's `model` parameter, the main agent approximating that tier itself is not a substitute. Encode effort/thinking into the subagent's task prompt (no separate parameter for it exists). If Step 5 found the task delegable, run its delegation loop instead of drafting directly. After the result, print `Delegation: ~X% (reason)`; at 0%, name the specific reason (security-sensitive, PII, git action, architecture judgment, tool-gap with a small/judgment remainder, or too small to be worth delegating). User sees settings + summary + result + delegation line, not the full polished prompt, not the dispatch mechanics.
- **Multiple prompts (scope creep)**: stop, do not execute anything. This holds even if the tasks feel small, related, or there are only two or three. Do not rationalize past it, "I'll just run them in one pass" is exactly the failure mode this step exists to block. Print the numbered list, one `Settings:` line per item (from Step 4, not optional), let the user send each separately.
- **Skill-routed**: invoke the skill directly using the Skill tool.

### Step 7 — Output format (multiple prompts only)

```
## Issues found
- [bullet list]

## Split into N prompts — send each separately:
1. [first clean prompt]
   Settings: [model] / [effort] / thinking [on|off]
2. [second clean prompt]
   Settings: [model] / [effort] / thinking [on|off]
```

---

## Attribution

Bypass prefix concept and fast-path approach inspired by [claude-code-prompt-improver](https://github.com/severity1/claude-code-prompt-improver) (MIT).
