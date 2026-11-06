---
name: task-status
description: 'Report the status of Agent-tool subagent dispatches from this and prior sessions by reading the local agent_task_log.jsonl. Use after an interruption, spend-limit stop, crash, or fresh session to recover what background agent work was in flight. Shows pending versus finished dispatches with results. Zero API cost, reads a local log only. Works on stock Claude Code; the log is optional and may be empty until the logging hook is installed. Setup: required: Windows PowerShell 5.1+, the logging hook hooks/log_agent_task.ps1 copied to ~/.claude/hooks/, and the hooks/settings-snippet.json entries merged into ~/.claude/settings.json (check: grep for log_agent_task in ~/.claude/settings.json). Without the hook the log stays empty, so treat it as required. Run /task-status setup after installing.'
---

# /task-status

## Setup check (first run)

When it runs: when the user types `/task-status setup`, or automatically before the first real run when the marker file `.setup_ok` in this skill's own folder (the folder holding this SKILL.md, user or project install) does not exist.

| Item | Required or optional | How to check |
|---|---|---|
| Windows PowerShell 5.1+ | required | `powershell -NoProfile -Command 'if ($PSVersionTable.PSVersion -ge [version]"5.1") { exit 0 } else { exit 1 }'` |
| Logging hook file | required | `test -r ~/.claude/hooks/log_agent_task.ps1` |
| Settings entries | required | `grep -q log_agent_task ~/.claude/settings.json` |

Without the hook the log stays empty, so treat it as required. Print OK / MISSING per item. If a REQUIRED item is missing, stop before the task, explain its purpose in one line, and offer step-by-step setup, asking before installing, editing settings.json, or creating files outside the skill folder. Never install silently. If only OPTIONAL items are missing, say in one line what is lost and continue.

When every required item passes, write today's date to the marker file (`date +%F > <this skill folder>/.setup_ok`), then continue the user's original request (if any).

Answers "what agent tasks did I dispatch, and which are still open?" without retained conversation context. Reads a local append-only log that optional hooks write on every Agent-tool dispatch, so it can survive interruptions, spend-limit stops, and new sessions.

## When to use

- After a session was interrupted (spend limit, crash, closed terminal) and you need to know what background agent work was in flight.
- At the start of a resumed or fresh session: "what was I doing or running?"
- Any time you want a list of recent subagent dispatches and their outcomes.

## How it works

Optional hooks in ~/.claude/settings.json call ~/.claude/hooks/log_agent_task.ps1, which appends one JSON line per event to ~/.claude/agent_task_log.jsonl:

- PreToolUse (Agent) logs the dispatch: timestamp, description, prompt (truncated), model, subagent_type, session id. Status dispatched.
- PostToolUse (Agent) logs the real agent_id and the launch status (async_launched for background, completed for a foreground run).
- SubagentStop logs completion: agent_id, agent_type, and the subagent's last message (truncated). Status finished.

A dispatch is finished when a SubagentStop (or a completed PostToolUse) line shares its agent_id; otherwise it is pending.

The skill itself only reads the log. It needs no model call, network call, MCP server, or external service. If the optional logging hook is not installed, the log may not exist and the skill says so.

## How to run

Run the reader script and relay its output to the user. The command runs through Git Bash, so the script path uses `$USERPROFILE` and forward slashes:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "$USERPROFILE/.claude/skills/task-status/read_agent_log.ps1"
```

Options:

- -Hours 72 widen the default 24 hour window.
- -All ignore the time window (full history).
- -Session <id> restrict to one session id.

Example (only the current session, full history):

```
powershell -NoProfile -ExecutionPolicy Bypass -File "$USERPROFILE/.claude/skills/task-status/read_agent_log.ps1" -All -Session <session-id>
```

## Limits

- Can: list every Agent-tool dispatch, its description, prompt, model, the real agent_id once assigned, and whether a completion event was logged.
- Cannot guarantee liveness: a pending item means no completion line was written. That is either still running or the session died before it finished. The log alone cannot tell these apart, because Claude Code fires no hook for "about to be interrupted."
- For live state of background sessions, cross-check with the built-in agent view: run `claude agents` in a terminal.
