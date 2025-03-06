param (
    [string]$Source = "$env:USERPROFILE\Downloads",
    [string]$Destination = "\\ac-nas\videos\torrents\pending",
    [switch]$Test,
    [switch]$Force
)
Clear-Host
. "$($PSScriptRoot)\Common.ps1"
Write-SpectreFigletText -Text "Move Torrents" -Color "Olive"
Write-SpectreRule -Title "Runtime environment and paramters" -Color "White"

# Define lock file path
$lockFilePath = Join-Path -Path $env:TEMP -ChildPath "move-torrents.lock"

# Check if lock file exists (another instance is running)
if (Test-Path -Path $lockFilePath) {
    $lockFileAge = (Get-Date) - (Get-Item -Path $lockFilePath).CreationTime
    
    # If the lock file is older than 30 minutes, it might be stale (from a crashed run)
    if ($lockFileAge.TotalMinutes -lt 30 -and -not $Force) {
        Write-SpectreHost -Message " ! [white]Another instance[/] of the script is already running. [yellow]Add -Force[/] parameter to override." 
        exit 0
    }
    elseif ( $Force -or $lockFileAge.TotalMinutes -ge 30 ) {
        Write-SpectreHost -Message " * Removing stale lock file (age: $([math]::Floor($lockFileAge.TotalMinutes)) minutes)."
        Remove-Item -Path $lockFilePath -Force
    }
    else {
        Write-SpectreHost -Message " * Detected lock file [Red](age: $($lockFileAge.TotalMinutes) minutes)[/]. Exiting."
        exit 1
    }
}

# Create lock file
try {
    $null = New-Item -Path $lockFilePath -ItemType File -Force
    Write-SpectreHost -Message " * Created lock file at [green]$lockFilePath[/]"
    
    # Main script logic
    Write-SpectreHost -Message " [White]* Source directory[/]: [Green]$Source[/]"
    Write-SpectreHost -Message " [White]* Destination directory[/]: [Green]$Destination[/]"
    Write-SpectreHost -Message " [White]* Test:[/] [Green]$Test[/]"
    Write-SpectreHost -Message " [White]* Force[/]: [Green]$Force[/]"
    Write-SpectreRule -Title "Script Execution"
    
    # Get all .torrent files in the source directory
    $torrentFiles = Get-ChildItem -Path $Source -Filter *.torrent
    Write-SpectreHost -Message " * Found [green]$($torrentFiles.Count)[/] torrents in the source directory."
    $testFilePath = ""
    if ($Test -and $torrentFiles.Count -eq 0) {
        # Create a blank .torrent file for testing
        Write-SpectreHost -Message " * Creating a blank .torrent file for testing..."
        $testFilePath = Join-Path -Path $Source -ChildPath "testfile.torrent"
        New-Item -Path $testFilePath -ItemType File -Force | Out-Null
        $torrentFiles = @(Get-Item -Path $testFilePath)
    }
    
    # Move each .torrent file to the destination directory
    $itemCount = $torrentFiles.Count
    $currentItem = 0
    $moved = 0
    $increment = 100 / $itemCount
    Invoke-SpectreCommandWithProgress -ScriptBlock {
        param (
            [Spectre.Console.ProgressContext] $Context
        )
        $task1 = $Context.AddTask("[green]Moving files[/]")
        $task1.Sp
        $errorLogs = @()
        foreach ($file in $torrentFiles) {
            $logEntries = @()
            try {
                $currentItem++
                $logEntries += "Processing item $($currentItem) of $($itemCount): $($file)"
                $destinationPath = Join-Path -Path $Destination -ChildPath $file.Name
                if ( -not $Test ) {
                    Move-Item -Path $file.FullName -Destination $destinationPath -Force | Out-Null
                    $logEntries += "Moved $($file.FullName) to $($destinationPath)"
                }
                if ( $Test -and $testFilePath -ne "") {
                    Remove-Item -Path $destinationPath -Force | Out-Null
                    $logEntries += "Removed test file $($file.FullName)"
                }
                Start-Sleep -Seconds 3
                $moved++
            }
            catch {
                $logEntries += "Error moving file $($file.FullName): $_"
                $errorLogs += $logEntries
            }
            $task1.Increment($increment)
        }
        if ( $errorLogs.Count -gt 0 ) {
            Write-SpectreHost -Message "Errors occurred during script execution:"
            foreach ($error in $errorLogs) {
                Write-SpectreHost -Message $error
            }
        }
    }
    
    if ($Test -and $testFilePath -eq "") {
        Write-SpectreHost -Message " * Test mode: No files were actually moved."
    }
    elseif ($Test -and $testFilePath -ne "") {
        if (Test-Path -Path $testFilePath) {
            Write-SpectreHost -Message " * Removing the test file [green]$testFilePath[/]"
            Remove-Item -Path $testFilePath -Force | Out-Null
        }
    }
    else {
        Write-SpectreHost -Message " * Moved $moved of $itemCount items."
    }
    
    Write-SpectreHost -Message "[blink]Script execution completed.[blink]"
}
catch {
    Write-SpectreHost -Message " ! An [red]error[/] occurred during script execution: $_"
}
finally {
    # Always remove lock file when done, regardless of success or failure
    Write-SpectreRule -Title "Cleanup"
    if (Test-Path -Path $lockFilePath) {
        Write-SpectreHost -Message " * Removing lock file"
        Remove-Item -Path $lockFilePath -Force | Out-Null
        Write-SpectreHost -Message " * Lock file removed."
    }
}