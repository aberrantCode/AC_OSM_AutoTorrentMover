$folder = "C:\Users\YourUsername\Downloads"  # Change this to your Downloads folder path

# Create a FileSystemWatcher to monitor the folder
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $folder
$watcher.Filter = "*.torrent"
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'

# Define the action to take when a new file is created
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    Write-Host "New file created: $name at $path"
    # Add your code here to handle the new file
    & "C:\path\to\move-torrents.ps1" # Invoke the move-torrents script with the file path as an argument
}

# Register the event
Register-ObjectEvent $watcher Created -Action $action

# Start monitoring
$watcher.EnableRaisingEvents = $true

# Keep the script running
Write-Host "Monitoring folder: $folder"
while ($true) { Start-Sleep -Seconds 1 }