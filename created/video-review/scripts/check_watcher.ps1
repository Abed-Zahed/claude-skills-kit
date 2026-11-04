$defaultTaskName = "ClaudeSkills_Ollama_DropfolderWatcher"
$taskName = if ($env:TRACK_A_TASK_NAME) { $env:TRACK_A_TASK_NAME } else { $defaultTaskName }

try {
    Get-ScheduledTask -TaskName $taskName -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Error: Could not retrieve scheduled task '$taskName'. Ensure the task exists and you have permissions."
    exit 1
}

function Test-WatcherRunning {
    $state = (Get-ScheduledTask -TaskName $taskName -ErrorAction Stop).State
    return $state -eq "Running"
}

if (Test-WatcherRunning) { exit 0 }

try { Stop-ScheduledTask -TaskName $taskName -ErrorAction Stop } catch { }

try {
    $state = (Get-ScheduledTask -TaskName $taskName -ErrorAction Stop).State
    if ($state -eq "Disabled") {
        Enable-ScheduledTask -TaskName $taskName -ErrorAction Stop | Out-Null
    }
    Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
} catch {
    Write-Host "Error: Could not start scheduled task '$taskName'. Ensure you have permissions."
    exit 1
}

Start-Sleep -Seconds 2

if (Test-WatcherRunning) { exit 0 }

Write-Host "Error: The watcher task '$taskName' could not be started after retry. If it is disabled, enable it with Enable-ScheduledTask, or re-register it with register_ollama_watcher_task.ps1 from ollama-addon/track-a."
exit 1
