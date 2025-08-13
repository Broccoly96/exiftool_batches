[CmdletBinding()]
param(
  [string]$Root = ".",
  [switch]$DryRun = $false,
  [switch]$UseLocalTZ = $true,
  [string]$ExifToolPath = ""
)

# --- 初期設定 ---
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}
# スクリプトの場所を基準に引数ファイルパスを決定
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$argFile = Join-Path $scriptDir "exiftool_args.txt"


# --- 関数定義 ---
function Get-TimeFromJson {
  param([object]$Json)
  $timeKeys = 'creationTime', 'photoTakenTime', 'imageCreationTime'
  foreach ($key in $timeKeys) {
    if ($Json.PSObject.Properties.Name -contains $key) {
      $timeObject = $Json.$key
      if ($timeObject.PSObject.Properties.Name -contains 'timestamp' -and $timeObject.timestamp) { return [string]$timeObject.timestamp }
      if ($timeObject.PSObject.Properties.Name -contains 'formatted' -and $timeObject.formatted) { return [string]$timeObject.formatted }
    }
  }
  return $null
}

function Convert-ToExifDateString {
  param([string]$value, [bool]$UseLocal)
  if ($value -match '^\d{10}(\d{3})?$') {
    try {
      $epochSeconds = [int64]($value.Substring(0, 10))
      $dto = [DateTimeOffset]::FromUnixTimeSeconds($epochSeconds)
      $dt = if ($UseLocal) { $dto.LocalDateTime } else { $dto.UtcDateTime }
      return $dt.ToString("yyyy:MM:dd HH:mm:ss")
    } catch { return $null }
  }
  try {
    $dto = [DateTimeOffset]::Parse($value)
    $dt = if ($UseLocal) { $dto.LocalDateTime } else { $dto.UtcDateTime }
    return $dt.ToString("yyyy:MM:dd HH:mm:ss")
  } catch { return $null }
}

# --- メイン処理 ---

# 1. ExifToolのパスを解決
if (-not [string]::IsNullOrEmpty($ExifToolPath)) {
  $exifTool = $ExifToolPath
} else {
  $localExifTool = Join-Path $scriptDir "exiftool-13.33_64\exiftool.exe"
  if (Test-Path -LiteralPath $localExifTool) {
    $exifTool = $localExifTool
    Write-Verbose "Found exiftool at: $exifTool"
  } else {
    $exifTool = "exiftool.exe"
    Write-Verbose "Using exiftool from PATH."
  }
}

# 2. 対象JSONファイルを検索
$extensions = @("*.jpg.json", "*.png.json", "*.mp4.json")
$sidecars = Get-ChildItem -Path $Root -Recurse -Include $extensions -File -ErrorAction SilentlyContinue

if ($sidecars.Count -eq 0) {
  Write-Warning "No sidecar files found."
  return
}

# 3. ExifTool用の引数ファイルを生成
Write-Host "Generating arguments for $($sidecars.Count) files..."
$argList = New-Object System.Collections.Generic.List[string]

foreach ($jsonFile in $sidecars) {
  $mediaPath = $jsonFile.FullName -replace '\.json$', ''
  if (-not (Test-Path -LiteralPath $mediaPath)) { continue }

  try {
    $json = Get-Content -LiteralPath $jsonFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch { continue }

  $rawTime = Get-TimeFromJson -Json $json
  if (-not $rawTime) { continue }

  $exifTime = Convert-ToExifDateString -value $rawTime -UseLocal:$UseLocalTZ
  if (-not $exifTime) { continue }

  # 引数ファイルに書き込むコマンドを追加
  $argList.Add("-AllDates=$exifTime")
  $argList.Add("-TrackCreateDate=$exifTime")
  $argList.Add("-TrackModifyDate=$exifTime")
  $argList.Add("-MediaCreateDate=$exifTime")
  $argList.Add("-MediaModifyDate=$exifTime")
  $argList.Add("-Keys:CreationDate=$exifTime")
  $argList.Add("-overwrite_original")
  $argList.Add($mediaPath)
  $argList.Add("-execute")
}

if ($argList.Count -eq 0) {
    Write-Warning "No valid media files found to process."
    return
}

$argList.RemoveAt($argList.Count - 1)
Set-Content -Path $argFile -Value $argList -Encoding UTF8

# 4. ExifToolを一括実行
Write-Host "Executing exiftool for all files. This may take a while..."
$commonArgs = @(
    "-P",
    "-charset", "filename=UTF8",
    "-@",
    $argFile
)

if ($DryRun) {
    Write-Host "[DRY-RUN] ExifTool would be called with the arguments in '$argFile'. No files will be changed."
} else {
    $process = Start-Process -FilePath $exifTool -ArgumentList $commonArgs -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "All files processed successfully."
    } else {
        Write-Warning "ExifTool process finished with exit code: $($process.ExitCode). Check console output for errors."
    }
}

# 5. 後処理
Remove-Item -Path $argFile -ErrorAction SilentlyContinue
Write-Host "`nDone.`n"
