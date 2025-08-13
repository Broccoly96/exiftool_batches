[CmdletBinding()]
param(
  [string]$Root = ".",
  [string]$OutputFile = "media_dates_list.csv",
  [string]$ExifToolPath = ""
)

# --- 初期設定 ---
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}
$scriptDir = Split-Path $MyInvocation.MyCommand.Path

# --- メイン処理 ---

# 1. ExifToolのパスを解決
if (-not [string]::IsNullOrEmpty($ExifToolPath)) {
  $exifTool = $ExifToolPath
} else {
  $exifToolDir = Get-ChildItem -Path $scriptDir -Directory -Filter "exiftool*" | Select-Object -First 1
  if ($exifToolDir) {
    $localExifTool = Join-Path $exifToolDir.FullName "exiftool.exe"
    if (Test-Path -LiteralPath $localExifTool) {
      $exifTool = $localExifTool
      Write-Verbose "Found exiftool at: $exifTool"
    } else {
      $exifTool = "exiftool.exe"
      Write-Verbose "Using exiftool from PATH."
    }
  } else {
    $exifTool = "exiftool.exe"
    Write-Verbose "Using exiftool from PATH."
  }
}

# 2. ExifToolを実行してCreateDateをCSVに出力
Write-Host "Generating CreateDate list for all media files..."
$argList = @(
    "-r",
    "-csv",
    "-CreateDate",
    "-ext", "jpg",
    "-ext", "png",
    "-ext", "mp4",
    $Root
)
$argString = $argList -join ' '

$process = Start-Process -FilePath $exifTool -ArgumentList $argString -Wait -NoNewWindow -RedirectStandardOutput $OutputFile -PassThru
if ($process.ExitCode -eq 0) {
    Write-Host "Successfully created date list: $OutputFile"
} else {
    Write-Warning "ExifTool process finished with exit code: $($process.ExitCode)."
}

Write-Host "`nDone.`n"
