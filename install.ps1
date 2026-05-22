param(
    [switch]$Apply,
    [switch]$Yes,
    [switch]$Wsl,
    [switch]$Help,
    [string]$Version = "latest",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$BootstrapRepo = if ($env:WST_BOOTSTRAP_REPO) { $env:WST_BOOTSTRAP_REPO } else { "code-lift/workstation-bootstrap" }
$WorkstationBundleUrl = if ($env:WORKSTATION_BUNDLE_URL) { $env:WORKSTATION_BUNDLE_URL } else { "" }

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
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1" [-Apply] [-Yes] [-Wsl] [-Version <tag>] [-Help]

Setup (one-time, if not already done):
  gh auth login

Download and run:
  gh release download latest --repo code-lift/workstation-bootstrap --pattern install.ps1 -D `$HOME --clobber
  Unblock-File "`$HOME\install.ps1"
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1"
  wst preview
  wst upgrade

Inspect first:
  gh release download latest --repo code-lift/workstation-bootstrap --pattern install.ps1 -D `$HOME --clobber
  Get-Content "`$HOME\install.ps1" | more
  powershell -NoProfile -ExecutionPolicy Bypass -File "`$HOME\install.ps1"

Default:
  Preview mode. Downloads the setup bundle and shows what will happen without changing this computer.

Options:
  -Apply          Apply the selected setup.
  -Yes            Skip the apply confirmation prompt for automation.
  -Wsl            Prepare WSL Ubuntu instead of Windows apps.
  -Version <tag>  Install a specific release (e.g. v1.0.0). Default: latest.
  -Help           Show this help.

Installed Windows command:
  wst preview       Download the latest installer and preview Windows app setup.
  wst upgrade       Download the latest installer and apply Windows app setup.

WSL Ubuntu setup:
  Use -Wsl when this computer will run the Linux development setup through WSL Ubuntu.
  If a reboot is required, restart Windows and run the same -Wsl command again.

Environment:
  WORKSTATION_BUNDLE_URL  Override with a local file:// path for testing.
  WST_BOOTSTRAP_REPO      Override the bootstrap repository.

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

function Add-DirectoryToUserPath {
    param([string]$Directory)

    if ([string]::IsNullOrWhiteSpace($Directory)) { return }
    $currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $segments = @()
    if (-not [string]::IsNullOrWhiteSpace($currentUserPath)) {
        $segments = @($currentUserPath.Split(";") | Where-Object { $_ })
    }

    $alreadyPresent = $false
    foreach ($segment in $segments) {
        if ($segment.TrimEnd("\") -ieq $Directory.TrimEnd("\")) {
            $alreadyPresent = $true
            break
        }
    }

    if (-not $alreadyPresent) {
        $newPath = if ([string]::IsNullOrWhiteSpace($currentUserPath)) { $Directory } else { "$currentUserPath;$Directory" }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    }

    if (($env:Path -split ";") -notcontains $Directory) {
        $env:Path = "$Directory;$env:Path"
    }
}

function Install-WindowsWstCommand {
    $binDir = Join-Path $HOME ".workstation\bin"
    $psPath = Join-Path $binDir "wst.ps1"
    $cmdPath = Join-Path $binDir "wst.cmd"
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null

    $script = @'
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = "Stop"
$BootstrapRepo = if ($env:WST_BOOTSTRAP_REPO) { $env:WST_BOOTSTRAP_REPO } else { "code-lift/workstation-bootstrap" }
$InstallerPath = Join-Path $HOME "install.ps1"

function Show-Help {
    Write-Output @"
wst - Windows workstation setup

Usage:
  wst preview        Preview Windows app setup and choose optional apps
  wst upgrade        Apply the selected Windows app setup
  wst help           Show this command guide
  wst help --lang ko Show this guide in Korean

Flow:
  1. Run wst preview.
  2. Select optional apps inside the preview.
  3. Run wst upgrade.
  4. Confirm the final plan.

Windows and WSL:
  Windows PowerShell       wst preview / wst upgrade manage Windows apps
  WSL Ubuntu               wst preview / wst upgrade manage Linux dev tools
"@
}

function Show-HelpKo {
    Write-Output @"
wst - Windows 워크스테이션 설정

사용법:
  wst preview        Windows 앱 설치 계획을 미리 보고 선택 항목을 고릅니다
  wst upgrade        선택한 Windows 앱 설치 계획을 적용합니다
  wst help           이 명령어 가이드를 봅니다
  wst help --lang ko 한국어로 이 가이드를 봅니다

진행 순서:
  1. wst preview를 실행합니다.
  2. 화면에 나온 선택 앱 중 필요한 항목을 고릅니다.
  3. wst upgrade를 실행합니다.
  4. 마지막 확인 후 설치를 진행합니다.

Windows와 WSL:
  Windows PowerShell       wst preview / wst upgrade는 Windows 앱을 관리합니다
  WSL Ubuntu               wst preview / wst upgrade는 Linux 개발 도구를 관리합니다
"@
}

function Download-Installer {
    $TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("wst-installer-" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $TmpDir | Out-Null
    try {
        & gh release download latest --repo "$BootstrapRepo" --pattern 'install.ps1' --dir "$TmpDir" --clobber
        if ($LASTEXITCODE -ne 0) { throw "Failed to download installer." }
        Copy-Item -LiteralPath (Join-Path $TmpDir "install.ps1") -Destination $InstallerPath -Force
    } finally {
        if (Test-Path $TmpDir) { Remove-Item -Recurse -Force $TmpDir }
    }
    if (Get-Command Unblock-File -ErrorAction SilentlyContinue) {
        Unblock-File $InstallerPath
    }
}

$command = if ($Args.Count -gt 0) { $Args[0].ToLowerInvariant() } else { "preview" }
$installerArgs = @()

if ($command -eq "help" -or $command -eq "-h" -or $command -eq "--help") {
    if ($Args.Count -eq 1) {
        Show-Help
        exit 0
    }
    if ($Args.Count -eq 3 -and $Args[1] -eq "--lang" -and $Args[2] -eq "ko") {
        Show-HelpKo
        exit 0
    }
    if ($Args.Count -eq 3 -and $Args[1] -eq "--lang" -and $Args[2] -eq "en") {
        Show-Help
        exit 0
    }
    Write-Error "Unknown argument: $($Args[1])"
    Show-Help
    exit 2
}

if ($Args.Count -gt 1) {
    Write-Error "Unknown argument: $($Args[1])"
    Show-Help
    exit 2
}

switch ($command) {
    "preview" {
    }
    "upgrade" {
        $installerArgs += "-Apply"
    }
    default {
        Write-Error "Unknown command: $command"
        Show-Help
        exit 2
    }
}

Download-Installer
& powershell -NoProfile -ExecutionPolicy Bypass -File $InstallerPath @installerArgs
exit $LASTEXITCODE
'@

    Set-Content -Path $psPath -Value $script -Encoding UTF8

    $cmd = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.workstation\bin\wst.ps1" %*
'@
    Set-Content -Path $cmdPath -Value $cmd -Encoding ASCII
    Add-DirectoryToUserPath -Directory $binDir
}

Install-WindowsWstCommand

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
    if ($Arg -in @("-Wsl", "--wsl", "-WithWsl", "--with-wsl")) {
        $Wsl = $true
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
    if (-not $Apply -or -not $Wsl -or (Test-Administrator)) {
        return
    }

    $Command = "& " + (Quote-PowerShellLiteral -Value $PSCommandPath) + " -Apply"
    if ($Yes) {
        $Command += " -Yes"
    }
    $Command += " -Wsl"

    $EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
    Write-Output "[next] Opening Administrator PowerShell for WSL Ubuntu setup."
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

function Ensure-GhAuth {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI (gh) is required to download the setup bundle. Install from: https://cli.github.com"
    }
    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub authentication required. Run: gh auth login"
    }
}

function Get-Bundle {
    param(
        [string]$ZipPath,
        [string]$SumsPath,
        [string]$Version = "latest"
    )
    $OutputDir = Split-Path -Parent $ZipPath

    if (-not [string]::IsNullOrWhiteSpace($WorkstationBundleUrl)) {
        if ($WorkstationBundleUrl -notmatch '^file://') {
            Write-Warning "WORKSTATION_BUNDLE_URL must be a file:// path. Ignoring."
        } else {
            $Uri = [System.Uri]$WorkstationBundleUrl
            Copy-Item -LiteralPath $Uri.LocalPath -Destination $ZipPath
            $Sibling = Join-Path (Split-Path -Parent $Uri.LocalPath) "SHA256SUMS"
            if (Test-Path -LiteralPath $Sibling) {
                Copy-Item -LiteralPath $Sibling -Destination $SumsPath
            }
            return
        }
    }

    Ensure-GhAuth
    & gh release download "$Version" `
        --repo "$BootstrapRepo" `
        --pattern 'workstation-bootstrap.zip' `
        --pattern 'SHA256SUMS' `
        --dir $OutputDir `
        --clobber
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download release '$Version' from '$BootstrapRepo'. Check available releases: gh release list --repo $BootstrapRepo"
    }
}

function Test-BundleChecksum {
    param(
        [string]$ZipPath,
        [string]$SumsPath
    )

    if (-not (Test-Path -LiteralPath $SumsPath)) {
        throw "Checksum file was not included in the release. Cannot verify bundle integrity."
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
    Get-Bundle -ZipPath $ZipPath -SumsPath $SumsPath -Version $Version
    Test-BundleChecksum -ZipPath $ZipPath -SumsPath $SumsPath
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    $BootstrapPath = Join-Path $TempDir "workstation-bootstrap/bootstrap/windows/windows.ps1"
    if (-not (Test-Path $BootstrapPath)) {
        throw "Windows setup file was not found in the downloaded bundle."
    }

    $BootstrapParams = @{}
    if ($Apply) { $BootstrapParams["Apply"] = $true }
    if ($Yes) { $BootstrapParams["Yes"] = $true }
    if ($Wsl) { $BootstrapParams["Wsl"] = $true }

    & $BootstrapPath @BootstrapParams

    if (-not $Apply) {
        Write-Output ""
        Write-Output "Next steps"
        if ($Wsl) {
            Write-Output "[next] powershell -NoProfile -ExecutionPolicy Bypass -File `"$HOME\install.ps1`" -Apply -Wsl"
        } else {
            Write-Output "[next] Open a new terminal"
            Write-Output "[next] Run: wst upgrade"
        }
    } elseif (-not $Wsl) {
        Write-Output ""
        Write-Output "Next steps"
        Write-Output "[next] powershell -NoProfile -ExecutionPolicy Bypass -File `"$HOME\install.ps1`" -Wsl"
    }
} finally {
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir
    }
}
