# run_dropfolder_task.ps1
#
# Runs ONE Track A task file. watch_ollama_dropfolder.ps1 starts this as its own
# process so up to -MaxParallel tasks can run at once (Ollama Cloud allows 3
# concurrent calls). The watcher has already claimed the task by renaming
# <name>.txt to <name>.txt.inflight; this script runs it, writes
# <name>_done.txt atomically, and removes the claimed file when it is finished,
# even if the runner fails.
#
# Task file format is unchanged: line 1 = working dir, line 2 = model, then
# optional KEY=value override lines (TimeoutMinutes, MaxTurns, OutFile,
# BudgetKey, BudgetBase), then the prompt.

param(
    [Parameter(Mandatory = $true)][string]$ClaimedPath,
    [Parameter(Mandatory = $true)][string]$DonePath,
    [string]$Runner = ''
)

$ErrorActionPreference = 'Stop'
if (-not $Runner) { $Runner = Join-Path $PSScriptRoot 'run_ollama_batch.ps1' }

# x.txt.inflight -> x  (two extensions to strip)
$baseName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($ClaimedPath))

try {
    $taskContent = Get-Content -LiteralPath $ClaimedPath -Raw
    $allLines = $taskContent -split "`r?`n"
    $workingDir = $allLines[0].Trim()
    $model = $allLines[1].Trim()
    $overrides = @{}
    $promptStart = 2
    while ($promptStart -lt $allLines.Count -and $allLines[$promptStart] -match '^(TimeoutMinutes|MaxTurns|OutFile|BudgetKey|BudgetBase)=(.+)$') {
        $overrides[$matches[1]] = $matches[2].Trim()
        $promptStart++
    }
    $prompt = ($allLines[$promptStart..($allLines.Count - 1)] -join "`n")
    # OutFile is where the RUNNER writes the stream-json transcript (overwriting
    # anything there). A report path here gets clobbered (2026-10-29 incident).
    if ($overrides.ContainsKey('OutFile') -and $overrides['OutFile'] -notmatch '\.(jsonl|log)$') {
        throw "OutFile must be a transcript path ending in .jsonl or .log (under ollama_dropfolder/logs/), never the deliverable path. Got: $($overrides['OutFile'])"
    }

    $params = @{
        Prompt     = $prompt
        WorkingDir = $workingDir
        Model      = $model
    }
    if ($overrides.ContainsKey('TimeoutMinutes')) { $params.TimeoutMinutes = [int]$overrides['TimeoutMinutes'] }
    if ($overrides.ContainsKey('MaxTurns')) { $params.MaxTurns = [int]$overrides['MaxTurns'] }
    if ($overrides.ContainsKey('OutFile')) { $params.OutFile = $overrides['OutFile'] }
    # Research budget identity (docs/research_tool_routing.md section 5). Default key is the
    # task name; a verifier or retry passes its parent's BudgetKey= to share one budget.
    $params.BudgetKey = if ($overrides.ContainsKey('BudgetKey')) { $overrides['BudgetKey'] } else { $baseName }
    if ($overrides.ContainsKey('BudgetBase')) { $params.BudgetBase = [int]$overrides['BudgetBase'] }
    $result = & $Runner @params 2>&1 | Out-String
} catch {
    $result = "watcher-level error: $_"
}

try {
    # Write to a .tmp path first, then rename, so a poller watching done\ never
    # reads a half-written file. Move-Item on the same volume is atomic.
    $tmpPath = "$DonePath.tmp"
    Set-Content -LiteralPath $tmpPath -Value $result -NoNewline
    Move-Item -LiteralPath $tmpPath -Destination $DonePath -Force
} finally {
    # Always release the claim, otherwise the watcher would requeue a finished task.
    if (Test-Path -LiteralPath $ClaimedPath) { Remove-Item -LiteralPath $ClaimedPath -Force -ErrorAction SilentlyContinue }
}
