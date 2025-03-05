$taskName = "Move Torrent Files"
$scriptPath = "C:\osm\torrents\src\move-torrents.ps1"  # Update this path to the actual location of your move-torrents.ps1 script

Write-Host "Starting the register script..."
Write-Host "Task name: $taskName"
Write-Host "Script path: $scriptPath"

# Check if the scheduled task already exists
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "Scheduled task '$taskName' already exists. Exiting..."
    exit
}

Write-Host "Creating a new scheduled task..."

# Define the action to run the PowerShell script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$scriptPath`""

# Define the event trigger for new file creation in the Downloads folder
$trigger = New-ScheduledTaskTrigger -AtStartup

# Register the scheduled task
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Move .torrent files from Downloads to \\ac-nas\videos\torrents\pending"

Write-Host "Scheduled task '$taskName' has been created to monitor the Downloads folder and move .torrent files."
Write-Host "Register script execution completed."