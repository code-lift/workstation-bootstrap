# workstation-bootstrap

Workstation setup for macOS, Linux, WSL Ubuntu, and Windows. Installs developer tools, applies shell and editor settings, and installs a `wst` command for ongoing maintenance.

## Platforms

| Platform | Support |
|----------|---------|
| macOS | ✅ |
| WSL2 Ubuntu | ✅ |
| Linux | ✅ |
| Windows 11 | ✅ |

Windows setup installs Windows-native apps and Windows Terminal. The full developer toolchain (shell, runtimes, CLI tools) runs inside WSL Ubuntu.

## Prerequisites

Install [GitHub CLI](https://cli.github.com) if not already available, then authenticate.

| Platform | Install |
|----------|---------|
| macOS ([Homebrew](https://brew.sh) required) | `brew install gh` |
| WSL Ubuntu / Linux | `sudo apt update && sudo apt install gh -y` |
| Windows | `winget install --id GitHub.cli` |

```sh
gh auth login
```

## Quick Start

### macOS / Linux / WSL Ubuntu

```sh
gh release download latest --repo code-lift/workstation-bootstrap --pattern install.sh -D /tmp/ --clobber && bash /tmp/install.sh
```

Preview runs by default — nothing is changed. The installer shows what to run next.

**Install a specific version (broken latest rescue)**

```sh
bash /tmp/install.sh --version v1.0.0
```

**Inspect before running**

```sh
gh release download latest \
  --repo code-lift/workstation-bootstrap \
  --pattern install.sh -D /tmp/ --clobber
less /tmp/install.sh
bash /tmp/install.sh --apply
```

### Windows

Run in PowerShell:

```powershell
gh release download latest --repo code-lift/workstation-bootstrap --pattern install.ps1 -D $HOME --clobber; Unblock-File "$HOME\install.ps1"; powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

Preview runs by default — nothing is changed. The installer shows what to run next.

### Windows + WSL Ubuntu

After Windows setup, run the WSL preview in PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Wsl
```

Preview runs by default — nothing is changed. The installer shows what to run next.

If a restart is required during the apply step, reboot and run the apply command again. When the Ubuntu prompt appears, create your username and password. Once WSL is ready, open Ubuntu and run the macOS / Linux steps above.

## What Gets Installed

**Core — macOS, Linux, WSL Ubuntu**

| Tool | Purpose |
|------|---------|
| zsh + starship | Shell with prompt |
| tmux | Terminal multiplexer |
| mise | Language runtime manager (Node, Python, Go, …) |
| ripgrep, fd, fzf | Fast search |
| bat, git-delta | Better pager and diff |
| yazi | Terminal file manager |
| gh | GitHub CLI |
| Claude Code, Codex | AI coding CLIs |

**macOS** — packages managed via `manifests/Brewfile`

**WSL Ubuntu / Linux** — packages managed via `manifests/wsl-packages.txt` / `manifests/linux-packages.txt`

**Windows** — apps managed via `manifests/winget.yaml`

**Optional apps** — selected interactively during setup

Browsers, password managers, IDEs, AI desktop apps, office tools, archive tools, media, screen capture, communication, notes, containers, and local LLM tools. Apps already installed are automatically skipped.

## After Setup

The `wst` command is available on all platforms after bootstrap completes:

```sh
wst help                # show command guide
wst help --lang ko      # show guide in Korean
wst doctor              # check installation health
wst preview             # preview available updates
wst upgrade             # apply updates
```

## Installer Options

**macOS / Linux / WSL Ubuntu**

| Option | Description |
|--------|-------------|
| `--apply` | Apply the setup. Default is preview only. |
| `--yes` | Skip confirmation prompts. |
| `--help` | Show usage. |

**Windows**

| Option | Description |
|--------|-------------|
| `-Apply` | Apply the setup. Default is preview only. |
| `-Yes` | Skip confirmation prompts. |
| `-Wsl` | Provision WSL Ubuntu instead of Windows apps. |
| `-Help` | Show usage. |

## Output Labels

| Label | Meaning |
|-------|---------|
| `[todo]` | Will be installed or changed |
| `[ok]` | Already installed or configured |
| `[skip]` | Explicitly skipped |
| `[warn]` | Needs attention or not available on this platform |
| `[next]` | Follow-up step to run manually |
| `[hint]` | Informational suggestion |

## Local Overrides

Managed settings are updated by the installer. Place personal customizations in local files — the installer never overwrites these:

```sh
~/.zshrc.local          # shell aliases, exports, functions
~/.tmux.conf.local      # tmux key bindings and options
~/.gitconfig.local      # git user, signing, extras
```

## Verify

```sh
wst doctor
git --version
node --version
tmux -V
yazi --version
```

Install history is written to `~/.workstation/logs/install.tsv`.

## Troubleshooting

**Windows: script is blocked**

```powershell
Unblock-File "$HOME\install.ps1"
```

**Windows: execution policy blocks the script**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
```

**Capture a log for debugging**

macOS / Linux / WSL Ubuntu:

```sh
bash /tmp/install.sh 2>&1 | tee ~/workstation-bootstrap.log
```

Windows PowerShell:

```powershell
Start-Transcript -Path .\workstation-bootstrap.log
wst preview
Stop-Transcript
```

## Bundle Contents

The release zip (`workstation-bootstrap.zip`) contains plain, readable source files — no obfuscation or binary blobs:

```
workstation-bootstrap/
├── install.sh                    macOS / Linux / WSL installer
├── install.ps1                   Windows installer
├── bootstrap/
│   ├── core.sh                   shared bootstrap logic
│   ├── macos.sh                  macOS entry point
│   ├── linux.sh                  Linux entry point
│   ├── wsl.sh                    WSL Ubuntu entry point
│   ├── lib/                      ui, state, packages, catalog, verify modules
│   └── windows/
│       ├── bootstrap.ps1
│       └── sharex/               ShareX clipboard preset
├── dotfiles/                     chezmoi source state (shell, tmux, git, terminal)
├── manifests/
│   ├── Brewfile                  Homebrew packages (macOS)
│   ├── winget.yaml               Windows apps
│   ├── linux-packages.txt        apt packages (Linux)
│   ├── wsl-packages.txt          apt packages (WSL Ubuntu)
│   ├── mise.toml                 language runtimes
│   └── catalog.yaml              optional app definitions
└── scripts/
    ├── validate-dotfiles.js
    └── validate-catalog.js
```

The installer verifies the bundle against `SHA256SUMS` before extracting.

## Security

- Review the installer before running it.
- Private credentials and account sessions are not managed or synchronized.
