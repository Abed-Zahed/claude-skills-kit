# run_ollama_batch.ps1
#
# Headless way to give an Ollama Cloud model a real Claude Code agent loop
# (skills, MCP tools, file edits) on one batch task, with nobody watching.
#
# Run it yourself or from Task Scheduler (normally via the drop-folder
# watcher). Do not have a Claude Code session launch it from its own Bash
# tool: the auto-mode classifier blocks one unattended agent spawning another,
# and that is the right call.
#
# How it reaches Ollama instead of Anthropic: Ollama's local daemon speaks the
# Anthropic Messages API on http://localhost:11434 and proxies `:cloud` model
# names to Ollama Cloud (docs.ollama.com/api/anthropic-compatibility). This
# script points claude.exe at that URL with a dummy token, so the real Claude
# Code harness runs on an open-weight model.
#
# Safety: --permission-mode acceptEdits plus ollama_batch_permissions.json.
# Bash is open by default with explicit denies: git commit/push/merge,
# gh pr create/merge/close, rm -rf, .env and credential reads, and any write
# under ~/.claude. Deny always wins over allow, so nothing is committed until
# you review it. The script prints a forced `git diff` of $WorkingDir and a
# log of every Bash call the model made, so you see what it actually did,
# not just its own summary.
#
# Defaults: 25 turns / 8 minutes; deepseek models 60 turns / 20 minutes. An
# explicit -MaxTurns / -TimeoutMinutes always wins. Size them to the task and
# split oversized tasks.
#
# -SmokeTest runs the real launch path (claude.exe resolution, env vars,
# ProcessStartInfo, JSON parse) with a trivial prompt against a cheap model
# and MaxTurns 1, no side effects, cents of Ollama Cloud usage instead of a
# real batch task:
#   powershell -ExecutionPolicy Bypass -File run_ollama_batch.ps1 -SmokeTest -Model <model>:cloud
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File run_ollama_batch.ps1 `
#     -Prompt "Summarize what src/matcher.py does" `
#     -WorkingDir "C:\path\to\your\repo" `
#     -Model "<model-from-your-roster>:cloud"

param(
    [string]$Prompt,
    [string]$WorkingDir = (Get-Location).Path,
    [string]$Model = $env:TRACK_A_DEFAULT_MODEL,
    [int]$MaxTurns = 25,
    [int]$TimeoutMinutes = 8,
    [string]$OutFile,
    [string]$BudgetKey,
    [int]$BudgetBase = 0,
    [switch]$SmokeTest
)

$ErrorActionPreference = "Stop"

if (-not $SmokeTest -and -not $Prompt) {
    Write-Error "Pass -Prompt (the batch task text) or -SmokeTest."
    exit 1
}
if (-not $SmokeTest -and -not $Model) {
    Write-Error "Pass -Model <model>:cloud or set the TRACK_A_DEFAULT_MODEL env var."
    exit 1
}

$orchestratorRoot = (Get-Item $PSScriptRoot).FullName
$permissionsPath = "$orchestratorRoot\ollama_batch_permissions.json"
$targetWorkingDir = (Get-Item $WorkingDir).FullName

# Claude Code uses a native single-file binary at .local\bin\claude.exe.
# Resolve claude.exe directly, with a fallback to the known native install
# path for the S4U-logon dropfolder watcher task, whose cached environment
# can lag a live PATH change. A native .exe launched directly via
# ProcessStartInfo avoids the .cmd wrapper reparsing <, >, | and & in prompt
# text as real operators.
$claudeExeCmd = Get-Command claude.exe -ErrorAction SilentlyContinue
if ($claudeExeCmd) {
    $claudeExe = $claudeExeCmd.Source
} else {
    $claudeExe = "$env:USERPROFILE\.local\bin\claude.exe"
    if (-not (Test-Path $claudeExe)) {
        Write-Error "claude.exe not found on PATH or at fallback location $claudeExe."
        exit 1
    }
}

function Stop-ProcessTree {
    param([int]$RootPid)
    $children = Get-CimInstance Win32_Process -Filter "ParentProcessId = $RootPid" -ErrorAction SilentlyContinue
    foreach ($child in $children) { Stop-ProcessTree -RootPid $child.ProcessId }
    Stop-Process -Id $RootPid -Force -ErrorAction SilentlyContinue
}

