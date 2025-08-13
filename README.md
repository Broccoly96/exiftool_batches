# ExifTool Batches

This repository contains a collection of PowerShell scripts designed to assist with managing media files, particularly focusing on date/time metadata and associated JSON sidecar files, often encountered with services like Google Photos Takeout. These scripts leverage [ExifTool](https://exiftool.org/) for powerful metadata manipulation.

## Prerequisites

*   **PowerShell**: These scripts are written in PowerShell and require a compatible version (PowerShell 5.1 or PowerShell Core 7+).
*   **ExifTool**: Most scripts rely on ExifTool being installed and accessible via your system's PATH, or located in a subdirectory named `exiftool-13.33_64` within the script's directory. You can download ExifTool from its [official website](https://exiftool.org/).

## Scripts Overview

### `json_filenamechange.ps1`

This script renames `.json` sidecar files associated with media files (JPG, PNG, MP4) to a standardized format. It changes filenames like "filename.ext.something.json" to "filename.ext.json", making them easier to pair with their respective media files.

**Parameters:**

*   `-Path <string>` (Mandatory): The root directory to search for media and JSON files. The script will recurse into subdirectories.
*   `-MediaExtensions <string[]>`: An array of media file extensions to consider (default: `"jpg", "png", "mp4"`).
*   `-OutputFile <string>`: The path to a file where a list of unchanged JSON files will be written (default: `"unchanged_json_files.txt"`).
*   `-WhatIf`: Shows what files would be renamed without actually renaming them.
*   `-Confirm`: Prompts for confirmation before renaming each file.

**Examples:**

```powershell
# Show what files would be renamed in C:\MyPhotos without actually renaming them
.\json_filenamechange.ps1 -Path "C:\MyPhotos" -WhatIf

# Prompt for confirmation before renaming each file in C:\MyPhotos
.\json_filenamechange.ps1 -Path "C:\MyPhotos" -Confirm

# Rename files in C:\MyPhotos without prompting
.\json_filenamechange.ps1 -Path "C:\MyPhotos"
```

### `list_media_dates.ps1`

This script uses ExifTool to extract the `CreateDate` metadata from all specified media files (JPG, PNG, MP4) within a given directory and outputs the information to a CSV file.

**Parameters:**

*   `-Root <string>`: The root directory to search for media files (default: `"."` - current directory).
*   `-OutputFile <string>`: The path to the output CSV file (default: `"media_dates_list.csv"`).
*   `-ExifToolPath <string>`: Optional. The explicit path to the ExifTool executable. If not provided, the script will attempt to find `exiftool.exe` in a local `exiftool-13.33_64` subdirectory or use the one in your system's PATH.

**Examples:**

```powershell
# List CreateDate for media files in C:\MyPhotos and save to default CSV
.\list_media_dates.ps1 -Root "C:\MyPhotos"

# List CreateDate and save to a custom output file
.\list_media_dates.ps1 -Root "C:\MyPhotos" -OutputFile "my_dates.csv"
```

### `move_files.ps1`

This script moves files listed in a source text file to a specified destination directory, preserving their relative path structure. It's useful for isolating media files that might be missing date information or need further processing.

**Parameters:**

*   `-SourceListFile <string>`: Path to the text file containing a list of file paths to move (default: `"files_missing_dates.txt"`). Each line in the file should be a relative or absolute path to a file.
*   `-DestinationBaseDir <string>`: The base directory where files will be moved (default: `"missing_dates_files"`). The script will recreate the source file's directory structure under this base directory.
*   `-LogFile <string>`: Path to the log file where move operations are recorded (default: `"move_files_log.txt"`).
*   `-DryRun`: If specified, the script will only report what it *would* do without actually moving any files.

**Examples:**

```powershell
# Move files listed in files_to_move.txt to a new directory named "quarantine"
.\move_files.ps1 -SourceListFile "files_to_move.txt" -DestinationBaseDir "quarantine"

# Perform a dry run to see which files would be moved
.\move_files.ps1 -DryRun
```

### `update_media_datetime_fast.ps1`

This script updates various date/time metadata tags (e.g., `AllDates`, `CreateDate`, `ModifyDate`) of media files (JPG, PNG, MP4) using information extracted from associated `.json` sidecar files (e.g., Google Photos JSON). It uses ExifTool for efficient batch processing.

**Parameters:**

*   `-Root <string>`: The root directory to search for media and JSON sidecar files (default: `"."` - current directory).
*   `-DryRun`: If specified, performs a dry run without actually modifying files.
*   `-UseLocalTZ <switch>`: If specified, converts timestamps from JSON to the local time zone before writing to Exif metadata. If omitted, UTC is used (default: `$true`).
*   `-ExifToolPath <string>`: Optional. The explicit path to the ExifTool executable. If not provided, the script will attempt to find `exiftool.exe` in a local `exiftool-13.33_64` subdirectory or use the one in your system's PATH.

**Examples:**

```powershell
# Update media dates in C:\MyPhotos using associated JSON files
.\update_media_datetime_fast.ps1 -Root "C:\MyPhotos"

# Perform a dry run to see what date changes would be applied
.\update_media_datetime_fast.ps1 -Root "C:\MyPhotos" -DryRun

# Update dates using UTC timestamps from JSON
.\update_media_datetime_fast.ps1 -Root "C:\MyPhotos" -UseLocalTZ:$false
```

### `verify_media_dates.ps1`

This script uses ExifTool to check if media files (JPG, PNG, MP4) in a given directory have any date/time metadata (e.g., `DateTimeOriginal`, `CreateDate`, `ModifyDate`). It generates a report and outputs a list of files that appear to be missing any date information to a text file.

**Parameters:**

*   `-Root <string>`: The root directory to search for media files (default: `"."` - current directory).
*   `-OutputFile <string>`: The path to the output text file where a list of files missing date information will be written (default: `"files_missing_dates.txt"`).
*   `-ExifToolPath <string>`: Optional. The explicit path to the ExifTool executable. If not provided, the script will attempt to find `exiftool.exe` in a local `exiftool-13.33_64` subdirectory or use the one in your system's PATH.

**Examples:**

```powershell
# Verify media dates in C:\MyPhotos and list files missing dates
.\verify_media_dates.ps1 -Root "C:\MyPhotos"

# Verify media dates and save the list to a custom file
.\verify_media_dates.ps1 -Root "C:\MyPhotos" -OutputFile "my_missing_dates.txt"
