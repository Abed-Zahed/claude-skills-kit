$defaultTaskName = "ClaudeSkills_Ollama_DropfolderWatcher"
$taskName = if ($env:TRACK_A_TASK_NAME) { $env:TRACK_A_TASK_NAME } else { $defaultTaskName }

try {
    Get-ScheduledTask -TaskName $taskName -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Error: Could not retrieve scheduled task '$taskName'. Ensure the task exists and you have permissions."
    Write-Host "Register it with: powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\register_ollama_watcher_task.ps1`""
    exit 1
}

$state = (Get-ScheduledTask -TaskName $taskName -ErrorAction Stop).State
if ($state -eq "Running") { exit 0 }

if ($state -eq "Disabled") {
    Write-Host "Task '$taskName' is disabled."
    Write-Host "Run: Enable-ScheduledTask -TaskName '$taskName'; Start-ScheduledTask -TaskName '$taskName'"
    exit 1
}

Write-Host "Task '$taskName' is not running (state: $state)."
Write-Host "Run: Start-ScheduledTask -TaskName '$taskName'"
exit 1
