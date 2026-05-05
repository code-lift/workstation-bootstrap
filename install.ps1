param(
    [switch]$Apply,
    [string]$Optional = "",
    [string]$OptionalItems = "",
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DefaultBundleUrl = "https://github.com/code-lift/workstation-bootstrap/releases/latest/download/workstation-bootstrap.zip"
$DefaultSha256Url = "https://github.com/code-lift/workstation-bootstrap/releases/latest/download/SHA256SUMS"
$BundleUrl = if ($env:WORKSTATION_BUNDLE_URL) { $env:WORKSTATION_BUNDLE_URL } else { $DefaultBundleUrl }
$Sha256Url = if ($env:WORKSTATION_SHA256_URL) { $env:WORKSTATION_SHA256_URL } else { "" }

function Show-Usage {
    Write-Output @"
Usage:
  pwsh -NoProfile -File install.ps1 [-Apply] [-Optional <category,...>] [-OptionalItems <id,...>] [-Help]

Public usage:
  irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 | iex
  irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile install.ps1
  pwsh -NoProfile -File .\install.ps1 -Apply

Default:
  Dry-run. Downloads the public bootstrap bundle and runs the Windows bootstrap without making changes.

Options:
  -Apply          Apply changes.
  -Optional       Limit optional item candidates by category.
  -OptionalItems  Select optional item ids directly.
  -Help           Show this help.

Environment:
  WORKSTATION_BUNDLE_URL  Override the bootstrap bundle zip URL.
  WORKSTATION_SHA256_URL  Override the SHA256SUMS URL.

"@
}

if ($Help) {
    Show-Usage
    exit 0
}

function Save-Bundle {
    param(
        [string]$Source,
        [string]$Destination
    )

    if ($Source -match '^file://') {
        $Uri = [System.Uri]$Source
        Copy-Item -LiteralPath $Uri.LocalPath -Destination $Destination
        return
    }

    if (Test-Path -LiteralPath $Source) {
        Copy-Item -LiteralPath $Source -Destination $Destination
        return
    }

    Invoke-WebRequest -Uri $Source -OutFile $Destination
}

function Resolve-Sha256Url {
    if (-not [string]::IsNullOrWhiteSpace($Sha256Url)) {
        return $Sha256Url
    }

    if ($BundleUrl -eq $DefaultBundleUrl) {
        return $DefaultSha256Url
    }

    if ($BundleUrl -match '^file://') {
        $Uri = [System.Uri]$BundleUrl
        $Sibling = Join-Path (Split-Path -Parent $Uri.LocalPath) "SHA256SUMS"
        if (Test-Path -LiteralPath $Sibling) {
            return "file://$Sibling"
        }
        return ""
    }

    try {
        $Uri = [System.Uri]$BundleUrl
        return ([System.Uri]::new($Uri, "SHA256SUMS")).AbsoluteUri
    } catch {
        return ""
    }
}

function Test-BundleChecksum {
    param(
        [string]$ZipPath,
        [string]$SumsSource,
        [string]$SumsPath
    )

    if ([string]::IsNullOrWhiteSpace($SumsSource)) {
        Write-Warning "SHA256SUMS URL 없음. checksum 검증을 건너뜁니다."
        return
    }

    try {
        Save-Bundle -Source $SumsSource -Destination $SumsPath
    } catch {
        if ($BundleUrl -eq $DefaultBundleUrl -or -not [string]::IsNullOrWhiteSpace($env:WORKSTATION_SHA256_URL)) {
            throw "SHA256SUMS 다운로드 실패: $SumsSource"
        }
        Write-Warning "SHA256SUMS 다운로드 실패. custom bundle checksum 검증을 건너뜁니다: $SumsSource"
        return
    }

    $Expected = $null
    foreach ($Line in Get-Content -LiteralPath $SumsPath) {
        if ($Line -match '^([A-Fa-f0-9]{64})\s+workstation-bootstrap\.zip$') {
            $Expected = $Matches[1].ToLowerInvariant()
            break
        }
    }
    if (-not $Expected) {
        throw "SHA256SUMS에 workstation-bootstrap.zip 항목이 없습니다."
    }

    $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash.ToLowerInvariant()
    if ($Actual -ne $Expected) {
        throw "checksum 불일치: workstation-bootstrap.zip expected=$Expected actual=$Actual"
    }
}

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("workstation-bootstrap-" + [System.Guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
    $ZipPath = Join-Path $TempDir "workstation-bootstrap.zip"
    $SumsPath = Join-Path $TempDir "SHA256SUMS"
    Save-Bundle -Source $BundleUrl -Destination $ZipPath
    Test-BundleChecksum -ZipPath $ZipPath -SumsSource (Resolve-Sha256Url) -SumsPath $SumsPath
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    $BootstrapPath = Join-Path $TempDir "workstation-bootstrap/bootstrap/windows.ps1"
    if (-not (Test-Path $BootstrapPath)) {
        throw "bootstrap 파일 없음: workstation-bootstrap/bootstrap/windows.ps1"
    }

    $BootstrapArgs = @()
    if ($Apply) { $BootstrapArgs += "-Apply" }
    if (-not [string]::IsNullOrWhiteSpace($Optional)) { $BootstrapArgs += @("-Optional", $Optional) }
    if (-not [string]::IsNullOrWhiteSpace($OptionalItems)) { $BootstrapArgs += @("-OptionalItems", $OptionalItems) }
    if ($RemainingArgs) { $BootstrapArgs += $RemainingArgs }

    & $BootstrapPath @BootstrapArgs
} finally {
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir
    }
}
