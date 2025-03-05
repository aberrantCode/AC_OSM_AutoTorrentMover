param (
    [string]$Source = "$env:USERPROFILE\Downloads",
    [string]$Destination = "\\ac-nas\videos\torrents\pending",
    [switch]$Test
)

Write-Host "Starting the move-torrents script..."
Write-Host "Source directory: $Source"
Write-Host "Destination directory: $Destination"
if ($Test) {
    Write-Host "Test mode is enabled."
}

# Get all .torrent files in the source directory
$torrentFiles = Get-ChildItem -Path $Source -Filter *.torrent
Write-Host "Found $($torrentFiles.Count) torrents in the source directory."
$testFilePath = ""
if ($Test -and $torrentFiles.Count -eq 0) {
    # Create a blank .torrent file for testing
    Write-Host "No .torrent files found. Creating a blank .torrent file for testing..."
    $testFilePath = Join-Path -Path $Source -ChildPath "testfile.torrent"
    New-Item -Path $testFilePath -ItemType File -Force | Out-Null
    $torrentFiles = @(Get-Item -Path $testFilePath)
}

# Move each .torrent file to the destination directory
$itemCount = $torrentFiles.Count
$currentItem = 0
$moved = 0
foreach ($file in $torrentFiles) {
    try {
        $currentItem++
        Write-Host "Processing item $currentItem of $($itemCount): $($file.FullName)"
        $destinationPath = Join-Path -Path $Destination -ChildPath $file.Name
        if ($Test -and $testFilePath -eq "") {
            Write-Host "Test mode: Would move $($file.FullName) to $destinationPath"
        }
        else {
            Write-Host " - Moving from $($file.FullName)"
            Write-Host " - Moving to $destinationPath"
            Move-Item -Path $file.FullName -Destination $destinationPath -Force | Out-Null
            Write-Host " - Move completed"
        }
        if ( $Test -and $testFilePath -ne "") {
            Write-Host " - Removing $($file.FullName)..."
            Remove-Item -Path $destinationPath -Force | Out-Null
            Write-Host " - Removed $($file.FullName)"
        }
        $moved++
    }
    catch {
        Write-Host "Error moving file $($file.FullName): $_"
    }
}

if ($Test -and $testFilePath -eq "") {
    Write-Host "Test mode: No files were actually moved."
}
elseif ($Test -and $testFilePath -ne "") {
    if (Test-Path -Path $testFilePath) {
        Write-Host "Removing the test file $testFilePath..."
        Remove-Item -Path $testFilePath -Force
    }
}
else {
    Write-Host "Moved $moved of $itemCount items."
}

Write-Host "Script execution completed."