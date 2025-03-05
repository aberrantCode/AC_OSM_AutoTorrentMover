# Define the source and destination directories
$sourceDir = Get-Location
$destinationDir = "C:\osm\torrents\src"

Write-Host "Starting the install script..."
Write-Host "Source directory: $sourceDir"
Write-Host "Destination directory: $destinationDir"

# Create the destination directory if it does not exist
if (-Not (Test-Path -Path $destinationDir)) {
    Write-Host "Destination directory does not exist. Creating directory..."
    New-Item -ItemType Directory -Path $destinationDir -Force
} else {
    Write-Host "Destination directory already exists."
}

# Copy the contents of the source directory to the destination directory
# Overwrite the files if they are newer
Write-Host "Copying contents from $sourceDir to $destinationDir..."
Get-ChildItem -Path $sourceDir -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($sourceDir.Path.Length).TrimStart("\")
    $destinationPath = Join-Path -Path $destinationDir -ChildPath $relativePath
    if (-Not (Test-Path -Path $destinationPath) -or ($_.LastWriteTime -gt (Get-Item -Path $destinationPath).LastWriteTime)) {
        Write-Host "Copying $($_.FullName) to $destinationPath..."
        Copy-Item -Path $_.FullName -Destination $destinationPath -Force -ErrorAction 'Continue'
    }
}

Write-Host "Contents of $sourceDir have been copied to $destinationDir"

# Invoke the Register.ps1 script
$registerScriptPath = "C:\osm\torrents\src\register.ps1"
Write-Host "Invoking the Register.ps1 script at $registerScriptPath..."
if (-Not (Test-Path -Path $registerScriptPath)) {
    Write-Host "Register.ps1 script not found at $registerScriptPath. Exiting..."
    exit
}
& $registerScriptPath

Write-Host "Install script execution completed."