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
  irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile "`$HOME\install.ps1"
  Unblock-File "`$HOME\install.ps1"
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1"
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1" -Apply

Default:
  Preview mode. Downloads the setup bundle and shows what will happen without changing this computer.

Options:
  -Apply          Apply the selected setup.
  -Yes            Skip the apply confirmation prompt for automation.
  -Optional       Limit the optional app list by category.
  -OptionalItems  Advanced: select optional app ids directly.
  -Help           Show this help.

WSL Ubuntu setup:
  Run from Windows PowerShell 5.1 first.
  -Apply opens Administrator PowerShell when WSL support needs elevated changes.
  If a reboot is required, restart Windows and run the same command again.

Environment:
  WORKSTATION_BUNDLE_URL  Override the setup bundle zip URL.
  WORKSTATION_SHA256_URL  Override the SHA256SUMS URL.

"@
}

if ($Help) {
    Show-Usage
    exit 0
}

function Get-ItemCount {
    param([object]$Value)
    if ($null -eq $Value) { return 0 }
    return @($Value).Count
}

$ParsedRemainingArgs = @($RemainingArgs)
$ParsedRemainingArgCount = Get-ItemCount -Value $ParsedRemainingArgs
for ($ArgIndex = 0; $ArgIndex -lt $ParsedRemainingArgCount; $ArgIndex++) {
    $Arg = $ParsedRemainingArgs[$ArgIndex]
    if ($Arg -in @("-Apply", "--apply")) {
        $Apply = $true
        continue
    }
    if ($Arg -in @("-Yes", "--yes")) {
        $Yes = $true
        continue
    }
    if ($Arg -in @("-Optional", "--optional") -and $ArgIndex + 1 -lt $ParsedRemainingArgCount) {
        $ArgIndex += 1
        $Optional = $ParsedRemainingArgs[$ArgIndex]
        continue
    }
    if ($Arg -in @("-OptionalItems", "--optional-items") -and $ArgIndex + 1 -lt $ParsedRemainingArgCount) {
        $ArgIndex += 1
        $OptionalItems = $ParsedRemainingArgs[$ArgIndex]
        continue
    }
}

function Test-Administrator {
    try {
        $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
        return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Quote-PowerShellLiteral {
    param([string]$Value)
    return "'" + ($Value -replace "'", "''") + "'"
}

function Start-ElevatedApply {
    if (-not $Apply -or (Test-Administrator)) {
        return
    }

    $Command = "& " + (Quote-PowerShellLiteral -Value $PSCommandPath) + " -Apply"
    if ($Yes) {
        $Command += " -Yes"
    }
    if (-not [string]::IsNullOrWhiteSpace($Optional)) {
        $Command += " -Optional " + (Quote-PowerShellLiteral -Value $Optional)
    }
    if (-not [string]::IsNullOrWhiteSpace($OptionalItems)) {
        $Command += " -OptionalItems " + (Quote-PowerShellLiteral -Value $OptionalItems)
    }

    $EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
    Write-Output "[next] Opening Administrator PowerShell for Windows setup."
    Write-Output "[next] Continue in the new Administrator PowerShell window."
    Start-Process powershell -Verb RunAs -ArgumentList @(
        "-NoExit",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-EncodedCommand",
        $EncodedCommand
    )
    exit 0
}

Start-ElevatedApply

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
        Write-Warning "Checksum file is not configured. Skipping download verification."
        return
    }

    try {
        Save-Bundle -Source $SumsSource -Destination $SumsPath
    } catch {
        if ($BundleUrl -eq $DefaultBundleUrl -or -not [string]::IsNullOrWhiteSpace($env:WORKSTATION_SHA256_URL)) {
            throw "Failed to download checksum file."
        }
        Write-Warning "Failed to download checksum file. Skipping verification for custom bundle."
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
        throw "Checksum file does not include the setup bundle."
    }

    $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash.ToLowerInvariant()
    if ($Actual -ne $Expected) {
        throw "Setup bundle verification failed."
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
        throw "Windows setup file was not found in the downloaded bundle."
    }

    $BootstrapParams = @{}
    if ($Apply) { $BootstrapParams["Apply"] = $true }
    if ($Yes) { $BootstrapParams["Yes"] = $true }
    if (-not [string]::IsNullOrWhiteSpace($Optional)) { $BootstrapParams["Optional"] = $Optional }
    if (-not [string]::IsNullOrWhiteSpace($OptionalItems)) { $BootstrapParams["OptionalItems"] = $OptionalItems }

    & $BootstrapPath @BootstrapParams
} finally {
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir
    }
}