# Append-only failure log, a dashboard can read
# this same file. There is no retry-then-rotate loop in this script (this
# is a single-shot batch call, see the header comment), so RetryCount is
# always 0 and FinalOutcome is always "failed" here, that is the honest
# current state, not a placeholder for logic that exists elsewhere.
# Best-effort only, a logging
# failure must never crash the batch script itself.
function Write-OllamaFailureLog {
    param(
        [string]$Model,
        [string]$WorkingDir,
        [string]$TaskDescription,
        [string]$ErrorType,
        [string]$ErrorDetail,
        [int]$RetryCount = 0,
        [string]$FinalOutcome = "failed"
    )
    try {
        $td = if ($TaskDescription) { $TaskDescription.Substring(0, [Math]::Min(150, $TaskDescription.Length)) } else { "" }
        $ed = if ($ErrorDetail) { $ErrorDetail.Substring(0, [Math]::Min(500, $ErrorDetail.Length)) } else { "" }
        $entry = [ordered]@{
            timestamp        = (Get-Date).ToString("o")
            model            = $Model
            working_dir      = $WorkingDir
            task_description = $td
            error_type       = $ErrorType
            error_detail     = $ed
            retry_count      = $RetryCount
            final_outcome    = $FinalOutcome
        }
        $line = $entry | ConvertTo-Json -Compress -Depth 3
        Add-Content -Path "$orchestratorRoot\ollama_failure_log.jsonl" -Value $line -Encoding UTF8
    } catch {
        # Best-effort only, ignore logging failures.
    }
}

# Parses stream-json NDJSON output into (finalResult, bashAttempts[]).
# finalResult mirrors the old single-object shape (result/is_error/
# total_cost_usd/num_turns) so downstream code doesn't need to change.
# bashAttempts is an array of {Command, Outcome} covering every Bash
# tool_use call the model made, matched to its tool_result (including
# denied/errored ones), in call order. Tolerant of a line that fails to
# parse (partial/corrupt output) or an unmatched tool_result, skips rather
# than throwing, this is a diagnostic aid, not something that should crash
# the batch run if the streaming shape shifts slightly on a future CLI
# version.
function Parse-StreamJson {
    param([string]$RawText)

    $finalResult = $null
    $bashCalls = @()  # ordered list of PSCustomObject{Id, Command, Outcome}
    $byId = @{}

    $lines = $RawText -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    foreach ($line in $lines) {
        $evt = $null
        try { $evt = $line | ConvertFrom-Json } catch { continue }
        if (-not $evt.type) { continue }

        if ($evt.type -eq "result") {
            $finalResult = $evt
        }
        elseif ($evt.type -eq "assistant" -and $evt.message -and $evt.message.content) {
            foreach ($block in $evt.message.content) {
                if ($block.type -eq "tool_use" -and $block.name -eq "Bash") {
                    $entry = [PSCustomObject]@{
                        Id      = $block.id
                        Command = $block.input.command
                        Outcome = "(no result captured)"
                    }
                    $bashCalls += $entry
                    $byId[$block.id] = $entry
                }
            }
        }
        elseif ($evt.type -eq "user" -and $evt.message -and $evt.message.content) {
            foreach ($block in $evt.message.content) {
                if ($block.type -eq "tool_result" -and $block.tool_use_id -and $byId.ContainsKey($block.tool_use_id)) {
                    $contentText = $block.content
                    if ($contentText -is [System.Array]) {
                        $contentText = ($contentText | ForEach-Object { $_.text }) -join " "
                    }
                    $contentText = ($contentText -as [string])
                    if ($contentText.Length -gt 300) { $contentText = $contentText.Substring(0, 300) + "..." }
                    $prefix = if ($block.is_error) { "DENIED/ERROR" } else { "ok" }
                    $byId[$block.tool_use_id].Outcome = "$prefix : $contentText"
                }
            }
        }
    }

    return @{ FinalResult = $finalResult; BashCalls = $bashCalls }
}

$effectivePrompt = $Prompt
$effectiveModel = $Model
$effectiveTurnCap = $MaxTurns
# Per-model defaults: slower models can take more turns and time for a
# normal review, so the 8-minute fast-fail (which targets hung calls) and the
# 25-turn cap can kill finished work mid-run. Explicit caller values always
# win; all other models keep the 25-turn / 8-minute defaults.
if ($Model -like 'deepseek*') {
    if (-not $PSBoundParameters.ContainsKey('MaxTurns'))      { $effectiveTurnCap = 60 }
    if (-not $PSBoundParameters.ContainsKey('TimeoutMinutes')) { $TimeoutMinutes = 20 }
}
if ($SmokeTest) {
    $effectivePrompt = "In one short sentence and nothing else, what model are you running as?"
    if (-not $effectiveModel) { Write-Error "-SmokeTest needs -Model <model>:cloud or the TRACK_A_DEFAULT_MODEL env var."; exit 1 }
    $effectiveTurnCap = 1
}

