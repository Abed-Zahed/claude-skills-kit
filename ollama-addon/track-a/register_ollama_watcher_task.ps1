# register_ollama_watcher_task.ps1
#
# One-time setup. Registers watch_ollama_dropfolder.ps1 as a Windows Task
# Scheduler job so it survives reboots and VSCode closing, instead of dying
# with whatever terminal launched it by hand. Uses LogonType Password, not S4U, because the watcher's child process
# calls Ollama Cloud over the network, and S4U has no network access.
#
# Must be run by you directly, not by Claude: Get-Credential needs an
# interactive password prompt, which a non-interactive tool call cannot
# supply (and should not try to).
#
# Run manually, once:
#   powershell -ExecutionPolicy Bypass -File register_ollama_watcher_task.ps1

$ErrorActionPreference = "Stop"
$orchestratorRoot = (Get-Item $PSScriptRoot).FullName
$powershellExe = (Get-Command powershell.exe).Source

$credMessage = "Enter the password for $env:USERNAME. The watcher's child " +
    "process calls Ollama Cloud over the network, which needs a stored " +
    "credential to work while you're logged out (S4U has no network " +
    "access). This script does not keep the password; Windows Task " +
    "Scheduler stores it in its own DPAPI-protected credential store."
$taskCredential = Get-Credential -UserName $env:USERNAME -Message $credMessage
$taskPassword = $taskCredential.GetNetworkCredential().Password

# Enabled immediately: this is a near-zero-cost polling loop
# that only does real work when a task file actually appears, no separate
# activation step needed.
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun `
    -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)

$watcherAction = New-ScheduledTaskAction -Execute $powershellExe `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$orchestratorRoot\watch_ollama_dropfolder.ps1`"" `
    -WorkingDirectory $orchestratorRoot

$watcherTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

Register-ScheduledTask -TaskName "ClaudeSkills_Ollama_DropfolderWatcher" `
    -Action $watcherAction -Trigger $watcherTrigger -Settings $settings `
    -Description "Watches ollama_dropfolder\tasks for drop-folder delegation requests and runs them through run_ollama_batch.ps1 (watch_ollama_dropfolder.ps1)." `
    -User $taskCredential.UserName -Password $taskPassword -RunLevel Limited -Force

Write-Output "Registered ClaudeSkills_Ollama_DropfolderWatcher, enabled, fires at logon."
Write-Output "It will start automatically on next logon/reboot. The copy you started by hand earlier keeps running until you restart or log off."
