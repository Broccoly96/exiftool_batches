[CmdletBinding()]
param(
  [string]$Root = ".",
  [string]$OutputFile = "files_missing_dates.txt",
  [string]$ExifToolPath = ""
)

# --- 初期設定 ---
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$csvReport = Join-Path $scriptDir "date_report.csv"

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

# 2. ExifToolを実行して日付情報をCSVに出力
Write-Host "Generating date report for all media files... (This may take a moment)"
$dateTags = @(
    "-DateTimeOriginal",
    "-CreateDate",
    "-ModifyDate",
    "-TrackCreateDate",
    "-TrackModifyDate",
    "-MediaCreateDate",
    "-MediaModifyDate",
    "-Keys:CreationDate"
)
# 引数リストをフラットなリストとして構築
$argList = New-Object System.Collections.Generic.List[string]
$argList.Add("-r")
$argList.Add("-csv")
$argList.AddRange([string[]]$dateTags)
$argList.Add("-ext")
$argList.Add("jpg")
$argList.Add("-ext")
$argList.Add("png")
$argList.Add("-ext")
$argList.Add("mp4")
$argList.Add($Root)

# 引数リストを単一の文字列に結合
$argString = $argList -join ' '
# Start-Processを使用してCSVファイルに直接出力
$process = Start-Process -FilePath $exifTool -ArgumentList $argString -Wait -NoNewWindow -RedirectStandardOutput $csvReport -PassThru
if ($process.ExitCode -ne 0) {
    Write-Warning "ExifTool may have encountered errors. Check the console output."
}

if (-not (Test-Path $csvReport)) {
    Write-Error "Failed to generate date report CSV."
    return
}

# 3. CSVを読み込み、日付がないファイルを特定
Write-Host "Analyzing report to find files missing date information..."
$missingFiles = New-Object System.Collections.Generic.List[string]
$report = Import-Csv -Path $csvReport

# CSVのヘッダーから日付タグの列名を取得 (SourceFileを除く)
$dateColumns = $report | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne 'SourceFile' } | Select-Object -ExpandProperty Name

foreach ($row in $report) {
    $hasDate = $false
    foreach ($col in $dateColumns) {
        if (-not [string]::IsNullOrEmpty($row.$col)) {
            $hasDate = $true
            break # 日付が一つでも見つかればループを抜ける
        }
    }

    if (-not $hasDate) {
        $missingFiles.Add($row.SourceFile)
    }
}

# 4. 結果をファイルに出力
if ($missingFiles.Count -gt 0) {
    Write-Host "Found $($missingFiles.Count) files missing date information."
    Set-Content -Path $OutputFile -Value $missingFiles -Encoding UTF8
    Write-Host "List of files saved to: $OutputFile"
} else {
    Write-Host "All media files seem to have date information."
    # 空のファイルを作成して、結果が空であることを示す
    Set-Content -Path $OutputFile -Value "No files found missing date information." -Encoding UTF8
}

# 5. 後処理
Remove-Item -Path $csvReport -ErrorAction SilentlyContinue
Write-Host "`nDone.`n"