$argList = @(
    '-p',
    # Claude Code 2.1.286+ rejects non-Anthropic ids passed to --model
    # ([claude-code:unrecognized_model], every task failed 2026-10-05). The
    # alias route still works: pass 'sonnet' and map every alias to the
    # Ollama tag via ANTHROPIC_DEFAULT_*_MODEL below.
    '--model', 'sonnet',
    '--permission-mode', 'acceptEdits',
    '--settings', "`"$permissionsPath`"",
    '--output-format', 'stream-json',
    '--verbose',
    '--max-turns', "$effectiveTurnCap",
    '--no-session-persistence'
)

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $claudeExe
$psi.Arguments = ($argList -join ' ')
$psi.WorkingDirectory = $targetWorkingDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.RedirectStandardInput = $true

# The whole point of this script: route to Ollama Cloud, not Anthropic.
$psi.EnvironmentVariables['ANTHROPIC_AUTH_TOKEN'] = 'ollama'
$psi.EnvironmentVariables['ANTHROPIC_BASE_URL'] = 'http://localhost:11434'
foreach ($alias in 'SONNET', 'OPUS', 'HAIKU') {
    $psi.EnvironmentVariables["ANTHROPIC_DEFAULT_${alias}_MODEL"] = $effectiveModel
}
$psi.EnvironmentVariables['ANTHROPIC_SMALL_FAST_MODEL'] = $effectiveModel
if ($psi.EnvironmentVariables.ContainsKey('ANTHROPIC_API_KEY')) {
    $psi.EnvironmentVariables.Remove('ANTHROPIC_API_KEY') | Out-Null
}

# Research budget identity for the PreToolUse hook firecrawl_budget_gate.ps1
# (research budget keys): retries and verifiers of one parent job share a
# single Firecrawl budget instead of each getting a fresh allowance.
if ($BudgetKey) { $psi.EnvironmentVariables['RESEARCH_BUDGET_KEY'] = $BudgetKey }
if ($BudgetBase -gt 0) { if ($BudgetBase -notin 25, 60) { $BudgetBase = 25 }; $psi.EnvironmentVariables['RESEARCH_BASE'] = [string]$BudgetBase }

# Mitigation for long lines in delegated file writes coming back
# hard-wrapped mid-token, with the tail duplicated as bare code.
# CreateNoWindow+redirected streams means stdout is not a real TTY, but many
# Node CLIs still consult the COLUMNS/LINES env vars as a width fallback
# independent of TTY detection, defaulting to 80 when unset. If that path is
# what wraps tool-call content before it reaches the model's own Write calls,
# a wide explicit value should stop it. This is a targeted mitigation, not a
# verified root-cause fix. The real safety net stays the oxlint-after-write
# check; keep doing that regardless of whether this helps.
$psi.EnvironmentVariables['COLUMNS'] = '4096'
$psi.EnvironmentVariables['LINES'] = '400'

# Baseline snapshot, taken BEFORE the model runs. Without it the end-of-run
# report below attributes the entire pre-existing uncommitted state of
# $targetWorkingDir to this task. Everything the report calls "changed by
# this task" is the delta against this snapshot, so it must exist before the
# model can touch anything. Each entry also stores a SHA256 of the file as it
# sits on disk, because the porcelain code alone cannot see a task editing a
# file that was ALREADY dirty before it started (the code reads identical
# before and after), and the hash is the only signal that the content moved
# under a stable status code.
function Get-GitStatusMap {
    param([string]$RepoDir)
    # porcelain v1: two status chars, one space, then the path (renames read
    # "old -> new", keyed by the new path). Only dirty paths appear at all,
    # so an absent key means clean, and the two raw chars distinguish staged
    # ("M ") from unstaged (" M") changes, which a trimmed code would not.
    $map = @{}
    $lines = @(git -C $RepoDir status --porcelain 2>$null)
    if ($LASTEXITCODE -ne 0) { return $null }
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $status = $line.Substring(0, 2)
        $path = $line.Substring(3)
        if ($path -match '^(.+) -> (.+)$') { $path = $Matches[2] }
        # Distinct sentinels, not an empty string: a real SHA256 is 64 hex
        # chars, so "<absent>" (deleted, or not a plain file, e.g. a
        # submodule) and "<unreadable>" (locked or unreadable) can never
        # collide with one, and silent failure here would reintroduce the
        # same status-code-only blindness.
        $hash = '<absent>'
        $fullPath = Join-Path $RepoDir $path
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            try {
                $hash = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256 -ErrorAction Stop).Hash
            } catch {
                $hash = '<unreadable>'
            }
        }
        $map[$path] = [pscustomobject]@{ Status = $status; Hash = $hash }
    }
    return $map
}

$gitAvailable = $true
$baselineStatus = $null
try {
    $baselineStatus = Get-GitStatusMap -RepoDir $targetWorkingDir
} catch {
    # git missing entirely, or something else fatal in the snapshot itself
    $gitAvailable = $false
}
if ($null -eq $baselineStatus) { $gitAvailable = $false }

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$proc.Start() | Out-Null

# Feed the prompt via stdin (not the command line) so an embedded double-quote
# in $effectivePrompt survives Windows argv parsing intact. claude -p reads the
# prompt from stdin when no positional prompt argument is supplied. Write the
# (short) prompt and close stdin before reading stdout: a small synchronous
# stdin write cannot deadlock against the not-yet-started async stdout reads,
# and closing stdin signals end-of-input so claude.exe does not hang.
$proc.StandardInput.Write($effectivePrompt)
$proc.StandardInput.Close()

# Read both streams before WaitForExit: a child that fills the OS pipe buffer
# blocks on write while nobody reads, and WaitForExit then never returns.
$stdoutTask = $proc.StandardOutput.ReadToEndAsync()
$stderrTask = $proc.StandardError.ReadToEndAsync()
$exitedInTime = $proc.WaitForExit($TimeoutMinutes * 60 * 1000)
if (-not $exitedInTime) {
    Stop-ProcessTree -RootPid $proc.Id
    Write-OllamaFailureLog -Model $effectiveModel -WorkingDir $targetWorkingDir -TaskDescription $effectivePrompt `
        -ErrorType "timeout" -ErrorDetail "Force-killed after exceeding the $TimeoutMinutes-minute wall-clock cap."
    Write-Error "Force-killed after exceeding the $TimeoutMinutes-minute wall-clock cap."
    exit 1
}

