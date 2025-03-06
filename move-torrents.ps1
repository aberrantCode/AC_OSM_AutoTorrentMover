param (
    [string]$Source = "$env:USERPROFILE\Downloads",
    [string]$Destination = "\\ac-nas\videos\torrents\pending",
    [switch]$Test,
    [switch]$Force
)
Clear-Host
Write-SpectreFigletText -Text "Move Torrents"
Write-SpectreRule -Title "Runtime environment and paramters"
. ".\Common.ps1"

# Define lock file path
$lockFilePath = Join-Path -Path $env:TEMP -ChildPath "move-torrents.lock"

# Check if lock file exists (another instance is running)
if (Test-Path -Path $lockFilePath) {
    $lockFileAge = (Get-Date) - (Get-Item -Path $lockFilePath).CreationTime
    
    # If the lock file is older than 30 minutes, it might be stale (from a crashed run)
    if ($lockFileAge.TotalMinutes -lt 30 -and -not $Force) {
        Write-SpectreHost -Message "!! [white]Another instance[/] of the script is already running. [yellow]Add -Force[/] parameter to override." 
        exit 0
    }
    elseif ( $Force -or $lockFileAge.TotalMinutes -ge 30 ) {
        Write-SpectreHost -Message" * Found a stale lock file (age: $([math]::Floor($lockFileAge.TotalMinutes)) minutes). Removing and continuing."
        Remove-Item -Path $lockFilePath -Force
    }
    else {
        Write-SpectreHost -Message "Found a lock file [Red](age: $($lockFileAge.TotalMinutes) minutes)[/]. Exiting."
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
        Write-SpectreHost -Message " * Initiating task with progress..."
        $task1 = $Context.AddTask("Moving files")
        foreach ($file in $torrentFiles) {
            try {
                $currentItem++
                #Write-Host "Processing item $($currentItem) of $($itemCount): $($file)"
                $destinationPath = Join-Path -Path $Destination -ChildPath $file.Name
                if ($Test -and $testFilePath -eq "") {
                    #Write-ToLog "Test mode: Would move $($file.FullName) to $destinationPath"
                }
                else {
                    #Write-ToLog " - Moving from $($file.FullName)"
                    #Write-ToLog " - Moving to $destinationPath"
                    Move-Item -Path $file.FullName -Destination $destinationPath -Force | Out-Null
                    #Write-ToLog " - Move completed"
                }
                if ( $Test -and $testFilePath -ne "") {
                    #Write-ToLog " - Removing $($file.FullName)..."
                    Remove-Item -Path $destinationPath -Force | Out-Null
                    #Write-ToLog " - Removed $($file.FullName)"
                }
                $moved++
            }
            catch {
                Write-SpectreHost " * [DarkRed]Error[/] moving file $($file.FullName): [red]$_[/]"
            }
            $task1.Increment($increment)
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