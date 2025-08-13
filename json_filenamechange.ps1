<#
.SYNOPSIS
    Renames .json files associated with media files (JPG, PNG, MP4) to a standardized format.

.DESCRIPTION
    This script renames .json files that follow a pattern like "filename.ext.something.json"
    to "filename.ext.json". It supports JPG, PNG, and MP4 media files.
    It provides WhatIf and Confirm parameters for safe execution.

.PARAMETER Path
    The root directory to search for media and JSON files. The script will recurse into subdirectories.

.PARAMETER MediaExtensions
    An array of media file extensions to consider (e.g., "jpg", "png", "mp4").

.PARAMETER OutputFile
    The path to a file where a list of unchanged JSON files will be written.

.EXAMPLE
    .\json_filenamechange2.ps1 -Path "C:\MyPhotos" -WhatIf
    This will show what files would be renamed in "C:\MyPhotos" without actually renaming them.

.EXAMPLE
    .\json_filenamechange2.ps1 -Path "C:\MyPhotos" -Confirm
    This will prompt for confirmation before renaming each file in "C:\MyPhotos".

.EXAMPLE
    .\json_filenamechange2.ps1 -Path "C:\MyPhotos"
    This will rename files in "C:\MyPhotos" without prompting for confirmation.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [string[]]$MediaExtensions = @("jpg", "png", "mp4"),

    [string]$OutputFile = "unchanged_json_files.txt"
)

Write-Host "`n================ Starting JSON File Renaming =================="

$renamedFiles = New-Object System.Collections.Generic.HashSet[string]
$mediaPattern = ($MediaExtensions | ForEach-Object { [regex]::Escape(".$_") }) -join '|'

# Get all .json files recursively
$jsonFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.json"

Write-Host "Processing $($jsonFiles.Count) JSON files..."

foreach ($file in $jsonFiles) {
    # Construct a regex pattern that matches any of the specified media extensions
    # and then any characters before .json
    $regexPattern = "^(.*(?:$mediaPattern))\.[^.]+\.json$"

    if ($file.Name -match $regexPattern) {
        $baseName = $matches[1]
        $newName = "$baseName.json"

        if ($file.Name -ne $newName) {
            $newFullPath = Join-Path -Path $file.DirectoryName -ChildPath $newName

            if ($PSCmdlet.ShouldProcess($file.FullName, "Rename-Item to $newFullPath")) {
                try {
                    Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                    Write-Host "Renamed: '$($file.Name)' -> '$newName'" -ForegroundColor Green
                    [void]$renamedFiles.Add($file.FullName) # Add original full path to set
                }
                catch {
                    Write-Host "Error renaming '$($file.Name)': $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Skipped: '$($file.Name)' (already in target format)" -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "Skipped: '$($file.Name)' (does not match renaming pattern)" -ForegroundColor DarkYellow
    }
}

# Identify unchanged files (those that were not renamed)
$unchangedJsonFiles = $jsonFiles | Where-Object { -not $renamedFiles.Contains($_.FullName) }

Write-Host "`n================ Summary =================="
if ($renamedFiles.Count -gt 0) {
    Write-Host "Successfully renamed $($renamedFiles.Count) JSON files." -ForegroundColor Green
} else {
    Write-Host "No JSON files were renamed." -ForegroundColor Yellow
}

if ($unchangedJsonFiles.Count -gt 0) {
    Write-Host "`n=== Unchanged JSON Files (not matching pattern or already in target format) ===" -ForegroundColor Cyan
    $unchangedJsonFiles | Select-Object -ExpandProperty FullName | Out-File -FilePath $OutputFile -Encoding UTF8
    $unchangedJsonFiles | ForEach-Object { Write-Host $_.FullName }
    Write-Host "`nList of unchanged files saved to '$OutputFile'." -ForegroundColor Cyan
} else {
    Write-Host "`nAll relevant JSON files were processed or already in the correct format. No unchanged files to report." -ForegroundColor Green
    # Ensure the output file is empty or removed if no unchanged files
    if (Test-Path $OutputFile) {
        Remove-Item $OutputFile -Force
    }
}

Write-Host "`n================ Script Finished =================="