$stdoutText = $stdoutTask.Result
$stderrText = $stderrTask.Result

$parsed = Parse-StreamJson -RawText $stdoutText
$result = $parsed.FinalResult
$bashCalls = $parsed.BashCalls

if ($SmokeTest) {
    if ($result -and $result.is_error -eq $false) {
        Write-Output "[smoke] PASS. cost=$($result.total_cost_usd) turns=$($result.num_turns)"
        Write-Output "[smoke] model answered: $($result.result)"
        exit 0
    }
    Write-Output "[smoke] FAIL. exit=$($proc.ExitCode)"
    Write-Output "stdout: $stdoutText"
    Write-Output "stderr: $stderrText"
    exit 1
}

if ($OutFile) {
    Set-Content -Path $OutFile -Value $stdoutText -NoNewline
}

# $proc.ExitCode alone is not trustworthy: claude.exe exits nonzero on the
# benign "connectors are disabled" stderr warning (this script's own
# deliberate ANTHROPIC_AUTH_TOKEN override triggers it every real multi-turn
# run) even when the task itself completed and the parsed result says so.
# Trust $result.is_error first; only fall back to exit code when no result
# event was parsed at all (a real crash before the model finished).
#
# On failure, stderr always holds two benign warnings ("claude.ai connectors
# are disabled..." and "[claude-code:unrecognized_model] ..."), so exit code
# plus stderr alone makes every failure look identical. The parsed result
# object carries the real reason; log it first. The raw stdout is also saved
# to the dropfolder logs dir so it survives even without -OutFile.
# PSObject property lookups instead of $result.<name>: defensive lookups that
# return null for an absent field, and failure reporting must not fail.
function Save-FailureStdout {
    param([string]$ModelName)
    try {
        $logsDir = Join-Path $orchestratorRoot 'ollama_dropfolder\logs'
        if (-not (Test-Path $logsDir)) {
            New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        }
        $path = Join-Path $logsDir ("fail_{0}_{1}.jsonl" -f (Get-Date -Format 'yyyyMMdd_HHmmss'), ($ModelName -replace ':', '_'))
        Set-Content -Path $path -Value $stdoutText -NoNewline -Encoding UTF8
        return $path
    } catch {
        Write-Warning "Could not save failure stdout: $($_.Exception.Message)"
        return $null
    }
}

