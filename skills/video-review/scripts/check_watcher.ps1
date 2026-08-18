$taskName = "JobHunter_Ollama_DropfolderWatcher"

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

try { Start-ScheduledTask -TaskName $taskName -ErrorAction Stop } catch {
    Write-Host "Error: Could not start scheduled task '$taskName'. Ensure you have permissions."
    exit 1
}

Start-Sleep -Seconds 2

if (Test-WatcherRunning) { exit 0 }

Write-Host "Error: The watcher task '$taskName' could not be started after retry. Registering a brand-new scheduled task requires an interactive credential prompt only a human can supply."
exit 1
