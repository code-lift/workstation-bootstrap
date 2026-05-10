# workstation-bootstrap

Public installer for a practical development workstation baseline on Windows, WSL Ubuntu, Linux, and macOS.

It runs in preview mode by default. Preview shows the plan and lets you select optional apps. Apply installs only the approved items.

## What It Sets Up

Core setup:

- Windows: Windows Terminal and the `wst` setup command.
- macOS, Linux, WSL Ubuntu: shell tools, language runtimes, terminal settings, Git defaults, GitHub CLI, tmux, yazi, search tools, formatters, and the `wst` command guide.
- All platforms: selected optional apps are skipped when they are already installed.

Optional app groups include:

- Browsers and password managers.
- IDEs, AI desktop apps, and optional AI CLI tools.
- Office, documents, archive tools, media, file transfer, and screen capture.
- Developer fonts, terminals, notes, communication, local LLM tools, and containers.

Private credentials are not created, read, or synchronized.

## Quick Start

### Windows

Open **Windows PowerShell** and run:

```powershell
cd $HOME
irm https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.ps1 -OutFile "$HOME\install.ps1"
Unblock-File "$HOME\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

After the first run, use:

```powershell
wst preview
wst upgrade
```

`wst preview` downloads the latest installer and shows the Windows app plan.
`wst upgrade` downloads the latest installer and applies the selected Windows app plan.

### macOS, Linux, or WSL Ubuntu

Preview:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
```

Apply:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## WSL Ubuntu On Windows

The default Windows setup does not require WSL Ubuntu.

If this computer will also use the Linux development environment, run these commands from Windows PowerShell after the Windows setup:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Wsl
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Wsl -Apply
```

If Windows asks for a restart, restart Windows and run the same WSL command again.

When Ubuntu opens for the first time, create the Ubuntu username and password. After the Ubuntu prompt appears, return to PowerShell and continue.

Then open Ubuntu and run:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

## Output Labels

- `[ok]` already ready.
- `[todo]` will be installed or changed during apply.
- `[skip]` already installed, so no action is needed.
- `[next]` follow-up command or step.
- `[warn]` could not be verified in the current shell.

## Optional Apps

Optional apps are selected inside the installer. Run preview first, choose the items you want, then run apply.

Windows:

```powershell
wst preview
wst upgrade
```

macOS, Linux, or WSL Ubuntu:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply
```

The selected optional apps are saved under `~/.workstation/state/`. Apply shows the saved selection again and lets you add or remove items before final confirmation.

## Verify

Windows PowerShell:

```powershell
winget --version
winget list --id Microsoft.WindowsTerminal --exact
wst help
```

macOS, Linux, or WSL Ubuntu:

```sh
wst doctor
wst help
git --version
node --version
tmux -V
yazi --version
```

Install logs are written to:

```text
~/.workstation/logs/install.tsv
```

The log is installation history. Each run still checks the real installed state, so apps removed later are shown as missing again.

## Useful Commands

Windows PowerShell:

| Command | Purpose |
| --- | --- |
| `wst preview` | Preview Windows app setup. |
| `wst upgrade` | Apply Windows app setup. |
| `wst help` | Show Windows setup command help. |

macOS, Linux, or WSL Ubuntu:

| Command | Purpose |
| --- | --- |
| `wst help` | Show the workstation command guide. |
| `wst doctor` | Check core tools and upgrade safety. |
| `wst preview` | Preview baseline updates. |
| `wst upgrade` | Apply baseline updates. |
| `gh auth status` | Check GitHub CLI authentication. |
| `gh repo view` | Open GitHub repository information from the terminal. |
| `tmux new -A -s <name>` | Start or rejoin a persistent terminal session. |
| `yazi` | Browse project files in the terminal. |
| `lazygit` | Use Git from a terminal UI. |
| `rg "<text>"` | Search code quickly. |
| `fd <name>` | Find files and folders quickly. |
| `bat <file>` | Read files with highlighting and line numbers. |
| `btop` | Inspect CPU, memory, disk, and processes. |

## Managed Settings

Managed terminal settings are updated by the installer. Put personal changes in local files:

```text
~/.zshrc.local
~/.tmux.conf.local
~/.gitconfig.local
```

When JetBrains Mono Nerd Font is installed, setup can apply it to supported terminal apps:

- macOS Ghostty uses `~/.config/ghostty/config` when Ghostty is installed.
- Windows Terminal uses `profiles.defaults.font.face`.

Windows Terminal settings are backed up under:

```text
~/.workstation/backups/windows-terminal/
```

## Troubleshooting

If Windows blocks the downloaded script:

```powershell
Unblock-File "$HOME\install.ps1"
```

If PowerShell policy blocks the script:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

Capture a Windows log:

```powershell
Start-Transcript -Path .\workstation-bootstrap.log
wst preview
Stop-Transcript
```

Capture a macOS, Linux, or WSL Ubuntu log:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash 2>&1 | tee workstation-bootstrap.log
```

## Security

- Review the installer before applying it.
- The bundle contains plain source files.
- The installer verifies the release bundle against `SHA256SUMS` when the checksum file is available.
- Private credentials and account sessions are not managed.