if (-not $result) {
    # stdout_saved is computed first so it appears before stderr in the detail
    # string and cannot be cut off by the Write-OllamaFailureLog length cap.
    $stdoutSavedPath = Save-FailureStdout -ModelName $effectiveModel
    $noResultDetail = "exit $($proc.ExitCode)"
    if ($stdoutSavedPath) { $noResultDetail += "; stdout_saved=$stdoutSavedPath" }
    $noResultDetail += "; stderr: $stderrText"
    Write-OllamaFailureLog -Model $effectiveModel -WorkingDir $targetWorkingDir -TaskDescription $effectivePrompt `
        -ErrorType "no_result" -ErrorDetail $noResultDetail
    Write-Error "Run failed (exit $($proc.ExitCode), no result event parsed). $noResultDetail"
    exit 1
}
if ($result.is_error) {
    # stdout_saved is computed before the detail string is built so it lands
    # right after api_error_status and the 500-char cap in
    # Write-OllamaFailureLog never cuts it off.
    $stdoutSavedPath = Save-FailureStdout -ModelName $effectiveModel
    $subTypeVal   = $null
    $turnsVal     = $null
    $apiStatusVal = $null
    $resultVal    = $null
    if ($result.PSObject.Properties['subtype'])           { $subTypeVal   = $result.PSObject.Properties['subtype'].Value }
    if ($result.PSObject.Properties['num_turns'])         { $turnsVal     = $result.PSObject.Properties['num_turns'].Value }
    if ($result.PSObject.Properties['api_error_status'])  { $apiStatusVal = $result.PSObject.Properties['api_error_status'].Value }
    $errorsProp = $result.PSObject.Properties['errors']
    if ($result.PSObject.Properties['result'])            { $resultVal    = $result.PSObject.Properties['result'].Value }

    if ($null -eq $subTypeVal)   { $subTypeVal = 'null' }
    if ($null -eq $turnsVal)     { $turnsVal = 'null' }
    if ($null -eq $apiStatusVal) { $apiStatusVal = 'null' }
    $errorsStr = $null
    if ($errorsProp -and $null -ne $errorsProp.Value -and $errorsProp.Value) {
        $errorsStr = (@($errorsProp.Value) -join ' | ')
        if ($errorsStr.Length -gt 120) { $errorsStr = $errorsStr.Substring(0, 120) }
    }
    $resultStr = ''
    if ($null -ne $resultVal) { $resultStr = [string]$resultVal }
    if ($resultStr.Length -gt 300) { $resultStr = $resultStr.Substring(0, 300) }

    $detailParts = @(
        "subtype=$subTypeVal",
        "turns=$turnsVal",
        "api_error_status=$apiStatusVal"
    )
    if ($stdoutSavedPath) { $detailParts += "stdout_saved=$stdoutSavedPath" }
    if ($errorsStr) { $detailParts += "errors=$errorsStr" }
    $detailParts += "result=$resultStr"
    $isErrorDetail = ($detailParts -join '; ') + "; exit $($proc.ExitCode); stderr: $stderrText"

    Write-OllamaFailureLog -Model $effectiveModel -WorkingDir $targetWorkingDir -TaskDescription $effectivePrompt `
        -ErrorType "is_error" -ErrorDetail $isErrorDetail
    Write-Error "Run failed. $isErrorDetail"
    exit 1
}

Write-Output $result.result

