# Felis Shell

[![CI](https://github.com/afif25fradana/felis-shell/actions/workflows/ci.yml/badge.svg)](https://github.com/afif25fradana/felis-shell/actions/workflows/ci.yml)

A modular Bash configuration framework providing structured aliases, git-aware prompt status, platform detection (WSL2 / Linux), and developer workflow helpers.

> [!NOTE]
> **A quick note on this repo:**
> This repository was my very first project when I first joined GitHub, back when I was dual-booting Linux on my old laptop! That's why the early commit history might look like a bit of a joke or a playground of experiments. Keeping this repo alive and updated for WSL2 is my way of celebrating where my coding journey began.

---

## Architecture & Loading Sequence

Felis Shell loads configuration modules from `~/.bashrc.d` via `~/.bashrc` in a deterministic sequence:

| Stage | Module | Purpose |
| :---: | :--- | :--- |
| **0** | `user.conf` | User environment variables and customization toggles (loaded first) |
| **1** | `00-colors.sh` | Terminal ANSI / 256-color palette variables |
| **2** | `01-aliases.sh` | Safe command shortcuts, modern tool replacements, and platform detection |
| **3** | `02-prompt.sh` | Multi-line git status prompt with exit code reporting and Nerd Font icons |
| **4** | `03-hooks.sh` | Opt-in directory stack and environment integration hooks (`cd`, auto-venv) |
| **5** | `functions/*.sh` | Modular utilities (system maintenance, git, docker, dev scaffolding) |

---

## Platform Support

- **Arch Linux / Manjaro**: Native package support via `pacman` (`github-cli`, `7zip`, `chafa`, `fastfetch`).
- **Ubuntu / Debian**: Native package support via `apt` (`chafa`, `fastfetch`, `batcat`, `fdfind`).
- **WSL2 (Windows Subsystem for Linux)**: Automatically detected (`WSL_DISTRO_NAME`). Configures Windows Explorer browser dispatch (`wslview` / `explorer.exe`), bypasses slow 9P filesystem hooks on `/mnt/*`, and selects Chafa character rendering for Windows Terminal.
- **Native Linux Desktops**: Detects Kitty terminal emulator for GPU-accelerated graphic banners.

---

## Installation

### 1. Clone Repository
Clone Felis Shell into your home directory (recommended to keep on native Linux ext4 inside WSL for best I/O performance):
```bash
git clone https://github.com/afif25fradana/felis-shell.git
cd felis-shell
```

### 2. Verify with Dry-Run
Preview the symlinks and backups without making changes:
```bash
./install.sh --dry-run
```

### 3. Install Configuration
Choose either dotfiles only or dotfiles with core dependencies:
```bash
# Option A: Install configuration symlinks only
./install.sh

# Option B: Install configuration and install core CLI utilities via package manager
./install.sh --install-deps
```

### 4. Activate
Reload your shell environment:
```bash
source ~/.bashrc
```

*Note: Existing configuration files (`~/.bashrc`, `~/.inputrc`, etc.) are backed up with timestamps (`~/.bashrc.backup.YYYYMMDD_HHMMSS`) before symlinks are created. Host Git configuration is preserved untouched (see `.gitconfig.example` for reference settings).*

---

## Configuration

Customize your setup without editing tracked git files by creating `~/.bashrc.d/user.conf`:

```bash
cp ~/.bashrc.d/user.conf.example ~/.bashrc.d/user.conf
```

Supported configuration variables:
```bash
# Toggle fastfetch login banner (true/false)
export FASTFETCH_ENABLED=true

# Fastfetch banner width in character columns
export FELIS_LOGO_WIDTH=50

# Toggle Nerd Font prompt iconography (true/false)
export USE_NERD_FONT=true

# Default Python virtual environment directory name
export DEFAULT_VENV_NAME=".venv"

# Docker directory for local n8n service
export N8N_DIR="$HOME/n8n-docker"
```

---

## Documentation

- [Command & Function Reference](docs/reference.md): Full technical reference of aliases, modular shell functions, directory hooks, fastfetch banners, and troubleshooting.
- [Contributing Guide](docs/contributing.md): Coding style, shellcheck guidelines, testing instructions, and PR workflow.

---

## Verification & Testing

Run the test harness to validate syntax, directory hooks, and module loading:
```bash
./test_dotfiles.sh
```

---

## Uninstallation / Rollback

To remove Felis Shell symlinks and restore your previous configuration:
```bash
# Remove managed symlinks
rm ~/.bashrc ~/.bashrc.d ~/.local/bin/random-fastfetch.sh

# Restore latest backup (if available)
latest_backup=$(ls -t ~/.bashrc.backup.* 2>/dev/null | head -1)
[[ -n "$latest_backup" ]] && cp "$latest_backup" ~/.bashrc
source ~/.bashrc
```
