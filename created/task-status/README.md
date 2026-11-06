# task-status

`task-status` is a Claude Code skill that reports what Agent-tool subagent dispatches were started from this and prior sessions. It reads a local append-only log, so it can answer "what was I running?" after an interruption, a spend-limit stop, a crash, or a new session. It makes no model or Application Programming Interface (API) calls and costs nothing to run.

The log is `~/.claude/agent_task_log.jsonl`. The file is JSON Lines (JSONL, a text format where each line is a JavaScript Object Notation (JSON) object). Optional hooks write one line per lifecycle event. The skill can still be installed and loaded without the hooks; it will report that no log exists or that the log is empty.

## Setup

Required:
- Windows PowerShell 5.1 or later. Check: `powershell -NoProfile -Command 'if ($PSVersionTable.PSVersion -ge [version]"5.1") { exit 0 } else { exit 1 }'`
- The logging hook `hooks/log_agent_task.ps1` copied to `~/.claude/hooks/`. Check: `test -r ~/.claude/hooks/log_agent_task.ps1`
- The `hooks/settings-snippet.json` entries merged into `~/.claude/settings.json`. Check: `grep -q log_agent_task ~/.claude/settings.json`

Without the hook the log stays empty, so treat it as required.

Install commands:

```bash
mkdir -p ~/.claude/skills/task-status ~/.claude/hooks
cp SKILL.md read_agent_log.ps1 ~/.claude/skills/task-status/
cp hooks/log_agent_task.ps1 ~/.claude/hooks/
```

Merge the entries from `hooks/settings-snippet.json` into `~/.claude/settings.json`, then start a new Claude Code session so the hooks load.

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