# Forced, not optional: whoever calls this script must see what this task
# actually changed, not just trust the model's own account of it. Reported as
# a delta against the baseline snapshot taken before the process started: a
# bare `git diff` here credits the task with all pre-existing dirt AND misses
# newly created untracked files entirely (they print as "(no tracked
# changes)", which a reviewer reads as "this task wrote nothing").
Write-Output "`n----- git change report ($targetWorkingDir), delta vs pre-run baseline -----"
try {
    if (-not $gitAvailable -or $null -eq $baselineStatus) {
        Write-Output "(git unavailable or $targetWorkingDir is not a git repo, this task's changes could not be attributed, review $targetWorkingDir manually)"
    } else {
        $afterStatus = Get-GitStatusMap -RepoDir $targetWorkingDir
        if ($null -eq $afterStatus) {
            Write-Output "(git status failed after the run in $targetWorkingDir, this task's changes could not be attributed, review $targetWorkingDir manually)"
        } else {
            $changedPaths = @()
            $alreadyDirtyPaths = @()
            foreach ($path in $afterStatus.Keys) {
                $before = $baselineStatus[$path]
                # Changed when EITHER the porcelain code moved OR the on-disk
                # content hash moved: the hash is what catches the normal case
                # here, a task editing a file that was already dirty before it
                # started, where the two-character code is identical both
                # times.
                if (-not $before -or
                    $before.Status -ne $afterStatus[$path].Status -or
                    $before.Hash -ne $afterStatus[$path].Hash) {
                    $changedPaths += $path
                } else {
                    $alreadyDirtyPaths += $path
                }
            }
            if ($changedPaths.Count -gt 0) {
                Write-Output "`nCHANGED BY THIS TASK:"
                foreach ($path in $changedPaths) {
                    if ($afterStatus[$path].Status -eq '??') {
                        # Newly created untracked file: bare git diff hides it
                        # entirely, so print its contents instead.
                        Write-Output "`n--- new file: $path ---"
                        $fullPath = Join-Path $targetWorkingDir $path
                        $content = @(Get-Content -LiteralPath $fullPath -TotalCount 201 -ErrorAction SilentlyContinue)
                        if (-not $content) {
                            Write-Output "(empty or unreadable file)"
                        } elseif ($content.Count -gt 200) {
                            Write-Output ($content[0..199] -join "`n")
                            Write-Output "(truncated at 200 lines)"
                        } else {
                            Write-Output ($content -join "`n")
                        }
                    } else {
                        # Absent key in the baseline means the path was clean
                        # before this task (only dirty paths are in the map).
                        $was = 'clean'
                        if ($baselineStatus.ContainsKey($path)) { $was = $baselineStatus[$path].Status.Trim() }
                        Write-Output "`n--- diff: $path (was $was, now $($afterStatus[$path].Status.Trim())) ---"
                        $unstaged = git -C $targetWorkingDir diff -- $path 2>$null
                        if ($unstaged) { Write-Output $unstaged }
                        $staged = git -C $targetWorkingDir diff --cached -- $path 2>$null
                        if ($staged) { Write-Output $staged }
                        if (-not $unstaged -and -not $staged) {
                            # e.g. a mode change or a pure rename, no text hunks
                            Write-Output "(no textual diff, status change only)"
                        }
                    }
                }
            } elseif ($alreadyDirtyPaths.Count -eq 0) {
                # Distinguishable from "the tree was clean", the exact wording
                # matters to the reviewer.
                Write-Output "(this task changed no files; the working tree was clean before this task and still is)"
            } else {
                Write-Output "(this task changed no files; the pre-existing changes below are not this task's work)"
            }
            if ($alreadyDirtyPaths.Count -gt 0) {
                Write-Output "`nALREADY DIRTY BEFORE THIS TASK (pre-existing, excluded from this task's attribution, diffs deliberately not shown):"
                foreach ($path in $alreadyDirtyPaths) {
                    Write-Output "  $path ($($afterStatus[$path].Status.Trim()))"
                }
            }
        }
    }
} catch {
    Write-Output "(change report failed, review $targetWorkingDir manually)"
}

# Forced, not optional: every Bash command it attempted, including
# denied/errored ones, so a reviewer (human, Sonnet, or Opus) can see whether
# it tried to route around a deny rule instead of trusting its own summary of
# what happened.
Write-Output "`n----- bash commands attempted -----"
if ($bashCalls.Count -eq 0) {
    Write-Output "(none)"
} else {
    foreach ($call in $bashCalls) {
        Write-Output "COMMAND: $($call.Command)"
        Write-Output "OUTCOME: $($call.Outcome)"
        Write-Output "---"
    }
}

# Explicit, not implicit: without this, PowerShell.exe's own process exit
# code falls back to whatever $LASTEXITCODE a native command left behind
# (the git diff call above is the usual culprit; a real "not a git repo"
# style failure inside its own try/catch still sets $LASTEXITCODE, caught
# or not). A genuinely successful run could then report a nonzero exit to
# whatever invoked this script. Keep this explicit exit for a successful run.
exit 0
