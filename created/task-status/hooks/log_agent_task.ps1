# log_agent_task.ps1
# Appends one JSONL line per Agent-tool dispatch lifecycle event to the local
# agent task log.
#
# The log path is resolved from the USERPROFILE environment variable at runtime:
#   $env:USERPROFILE\.claude\agent_task_log.jsonl
#
# Registered in settings.json for three events:
#   PreToolUse  (matcher Agent)  -> status "dispatched"    (no agent id yet)
#   PostToolUse (matcher Agent)  -> status from tool_response (async_launched|completed) + agentId
#   SubagentStop (all)           -> status "finished" + agent_id + last message
#
# Design rules:
#   - NEVER blocks a tool call. Always exits 0. Any failure is swallowed.
#   - Reads the hook JSON from stdin, writes a compact JSON line, appends UTF-8 (no BOM).
#   - Truncates long text fields so the log stays greppable.

$ErrorActionPreference = 'SilentlyContinue'

function Truncate([string]$s, [int]$n) {
    if ($null -eq $s) { return '' }
    $s = $s -replace '\s+', ' '
    if ($s.Length -gt $n) { return $s.Substring(0, $n) + '...' }
    return $s
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $j = $raw | ConvertFrom-Json

    if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) { exit 0 }
    $log = Join-Path $env:USERPROFILE '.claude\agent_task_log.jsonl'
    $dir = Split-Path -Parent $log
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $event = [string]$j.hook_event_name
    $entry = [ordered]@{
        ts      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        event   = $event
        session = [string]$j.session_id
        cwd     = [string]$j.cwd
    }

    switch ($event) {
        'PreToolUse' {
            $ti = $j.tool_input
            $entry['status']        = 'dispatched'
            $entry['description']   = Truncate ([string]$ti.description) 200
            $entry['subagent_type'] = [string]$ti.subagent_type
            $entry['model']         = [string]$ti.model
            $entry['prompt']        = Truncate ([string]$ti.prompt) 300
        }
        'PostToolUse' {
            $tr = $j.tool_response
            $st = [string]$tr.status
            if ([string]::IsNullOrEmpty($st)) { $st = 'returned' }
            $entry['status']      = $st          # async_launched | completed | returned
            $entry['agent_id']    = [string]$tr.agentId
            $entry['description'] = Truncate ([string]$tr.description) 200
            $entry['model']       = [string]$tr.resolvedModel
            $entry['output_file'] = [string]$tr.outputFile
        }
        'SubagentStop' {
            $entry['status']       = 'finished'
            $entry['agent_id']     = [string]$j.agent_id
            $entry['agent_type']   = [string]$j.agent_type
            $entry['last_message'] = Truncate ([string]$j.last_assistant_message) 300
        }
        default {
            $entry['status'] = 'unknown_event'
        }
    }

    $line = ($entry | ConvertTo-Json -Compress -Depth 6)
    # Append without a BOM so the file stays clean JSONL.
    [System.IO.File]::AppendAllText($log, $line + "`n", (New-Object System.Text.UTF8Encoding($false)))
}
catch {
    # Never let a logging error affect the tool call.
}
exit 0
