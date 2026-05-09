# workstation-bootstrap

Public setup installer for a development workstation. It installs a practical baseline for Windows, WSL Ubuntu, Linux, and macOS without storing private credentials.

## What it does

- Installs core command line tools and package manager entries.
- Applies selected terminal settings for zsh, tmux, git, search, file preview, and yazi.
- Shows optional apps in an interactive list and installs only the items you select.
- Runs as a preview by default. Nothing is installed unless you pass the apply option.

## Supported platforms

- Windows 11 with Windows PowerShell 5.1.
- macOS.
- Linux.
- WSL Ubuntu.

Windows uses separate layers. The default Windows setup installs Windows apps only. The optional WSL Ubuntu setup prepares Ubuntu for the Linux development environment.

## Install matrix

`Core` is installed by the default setup for that platform. `Optional` is shown in the app picker and installed only when selected. `-` means this setup does not install it on that platform.

| Area | Item | macOS | WSL Ubuntu | Linux | Windows |
| --- | --- | --- | --- | --- | --- |
| Setup guide | wst | Core | Core | Core | - |
| Shell | zsh | Core | Core | Core | - |
| Terminal sessions | tmux | Core | Core | Core | - |
| Terminal file manager | yazi | Core | Core | Core | - |
| Git UI | lazygit | Core | Core | Core | - |
| YAML tool | yq | Core | Core | Core | - |
| Shell formatter | shfmt | Core | Core | Core | - |
| Fast navigation | zoxide | Core | Core | Core | - |
| System monitor | btop | Core | Core | Core | - |
| Search | ripgrep, fd, fzf | Core | Core | Core | - |
| Better output | bat, eza, git-delta | Core | Core | Core | - |
| Runtime manager | mise | Core | Core | Core | - |
| Runtime tools | Node, Python, Go, Bun, uv | Core | Core | Core | - |
| Security checks | gitleaks, shellcheck | Core | Core | Core | - |
| Terminal settings | Managed shell, tmux, git, yazi settings | Core | Core | Core | - |
| Windows terminal | Windows Terminal | - | - | - | Core |
| Password manager | Bitwarden | Optional | - | - | Optional |
| Browser | Google Chrome, Firefox Developer Edition | Optional | - | - | Optional |
| Browser | Microsoft Edge | Optional | - | - | - |
| Office and documents | ONLYOFFICE Desktop Editors, rhwp | Optional | - | - | Optional |
| Archive tools | The Unarchiver | Optional | - | - | - |
| Archive tools | NanaZip | - | - | - | Optional |
| File transfer | LocalSend | Optional | - | - | Optional |
| Media | VLC media player | Optional | - | - | Optional |
| Screen capture | ShareX | - | - | - | Optional |
| Editor or IDE | Google Antigravity, Cursor | Optional | - | - | Optional |
| AI desktop app | Claude Desktop, Codex | Optional | - | - | Optional |
| AI CLI | Codex CLI, Claude Code CLI, Gemini CLI | Optional | Optional | Optional | - |
| Local LLM | LM Studio, Ollama | Optional | - | - | Optional |
| Terminal | Ghostty | Optional | - | - | - |
| Terminal sessions | cmux | Optional | - | - | - |
| Developer font | JetBrains Mono Nerd Font | Optional | - | - | Optional |
| Communication | Slack, KakaoTalk, Telegram | Optional | - | - | Optional |
| Notes | Notion, Obsidian | Optional | - | - | Optional |
| macOS productivity | Raycast, Rectangle, Karabiner-Elements | Optional | - | - | - |
| Windows productivity | Microsoft PowerToys, Everything, PowerShell 7 | - | - | - | Optional |
| Containers | Docker Desktop | Optional | - | - | Optional |

## Useful commands

These commands are installed or enabled by the core setup on macOS, WSL Ubuntu, and Linux.

| Command | What to use it for |
| --- | --- |
| `wst help` | Show workstation commands and the core command guide. |
| `wst doctor` | Check core tools and upgrade safety. |
| `wst preview` | Preview the latest workstation setup after doctor passes. |
| `wst upgrade` | Apply the latest workstation setup after doctor passes. |
| `wst diff` | Show direct edits in managed terminal settings. |
| `wst repair` | Move safe local additions to `.local` files. |
| `~/.workstation/contract.md` | See managed settings and safe local edit paths. |
| `tmux new -A -s main` | Keep a durable coding session open. |
| `yazi` | Browse project files without leaving the terminal. |
| `lazygit` | Stage, commit, branch, pull, and push faster. |
| `btop` | Find CPU, memory, disk, or process pressure. |
| `rg "text"` | Search code fast without opening an editor. |
| `fd name` | Find files and folders by name. |
| `bat file` | Read files with highlighting and line numbers. |
| `z name` | Jump to a folder you use often. |
| `mkcd dir` | Create a directory and enter it. |
| `croot` | Jump to the current Git repository root. |
| `gs` | Show short Git status and current branch. |
| `gd` | Show unstaged diff. |
| `gds` | Show staged diff. |
| `gl` | Show a compact commit graph. |
| `gitleaks detect` | Scan the repository for exposed credentials. |
| `shellcheck script.sh` | Catch common shell script bugs. |
| `shfmt -w script.sh` | Format shell scripts in place. |
| `jq '.key' file.json` | Read and transform JSON. |
| `yq '.key' file.yaml` | Read YAML, JSON, TOML, or XML values. |
| `mise list` | Show installed language runtimes. |
| `mise use node@22` | Pin a runtime version for the current project. |
| `node --version` | Check the active Node.js version. |
| `python --version` | Check the active Python version. |
| `bun --version` | Check the active Bun version. |
| `uv --version` | Check the active uv version. |

