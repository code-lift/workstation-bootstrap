# workstation-bootstrap

Public setup installer for a development workstation. It installs a practical baseline for Windows, WSL Ubuntu, Linux, and macOS, then leaves account login and private credentials to you.

## What it does

- Installs core command line tools and package manager entries.
- Applies selected terminal settings for zsh, tmux, git, search, file preview, and yazi.
- Installs AI coding tools where they are listed in the setup bundle.
- Shows optional apps in an interactive list and installs only the items you select.
- Runs as a preview by default. Nothing is installed unless you pass the apply option.

## Supported platforms

- Windows 11 with Windows PowerShell 5.1 and WSL Ubuntu.
- macOS.
- Linux.
- WSL Ubuntu.

Windows uses two layers: the Windows setup installs Windows apps and prepares WSL Ubuntu, while the WSL setup configures the Linux development environment inside WSL Ubuntu.

## Quick start

Preview on macOS, Linux, or WSL Ubuntu:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
```

Apply on macOS, Linux, or WSL Ubuntu:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

Preview on Windows PowerShell 5.1:

```powershell
cd $HOME
irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile "$HOME\install.ps1"
Unblock-File "$HOME\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

## Windows setup

Start from Windows PowerShell 5.1. Windows Terminal is useful, but it is not required.

Open PowerShell and run a preview first:

```powershell
cd $HOME
irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile "$HOME\install.ps1"
Unblock-File "$HOME\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

The Windows installer checks Windows apps, WSL support, and WSL Ubuntu. In apply mode it opens Administrator PowerShell when elevated changes are needed.

Windows output uses these labels:

- `[ok]` means the item is already ready.
- `[todo]` means the installer will change it when you apply.
- `[next]` means a later step is required, usually after Windows restart or WSL Ubuntu is ready.
- `[warn]` means the installer could not check or use something in the current shell.

The Windows step installs only Windows apps such as Windows Terminal, Git for Windows, GitHub CLI, and WSL Ubuntu readiness. The main command line development tools are installed later inside WSL Ubuntu.

To apply changes, download the installer and run it explicitly from Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

Restart is not always required. If WSL support is already enabled, the installer continues without a restart. If WSL support is enabled during apply, restart Windows and run the same command again:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

When WSL support is ready and WSL Ubuntu is not installed, the installer installs WSL Ubuntu first. It then opens an Ubuntu window so you can complete Ubuntu user setup. Return to the PowerShell window after Ubuntu shows a shell prompt, then answer `y` to continue.

After the Windows setup finishes, open WSL Ubuntu and run the Linux setup there:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## macOS setup

Run the preview first:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
```

Apply when the plan looks correct:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## Ubuntu/Linux setup

Run this inside your Linux shell:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
```

Apply when ready:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## Preview vs apply

The default mode is preview. It prints the setup plan and avoids changing machine state.

Use `--apply` on macOS, Linux, or WSL Ubuntu:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

Use `-Apply` on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

Windows apply mode asks for confirmation before changing the machine. Use `-Yes` only for trusted automation after reviewing the preview output.

Successful package and app installs are recorded under `~/.workstation/logs/install.tsv`. On later runs, the installer uses that log together with a live install check; an item is skipped only when it was previously completed and is still installed.

## Optional items

Optional apps are selected interactively in a terminal list. In non-interactive automation, item ids can be passed directly.

macOS, Linux, or WSL Ubuntu:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --optional container
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --optional-items docker_desktop
```

`--optional` limits the list by category. It does not install a whole category by itself. In preview mode, selected optional items are saved under `~/.workstation/state/<os>-optional.txt`; apply mode shows that saved selection again and lets you add or remove items before the final confirmation.

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

Add the apply option only after the preview output is correct.

## Post-install verification

macOS, Linux, or WSL Ubuntu:

```sh
git --version
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
wsl -d Ubuntu -- sh -lc 'echo ready'
pwsh --version
```

## AI CLI login

AI CLIs are installed as tools only. Sign in after installation using each tool's normal login command.

The installer does not create, copy, or sync tokens, API keys, credentials, or session files.

## Troubleshooting and logs

If Windows blocks the downloaded script, run this in the same PowerShell window and try again:

```powershell
Unblock-File "$HOME\install.ps1"
```

If your PowerShell policy still blocks the script, use a process-only bypass for the current window:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

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

Use preview first, then apply:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## Security notes

- Review the installer before applying it.
- The bundle contains plain source files. There is no source obfuscation or encryption.
- Private credentials are never generated or synchronized by the installer.
- The default bundle URL points to the latest GitHub Release asset for this public repository.
- The installer verifies `workstation-bootstrap.zip` against `SHA256SUMS` when the checksum file is available.
