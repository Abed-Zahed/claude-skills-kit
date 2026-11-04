# read_agent_log.ps1
# Reads the local agent task log and prints a human-readable status report
# of Agent-tool dispatches.
#
# The log path is resolved from the USERPROFILE environment variable at runtime:
#   $env:USERPROFILE\.claude\agent_task_log.jsonl
#
# Correlation: a dispatch is a PreToolUse "dispatched" line. Its agent_id is
# only known from the following PostToolUse line (same session, same
# description). A SubagentStop line with that agent_id means it finished.
#
# Usage:
#   powershell -File read_agent_log.ps1                 # last 24 hours, all sessions
#   powershell -File read_agent_log.ps1 -Session <id>   # one session only
#   powershell -File read_agent_log.ps1 -Hours 72       # widen the window
#   powershell -File read_agent_log.ps1 -All            # ignore the time window

param(
    [string]$Session = '',
    [int]$Hours = 24,
    [switch]$All
)

$ErrorActionPreference = 'SilentlyContinue'

if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    Write-Output "USERPROFILE is not set. This skill expects a Windows user profile."
    exit 0
}

$log = Join-Path $env:USERPROFILE '.claude\agent_task_log.jsonl'

if (-not (Test-Path -LiteralPath $log)) {
    Write-Output "No agent task log yet ($log does not exist). No Agent-tool dispatches have been recorded."
    exit 0
}

$rows = @()
foreach ($ln in (Get-Content -LiteralPath $log)) {
    if ([string]::IsNullOrWhiteSpace($ln)) { continue }
    try { $rows += ($ln | ConvertFrom-Json) } catch { }
}

if ($rows.Count -eq 0) { Write-Output "Agent task log is empty."; exit 0 }

$cutoff = (Get-Date).ToUniversalTime().AddHours(-1 * [math]::Abs($Hours))
$sel = foreach ($r in $rows) {
    $tsOk = $true
    if (-not $All) {
        $t = [datetime]::MinValue
        if ([datetime]::TryParse($r.ts, [ref]$t)) { $tsOk = ($t.ToUniversalTime() -ge $cutoff) }
    }
    $sesOk = ($Session -eq '') -or ($r.session -eq $Session)
    if ($tsOk -and $sesOk) { $r }
}

if (-not $sel -or @($sel).Count -eq 0) {
    Write-Output "No Agent dispatches in the selected window (Hours=$Hours, Session='$Session'). Try -All."
    exit 0
}

# Finished agent ids (from SubagentStop and completed PostToolUse).
$finished = @{}
foreach ($r in $sel) {
    if ($r.event -eq 'SubagentStop' -and $r.agent_id) { $finished[$r.agent_id] = $r }
    if ($r.event -eq 'PostToolUse' -and $r.status -eq 'completed' -and $r.agent_id) {
        if (-not $finished.ContainsKey($r.agent_id)) { $finished[$r.agent_id] = $r }
    }
}
# Map description to agent_id learned from PostToolUse (to link dispatch lines).
$descToId = @{}
foreach ($r in $sel) {
    if ($r.event -eq 'PostToolUse' -and $r.agent_id -and $r.description) {
        $descToId[$r.description] = $r.agent_id
    }
}

$dispatches = @($sel | Where-Object { $_.event -eq 'PreToolUse' })
$pending = @()
$done = @()
foreach ($d in $dispatches) {
    $id = $descToId[$d.description]
    if ($id -and $finished.ContainsKey($id)) { $done += ,@($d, $id) }
    else { $pending += ,@($d, $id) }
}

Write-Output "=== Agent-tool dispatch status ==="
if ($All) { Write-Output "Window: all history   Session filter: '$Session'" }
else { Write-Output "Window: last $Hours hours   Session filter: '$Session'" }
Write-Output "Dispatches: $($dispatches.Count)   Still pending: $($pending.Count)   Finished: $($done.Count)"
Write-Output ""

if ($pending.Count -gt 0) {
    Write-Output "--- PENDING / UNCONFIRMED (no completion recorded) ---"
    foreach ($p in $pending) {
        $d = $p[0]; $id = $p[1]
        $idTxt = if ($id) { $id } else { '(id not captured yet)' }
        Write-Output "  [$($d.ts)] $($d.description)"
        Write-Output "      model=$($d.model)  type=$($d.subagent_type)  agent_id=$idTxt  session=$($d.session)"
        if ($d.prompt) { Write-Output "      prompt: $($d.prompt)" }
    }
    Write-Output ""
}

if ($done.Count -gt 0) {
    Write-Output "--- RECENTLY FINISHED ---"
    foreach ($p in $done) {
        $d = $p[0]; $id = $p[1]
        $f = $finished[$id]
        Write-Output "  [$($d.ts)] $($d.description)   -> finished [$($f.ts)]"
        if ($f.last_message) { Write-Output "      result: $($f.last_message)" }
    }
    Write-Output ""
}

Write-Output "Note: 'pending' means no SubagentStop/completed line was logged. That can mean"
Write-Output "the agent is still running, OR the session was interrupted before it finished."
Write-Output "Use 'claude agents' (agent view) to see live background-session state."
exit 0
