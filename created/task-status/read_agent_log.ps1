# read_agent_log.ps1
# Reads the local agent task log and prints a human-readable status report
# of Agent-tool dispatches.
#
# The log path is resolved from the USERPROFILE environment variable at runtime:
#   $env:USERPROFILE\.claude\agent_task_log.jsonl
#
# Correlation: a dispatch is a PreToolUse "dispatched" line. Its agent_id is
# only known from a later PostToolUse line with the same description. Starts
# and finishes are paired in timestamp order: each start line is matched to at
# most one later finish line, preferring an exact agent_id match, then the
# earliest unconsumed finish with the same description.
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

# Order events by timestamp, keeping file order for equal timestamps.
$ordered = @()
$i = 0
foreach ($r in $sel) {
    $t = [datetime]::MinValue
    if (-not [datetime]::TryParse($r.ts, [ref]$t)) { $t = [datetime]::MinValue }
    $ordered += [pscustomobject]@{ Ts = $t.ToUniversalTime(); Pos = $i; Row = $r }
    $i++
}
$ordered = @($ordered | Sort-Object Ts, Pos)
for ($k = 0; $k -lt $ordered.Count; $k++) { $ordered[$k].Pos = $k }

# Finish lines: SubagentStop events and completed PostToolUse events.
$finishes = @()
foreach ($e in $ordered) {
    $r = $e.Row
    $isStop = ($r.event -eq 'SubagentStop' -and $r.agent_id)
    $isDone = ($r.event -eq 'PostToolUse' -and $r.status -eq 'completed' -and $r.agent_id)
    if ($isStop -or $isDone) {
        $finishes += [pscustomobject]@{
            Pos = $e.Pos
            AgentId = [string]$r.agent_id
            Description = [string]$r.description
            IsStop = [bool]$isStop
            Row = $r
            Consumed = $false
        }
    }
}

$dispatches = @($ordered | Where-Object { $_.Row.event -eq 'PreToolUse' })
$pending = @()
$done = @()

foreach ($d in $dispatches) {
    $dr = $d.Row
    $desc = [string]$dr.description

    # agent_id learned from a later PostToolUse line with the same description.
    $exactId = $null
    foreach ($e in $ordered) {
        if ($e.Pos -le $d.Pos) { continue }
        $r = $e.Row
        if ($r.event -eq 'PostToolUse' -and $r.agent_id -and ([string]$r.description) -eq $desc) {
            $exactId = [string]$r.agent_id
            break
        }
    }

    $match = $null

    # Exact agent_id match, later than this dispatch and not yet consumed.
    if ($exactId) {
        $exact = @($finishes | Where-Object { -not $_.Consumed -and $_.Pos -gt $d.Pos -and $_.AgentId -eq $exactId })
        $stops = @($exact | Where-Object { $_.IsStop })
        if ($stops.Count -gt 0) { $match = $stops[0] }
        elseif ($exact.Count -gt 0) { $match = $exact[0] }
    }

    # Otherwise the earliest unconsumed finish with the same description.
    if (-not $match -and -not $exactId -and $desc) {
        $match = @($finishes | Where-Object { -not $_.Consumed -and $_.Pos -gt $d.Pos -and $_.Description -eq $desc })[0]
    }

    if ($match) {
        $match.Consumed = $true
        $done += ,@($dr, $match)
    }
    else {
        # An id already paired with an earlier dispatch is not this one's.
        if ($exactId -and @($finishes | Where-Object { $_.Consumed -and $_.AgentId -eq $exactId }).Count -gt 0) { $exactId = $null }
        $pending += ,@($dr, $exactId)
    }
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
        $d = $p[0]; $f = $p[1]
        Write-Output "  [$($d.ts)] $($d.description)   -> finished [$($f.Row.ts)]"
        if ($f.Row.last_message) { Write-Output "      result: $($f.Row.last_message)" }
    }
    Write-Output ""
}

Write-Output "Note: 'pending' means no SubagentStop/completed line was logged. That can mean"
Write-Output "the agent is still running, OR the session was interrupted before it finished."
Write-Output "Use 'claude agents' (agent view) to see live background-session state."
exit 0
