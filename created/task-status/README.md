# task-status

`task-status` is a Claude Code skill that reports what Agent-tool subagent dispatches were started from this and prior sessions. It reads a local append-only log, so it can answer "what was I running?" after an interruption, a spend-limit stop, a crash, or a new session. It makes no model or Application Programming Interface (API) calls and costs nothing to run.

The log is `~/.claude/agent_task_log.jsonl`. The file is JSON Lines (JSONL, a text format where each line is a JavaScript Object Notation (JSON) object). Optional hooks write one line per lifecycle event. The skill can still be installed and loaded without the hooks; it will report that no log exists or that the log is empty.

## What it shows

- Dispatches recorded by the PreToolUse hook for the Agent tool.
- The real agent identifier (ID) and launch status from the PostToolUse hook.
- Completion lines from the SubagentStop hook, including the last message.
- Pending versus finished status. Pending means no completion line was recorded, which can mean still running or interrupted.

## Install

1. Copy `SKILL.md` and `read_agent_log.ps1` to `~/.claude/skills/task-status/`.
2. Copy `hooks/log_agent_task.ps1` to `~/.claude/hooks/`.
3. Merge the entries from `hooks/settings-snippet.json` into `~/.claude/settings.json`.
4. Start a new Claude Code session so the hooks load.

The scripts resolve the log path from the `USERPROFILE` environment variable at runtime. They do not hardcode a user path. On Windows, run the reader with PowerShell:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\task-status\read_agent_log.ps1"
```

Options:

- `-Hours 72` widen the default 24 hour window.
- `-All` ignore the time window.
- `-Session <id>` restrict to one session identifier.

## Example output

```
=== Agent-tool dispatch status ===
Window: last 24 hours   Session filter: ''
Dispatches: 2   Still pending: 1   Finished: 1

--- PENDING / UNCONFIRMED (no completion recorded) ---
  [<timestamp>] Review parser changes
      model=<model>  type=code-reviewer  agent_id=<agent-id>  session=<session-id>
      prompt: Review the parser changes and list risks.

--- RECENTLY FINISHED ---
  [<timestamp>] Summarize test failures   -> finished [<timestamp>]
      result: Found three failing tests in the parser suite.

Note: 'pending' means no SubagentStop/completed line was logged. That can mean
the agent is still running, OR the session was interrupted before it finished.
Use 'claude agents' (agent view) to see live background-session state.
```
