# Define the source and destination directories
$sourceDir = Get-Location
$destinationDir = "C:\osm\torrents\src"


# Import the PwshSpectreConsole module
& ".\Common.ps1"
Write-ToLog -Message "Starting the install script..." -Level "Info"
# Use Spectre.Console to write to the console
[PwshSpectreConsole.AnsiConsole]::Write([PwshSpectreConsole.Markup]::From("[green]Source directory:[/] $sourceDir"))
[PwshSpectreConsole.AnsiConsole]::Write([PwshSpectreConsole.Markup]::From("[green]Destination directory:[/] $destinationDir"))

# Create the destination directory if it does not exist
if (-Not (Test-Path -Path $destinationDir)) {
    Write-ToLog -Message "Destination directory does not exist. Creating directory..." -Level "Warning"
    New-Item -ItemType Directory -Path $destinationDir -Force
} else {
    Write-ToLog -Message "Destination directory already exists." -Level "Info"
}

# Copy the contents of the source directory to the destination directory
# Overwrite the files if they are newer
Write-ToLog -Message "Copying contents from $sourceDir to $destinationDir..." -Level "Info"
Get-ChildItem -Path $sourceDir -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($sourceDir.Path.Length).TrimStart("\")
    $destinationPath = Join-Path -Path $destinationDir -ChildPath $relativePath
    if (-Not (Test-Path -Path $destinationPath) -or ($_.LastWriteTime -gt (Get-Item -Path $destinationPath).LastWriteTime)) {
        Write-ToLog -Message "Copying $($_.FullName) to $destinationPath..." -Level "Info"
        Copy-Item -Path $_.FullName -Destination $destinationPath -Force -ErrorAction 'Continue'
    }
}

Write-ToLog -Message "Contents of $sourceDir have been copied to $destinationDir" -Level "Info"

# Invoke the Register.ps1 script
$registerScriptPath = "C:\osm\torrents\src\register.ps1"
Write-ToLog -Message "Invoking the Register.ps1 script at $registerScriptPath..." -Level "Info"
if (-Not (Test-Path -Path $registerScriptPath)) {
    Write-ToLog -Message "Register.ps1 script not found at $registerScriptPath. Exiting..." -Level "Error"
    exit
}
& $registerScriptPath

Write-ToLog -Message "Install script execution completed." -Level "Info"