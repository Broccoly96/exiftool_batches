param(
    [string]$SourceListFile = "files_missing_dates.txt",
    [string]$DestinationBaseDir = "missing_dates_files",
    [string]$LogFile = "move_files_log.txt",
    [switch]$DryRun
)

# Stop script on critical errors
$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [string]$Message,
        [string]$LogFilePath
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFilePath -Append -Encoding UTF8
    Write-Host "$Timestamp - $Message"
}

# Initialize log file
Remove-Item -Path $LogFile -ErrorAction SilentlyContinue
Write-Log -Message "--- Script Start: $(Get-Date) ---" -LogFilePath $LogFile
Write-Log -Message "Source list file: $SourceListFile" -LogFilePath $LogFile
Write-Log -Message "Destination base directory: $DestinationBaseDir" -LogFilePath $LogFile
Write-Log -Message "Log file: $LogFile" -LogFilePath $LogFile
if ($DryRun) {
    Write-Log -Message "Dry run mode is enabled. Files will not be moved." -LogFilePath $LogFile
}

# Check if source list file exists
if (-not (Test-Path -Path $SourceListFile)) {
    Write-Log -Message "Error: Source list file '$SourceListFile' not found." -LogFilePath $LogFile
    exit 1
}

# Create destination base directory if it doesn't exist
if (-not (Test-Path -Path $DestinationBaseDir)) {
    Write-Log -Message "Creating destination base directory '$DestinationBaseDir'." -LogFilePath $LogFile
    New-Item -ItemType Directory -Path $DestinationBaseDir -ErrorAction Stop | Out-Null
}

# Read file list and perform move operation
$filePaths = Get-Content -Path $SourceListFile

foreach ($filePath in $filePaths) {
    $sourcePath = Join-Path -Path (Get-Location) -ChildPath $filePath.TrimStart('.', '/')
    $relativePath = $filePath.TrimStart('.', '/')
    $destinationPath = Join-Path -Path $DestinationBaseDir -ChildPath $relativePath

    # Check if source file exists
    if (-not (Test-Path -Path $sourcePath)) {
        Write-Log -Message "Warning: File not found: '$sourcePath'" -LogFilePath $LogFile
        continue # Skip to the next file
    }

    # Create destination directory if it doesn't exist (New-Item -Force simplifies existence check)
    $destinationDir = Split-Path -Path $destinationPath -Parent
    New-Item -ItemType Directory -Path $destinationDir -Force -ErrorAction Stop | Out-Null
    Write-Log -Message "Processing: '$sourcePath' -> '$destinationPath'" -LogFilePath $LogFile

    if (-not $DryRun) {
        Move-Item -Path $sourcePath -Destination $destinationPath -Force -ErrorAction Stop
        Write-Log -Message "Success: Moved '$sourcePath' to '$destinationPath'." -LogFilePath $LogFile
    } else {
        Write-Log -Message "Dry Run: '$sourcePath' would be moved to '$destinationPath'." -LogFilePath $LogFile
    }
}

Write-Log -Message "--- Script End ---" -LogFilePath $LogFile
