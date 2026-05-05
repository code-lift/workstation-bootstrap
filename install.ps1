param(
    [switch]$Apply,
    [switch]$Yes,
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

try {
    if (Get-Command chcp.com -ErrorAction SilentlyContinue) {
        chcp.com 65001 *> $null
    }
    $Utf8Encoding = New-Object System.Text.UTF8Encoding
    [Console]::OutputEncoding = $Utf8Encoding
    $OutputEncoding = $Utf8Encoding
} catch {
    Write-Warning "UTF-8 console setup failed. Continuing with the current console encoding."
}

function Show-Usage {
    Write-Output @"
Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1" [-Apply] [-Yes] [-Optional <category,...>] [-OptionalItems <id,...>] [-Help]

Public usage:
  cd `$HOME
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile "`$HOME\install.ps1"
  Unblock-File "`$HOME\install.ps1"
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1"
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1" -Apply

Default:
  Dry-run. Downloads the public bootstrap bundle, checks Windows host packages, WSL features, and Ubuntu readiness without making changes.

Options:
  -Apply          Apply changes.
  -Yes            Skip the apply confirmation prompt for automation.
  -Optional       Limit the interactive optional app list by category.
  -OptionalItems  Advanced: select optional item ids directly.
  -Help           Show this help.

Windows WSL setup:
  Run from Windows PowerShell 5.1 first.
  -Apply can enable WSL Windows features from an elevated PowerShell session.
  If a reboot is required, restart Windows and run the same command again.

Environment:
  WORKSTATION_BUNDLE_URL  Override the bootstrap bundle zip URL.
  WORKSTATION_SHA256_URL  Override the SHA256SUMS URL.

"@
}

if ($Help) {
    Show-Usage
    exit 0
}

$ParsedRemainingArgs = @($RemainingArgs)
for ($ArgIndex = 0; $ArgIndex -lt $ParsedRemainingArgs.Count; $ArgIndex++) {
    $Arg = $ParsedRemainingArgs[$ArgIndex]
    if ($Arg -in @("-Apply", "--apply")) {
        $Apply = $true
        continue
    }
    if ($Arg -in @("-Yes", "--yes")) {
        $Yes = $true
        continue
    }
    if ($Arg -in @("-Optional", "--optional") -and $ArgIndex + 1 -lt $ParsedRemainingArgs.Count) {
        $ArgIndex += 1
        $Optional = $ParsedRemainingArgs[$ArgIndex]
        continue
    }
    if ($Arg -in @("-OptionalItems", "--optional-items") -and $ArgIndex + 1 -lt $ParsedRemainingArgs.Count) {
        $ArgIndex += 1
        $OptionalItems = $ParsedRemainingArgs[$ArgIndex]
        continue
    }
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
        Write-Warning "SHA256SUMS URL is not configured. Skipping checksum verification."
        return
    }

    try {
        Save-Bundle -Source $SumsSource -Destination $SumsPath
    } catch {
        if ($BundleUrl -eq $DefaultBundleUrl -or -not [string]::IsNullOrWhiteSpace($env:WORKSTATION_SHA256_URL)) {
            throw "Failed to download SHA256SUMS: $SumsSource"
        }
        Write-Warning "Failed to download SHA256SUMS. Skipping checksum verification for custom bundle: $SumsSource"
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
        throw "SHA256SUMS does not contain workstation-bootstrap.zip."
    }

    $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash.ToLowerInvariant()
    if ($Actual -ne $Expected) {
        throw "Checksum mismatch: workstation-bootstrap.zip expected=$Expected actual=$Actual"
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
        throw "Bootstrap file not found: workstation-bootstrap/bootstrap/windows.ps1"
    }

    $BootstrapParams = @{}
    if ($Apply) { $BootstrapParams["Apply"] = $true }
    if ($Yes) { $BootstrapParams["Yes"] = $true }
    if (-not [string]::IsNullOrWhiteSpace($Optional)) { $BootstrapParams["Optional"] = $Optional }
    if (-not [string]::IsNullOrWhiteSpace($OptionalItems)) { $BootstrapParams["OptionalItems"] = $OptionalItems }

    Write-Output ("Installer mode: {0}" -f $(if ($Apply) { "apply" } else { "dry-run" }))
    & $BootstrapPath @BootstrapParams
} finally {
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir
    }
}
