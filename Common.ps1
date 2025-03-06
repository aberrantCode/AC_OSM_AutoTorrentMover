
# Check if PwshSpectreConsole module is installed, if not, install it
if (-Not (Get-Module -ListAvailable -Name PwshSpectreConsole)) {
    Write-Host " * Required module not found. Installing module..."
    Install-Module -Name PwshSpectreConsole -Force -Scope CurrentUser
} else {
    Write-SpectreHost -Message " * Required module is already installed."
}

# Define global logging level variable
$Global:LoggingLevel = "Info"

function Write-ToLog {
    param (
        [string]$Message,
        [string]$LogLevel = "Info",
        [string]$ForegroundColor = "White"
    )

    # Define log levels in order of severity
    $logLevels = @("Debug", "Info", "Warning", "Error")

    # Check if the provided log level is valid
    if ($logLevels -notcontains $LogLevel) {
        throw "Invalid log level: $LogLevel. Valid levels are: $($logLevels -join ', ')"
    }
    # Set the foreground color based on the log level
    switch ($LogLevel) {
        "Debug"   { $ForegroundColor = "Gray" }
        "Info"    { $ForegroundColor = "White" }
        "Warning" { $ForegroundColor = "Yellow" }
        "Error"   { $ForegroundColor = "Red" }
    }

    # Check if the message should be logged based on the global logging level
    if ($logLevels.IndexOf($LogLevel) -ge $logLevels.IndexOf($Global:LoggingLevel)) {
        # Write the message using Spectre.Console
        Write-SpectreHost -Message "[$ForegroundColor]$Message[/]"
    }

    # Append the message to the log file if LOG_PATH is not empty
    if ($Global:LOG_PATH) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp [$LogLevel] $Message"
        Add-Content -Path $Global:LOG_PATH -Value $logEntry | Out-Null
    }
}