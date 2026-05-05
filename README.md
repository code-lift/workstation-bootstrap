# workstation-bootstrap

Public bootstrap installer for a development workstation. It installs a practical baseline for Windows, WSL/Linux, and macOS, then leaves account login and personal secrets to you.

## What it does

- Installs core command line tools and package manager entries.
- Applies selected dotfiles for zsh, tmux, git, and yazi.
- Installs AI coding CLIs where they are listed in the bootstrap bundle.
- Supports optional package groups when you choose them.
- Runs as a dry-run by default. Nothing is installed unless you pass the apply option.

## Supported platforms

- Windows 11 with Windows PowerShell 5.1 and WSL2 Ubuntu.
- macOS.
- Linux.
- WSL2 Ubuntu.

Windows uses two layers: the Windows host bootstrap installs Windows-native tools and prepares WSL, while the WSL bootstrap configures the Linux development environment inside Ubuntu.

## Quick start

Dry-run on macOS, Linux, or WSL:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
```

Apply on macOS, Linux, or WSL:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

Dry-run on Windows PowerShell 5.1:

```powershell
cd $HOME
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile "$HOME\install.ps1"
Unblock-File "$HOME\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

## Windows setup

Start from Windows PowerShell 5.1. Windows Terminal is useful, but it is not required.

Open PowerShell and run a dry-run first:

```powershell
cd $HOME
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile "$HOME\install.ps1"
Unblock-File "$HOME\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

The Windows installer checks Windows-native packages, WSL optional features, `wsl.exe`, and Ubuntu. In apply mode it can enable the WSL Windows features when PowerShell is running as Administrator.

To apply changes, download the installer and run it explicitly from Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

If WSL features are enabled during apply, restart Windows and run the same command again:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

When WSL is ready and Ubuntu is not installed, the installer runs `wsl --install -d Ubuntu`. Ubuntu may ask you to create a Linux username and password on first launch.

After the Windows host bootstrap finishes, open Ubuntu in WSL and run the Linux bootstrap there:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## macOS setup

Run the dry-run first:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
```

Apply when the plan looks correct:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## WSL/Linux setup

Run this inside your Linux shell:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
```

Apply when ready:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## Dry-run vs apply

The default mode is dry-run. It prints the install plan and avoids changing machine state.

Use `--apply` on macOS, Linux, or WSL:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

Use `-Apply` on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

## Optional items

Optional groups can be selected by category or item id.

macOS, Linux, or WSL:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --optional container
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --optional-items docker_desktop
```

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Optional windows_productivity
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -OptionalItems microsoft_powertoys
```

Add the apply option only after the dry-run output is correct.

## Post-install verification

macOS, Linux, or WSL:

```sh
git --version
chezmoi --version
mise --version
node --version
tmux -V
yazi --version
test -f "$HOME/.zshrc" && echo "zshrc installed"
```

Windows PowerShell:

```powershell
winget --version
git --version
wsl --status
pwsh --version
```

## AI CLI login

AI CLIs are installed as tools only. Sign in after installation using each tool's normal login command.

The installer does not create, copy, or sync tokens, API keys, credentials, or session files.

## Troubleshooting and logs

Capture macOS, Linux, or WSL output:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash 2>&1 | tee workstation-bootstrap.log
```

Capture Windows output:

```powershell
Start-Transcript -Path .\workstation-bootstrap.log
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
Stop-Transcript
```

Use a custom bundle URL for testing:

```sh
WORKSTATION_BUNDLE_URL=https://example.com/workstation-bootstrap.zip bash install.sh
```

```powershell
$env:WORKSTATION_BUNDLE_URL = "https://example.com/workstation-bootstrap.zip"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

If the checksum file is not next to a custom bundle, set it explicitly:

```sh
WORKSTATION_BUNDLE_URL=https://example.com/workstation-bootstrap.zip \
WORKSTATION_SHA256_URL=https://example.com/SHA256SUMS \
bash install.sh
```

```powershell
$env:WORKSTATION_BUNDLE_URL = "https://example.com/workstation-bootstrap.zip"
$env:WORKSTATION_SHA256_URL = "https://example.com/SHA256SUMS"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

## Updating

Run the installer again. It downloads the latest public release bundle by default.

Use dry-run first, then apply:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## Security notes

- Review the installer before applying it.
- The bundle contains plain source files. There is no source obfuscation or encryption.
- Secrets are never generated or synchronized by the installer.
- The default bundle URL points to the latest GitHub Release asset for this public repository.
- The installer verifies `workstation-bootstrap.zip` against `SHA256SUMS` when the checksum file is available.

## Korean Quick Start

기본 실행은 dry-run입니다. 실제 설치는 `--apply` 또는 `-Apply`를 붙여 실행하세요.