Optional AI CLI commands are available only when selected during optional setup.

| Command | What to use it for |
| --- | --- |
| `codex` | Start an OpenAI Codex terminal coding session. |
| `claude` | Start a Claude Code terminal coding session. |
| `gemini` | Start a Gemini CLI terminal coding session. |

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

The default Windows installer checks and installs Windows apps only.

Windows output uses these labels:

- `[ok]` means the item is already ready.
- `[todo]` means the installer will change it when you apply.
- `[next]` means a later step is required.
- `[warn]` means the installer could not check or use something in the current shell.

The Windows step installs Windows Terminal by default. Other Windows apps are shown as optional items and installed only when selected.

Claude Desktop and Codex are also available in the optional Windows app list.

To apply changes, download the installer and run it explicitly from Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

The default Windows setup does not require WSL Ubuntu.

For Linux development on Windows, prepare WSL Ubuntu separately:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Wsl
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Wsl -Apply
```

Restart is not always required. If WSL support is already enabled, the WSL setup continues without a restart. If WSL support is enabled during apply, restart Windows and run the same WSL command again.

When WSL support is ready and WSL Ubuntu is not installed, the WSL setup installs WSL Ubuntu first. It then opens an Ubuntu window so you can complete Ubuntu user setup. Return to the PowerShell window after Ubuntu shows a shell prompt, then answer `y` to continue.

After WSL Ubuntu setup finishes, open WSL Ubuntu and run the Linux setup there:

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

Apply mode ends with a final installation check. It re-checks the installed packages, command-line tools, language runtimes, terminal settings, and selected optional apps. Items that are ready are printed with `[ok]`; anything still missing is printed with `[warn]`. When verification passes, it also prints the next commands to run.

After setup, run `wst help` any time to see the command guide again. Run `wst doctor` to check core tools and upgrade safety from a new shell.

Managed terminal settings are updated by workstation. Put custom shell, tmux, and Git settings in:

```text
~/.zshrc.local
~/.tmux.conf.local
~/.gitconfig.local
```

## Optional items

Optional apps are selected interactively in a terminal list. In non-interactive automation, item ids can be passed directly.

Common optional apps:

| Area | Item | What it is for |
| --- | --- | --- |
| Office and documents | ONLYOFFICE Desktop Editors | Free desktop editor for Word, Excel, PowerPoint, and PDF files. |
| Office and documents | rhwp | Open-source HWP/HWPX tool for Korean document viewing and conversion. |
| Archive tools | The Unarchiver | macOS archive extractor for RAR, 7z, old ZIP encodings, and uncommon compressed files. |
| Archive tools | NanaZip | Windows 7-Zip based archiver for ZIP, 7z, RAR, and TAR files. |
| File transfer | LocalSend | AirDrop-like local file transfer between Windows, macOS, Linux, Android, and iOS. |
| Media | VLC media player | Free media player that opens most video and audio files without extra codecs. |
| Screen capture | ShareX | Windows screenshot and screen recording tool with annotation and automation workflows. |
| Windows productivity | Everything | Instant Windows file search that is much faster than Start search. |

macOS, Linux, or WSL Ubuntu:

```sh
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --optional container
curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --optional-items onlyoffice,rhwp,localsend,vlc
```

`--optional` limits the list by category. It does not install a whole category by itself. In preview mode, selected optional items are saved under `~/.workstation/state/<os>-optional.txt`; apply mode shows that saved selection again and lets you add or remove items before the final confirmation.

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -Apply
```

Add the apply option only after the preview output is correct.

Advanced Windows automation can pass item ids directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\install.ps1" -OptionalItems onlyoffice,rhwp,nanazip,localsend,vlc,sharex,everything_search
```

## Post-install verification

macOS, Linux, or WSL Ubuntu:

```sh
git --version
mise --version
node --version
tmux -V
yazi --version
lazygit --version
yq --version
shfmt --version
test -f "$HOME/.zshrc" && echo "zshrc installed"
```

Windows PowerShell:

```powershell
winget --version
winget list --id Microsoft.WindowsTerminal --exact
```

Optional Windows checks:

```powershell
pwsh --version
winget list --id ONLYOFFICE.DesktopEditors --exact
winget list --id M2Team.NanaZip --exact
winget list --id LocalSend.LocalSend --exact
winget list --id VideoLAN.VLC --exact
winget list --id ShareX.ShareX --exact
winget list --id voidtools.Everything --exact
Test-Path "$HOME\.workstation\bin\rhwp.exe"
wsl -d Ubuntu -- sh -lc 'echo ready'
```

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
