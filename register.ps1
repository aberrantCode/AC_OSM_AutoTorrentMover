$taskName = "Move Torrent Files"
$scriptPath = "C:\development\AC_OSM_AutoTorrentMover\start-monitor.ps1"  # Update this path to the actual location of your start-monitor.ps1 script

# Import the common.ps1 script
. C:\development\AC_OSM_AutoTorrentMover\common.ps1

Write-ToLog "Starting the register script..."
Write-ToLog "Task name: $taskName"
Write-ToLog "Script path: $scriptPath"

function Register-ScheduledTaskTriggerAfterLogon {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Move .torrent files from Downloads to \\ac-nas\videos\torrents\pending"
    )

    # Check if the scheduled task already exists
    $taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($taskExists) {
        Write-ToLog "Scheduled task '$TaskName' already exists. Exiting..."
        return $false
    }

    Write-ToLog "Creating a new scheduled task with startup trigger..."

    # Define the action to run the PowerShell script
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$ScriptPath`""

    # Define the event trigger for startup
    $trigger = New-ScheduledTaskTrigger -AtStartup

    # Register the scheduled task
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $TaskName -Description $Description

    Write-ToLog "Scheduled task '$TaskName' has been created to run at system startup."
    return $true
}

function Register-ScheduledTaskTriggeredOnSchedule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 15,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Move .torrent files from Downloads to \\ac-nas\videos\torrents\pending"
    )

    # Check if the scheduled task already exists
    $taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($taskExists) {
        Write-ToLog "Scheduled task '$TaskName' already exists. Exiting..."
        return $false
    }

    Write-ToLog "Creating a new scheduled task with $IntervalMinutes minute interval trigger..."

    # Define the action to run the PowerShell script
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$ScriptPath`""

    # Define the event trigger for recurring schedule
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration ([TimeSpan]::MaxValue)

    # Register the scheduled task
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $TaskName -Description $Description

    Write-ToLog "Scheduled task '$TaskName' has been created to run every $IntervalMinutes minutes."
    return $true
}

# Use the Register-ScheduledTaskTriggerAfterLogon function to register the task
# You can uncomment one of these lines to register the task using your preferred method
# Register-ScheduledTaskTriggerAfterLogon -TaskName $taskName -ScriptPath $scriptPath
Register-ScheduledTaskTriggeredOnSchedule -TaskName $taskName -ScriptPath $scriptPath -IntervalMinutes 5
