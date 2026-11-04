---
name: task-status
description: Report the status of Agent-tool subagent dispatches from this and prior sessions by reading the local agent_task_log.jsonl. Use after an interruption, spend-limit stop, crash, or fresh session to recover what background agent work was in flight. Shows pending versus finished dispatches with results. Zero API cost, reads a local log only. Works on stock Claude Code; the log is optional and may be empty until the logging hook is installed.
---

# /task-status

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

Run the reader script and relay its output to the user:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\task-status\read_agent_log.ps1"
```

Options:

- -Hours 72 widen the default 24 hour window.
- -All ignore the time window (full history).
- -Session <id> restrict to one session id.

Example (only the current session, full history):

```
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\task-status\read_agent_log.ps1" -All -Session <session-id>
```

## Limits

- Can: list every Agent-tool dispatch, its description, prompt, model, the real agent_id once assigned, and whether a completion event was logged.
- Cannot guarantee liveness: a pending item means no completion line was written. That is either still running or the session died before it finished. The log alone cannot tell these apart, because Claude Code fires no hook for "about to be interrupted."
- For live state of background sessions, cross-check with the built-in agent view: run `claude agents` in a terminal.
