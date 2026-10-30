# Felis Shell Reference Manual

A comprehensive technical reference for shortcuts, aliases, modular shell functions, hooks, and troubleshooting.

---

## 1. Aliases & Shortcuts

### System & Package Management
* `update`: Updates system packages (`yay -Syu` on Arch with AUR; `sudo apt update && sudo apt upgrade` on Debian/Ubuntu).
* `install <pkg>`: Installs specified package using detected package manager.
* `search <pkg>`: Searches repository for packages.
* `remove <pkg>`: Removes a package and unneeded dependencies (`yay -Rns` or `sudo apt remove`).
* `sysclean`: Automated system maintenance (cleans package caches, removes orphans safely with `xargs`, cleans user cache).
* `serv <action> <service> [--user]`: Wrapper for `systemctl` (handles sudo automatically).
* `top`: Launches modern system monitor (`btop` or `htop`).
* `ports`: Displays open network ports (`ss -tulpn` or fallback to `netstat`).

### Navigation & File Operations
* `..`, `...`, `....`: Quick directory traversal up 1, 2, or 3 levels.
* `~`: Return to user home directory.
* `-`: Return to previous working directory.
* `ll`: Detailed directory listing with icons and git status (`eza -lha` or `ls -lha`).
* `ls`: Standard directory listing with icons (`eza` or `ls`).
* `tree`: Visual folder tree (`eza --tree`).
* `cat` / `catt`: Syntax-highlighted file viewer via `bat` (`bat --paging=never` / `bat --paging=auto`).
* `find`: Fast file searching via `fd`.
* `grep`: High-speed regex text search via `ripgrep` (`rg`).
* `z <query>`: Smart directory jumping powered by `zoxide`.
* `mkcd <dir>`: Creates directory and immediately enters it.
* `backup <file_or_dir>`: Creates a timestamped backup copy (`.backup.YYYYMMDD_HHMMSS`).
* `extract <archive>`: Unified extractor for `.tar.gz`, `.zip`, `.rar`, `.7z`, `.bz2`, `.xz`, etc.

### Git Workflow Helpers
* `gs`: Concise repository status (`git status -sb`).
* `ga <file>` / `gaa`: Stage specific file or all modified files (`git add .`).
* `gc "<msg>"` / `gca "<msg>"`: Commit with message.
* `gp` / `gpl`: Push / pull with remote.
* `gd` / `gdc`: Diff working tree or staged changes (`git diff --cached`).
* `gb`: List local branches.
* `gco <branch>` / `gcb <branch>`: Checkout branch or create and checkout new branch.
* `gl` / `gll`: Pretty graphical git commit history.
* `gst` / `gstp`: Stash changes / pop latest stash.

### GitHub CLI Integration
* `ghpr`: Create a pull request in default browser (`gh pr create --web`).
* `ghi`: List repository issues (`gh issue list`).
* `ghv`: View repository in browser (`gh repo view --web`).
* `ghc <repo>`: Clone a repository (`gh repo clone`).
* `ghissue <title> [body]`: Rapidly create a GitHub issue from the terminal.

---

## 2. Shell Functions Reference

### `sysclean`
Performs comprehensive system cleanup:
* Pacman cache cleanup (`sudo pacman -Sc`).
* Safe orphan removal using `xargs -r sudo pacman -Rns --noconfirm`.
* Cleans user cache files older than 30 days in `~/.cache`.
* Empties user Trash directory.
* Vacuums systemd journal logs to 7 days (if permissions allow).

### `extract <file>`
Automatically determines archive format by file extension and executes the appropriate decompression tool (`tar`, `unzip`, `unrar`, `7z`, `bunzip2`, `unxz`, etc.).

### `myip`
Displays local IPv4 interfaces (excluding loopback) and queries public IP address via multiple external fallback APIs (`ipinfo.io`, `icanhazip.com`, `api.ipify.org`).

### `portcheck <port> [host]`
Checks whether a specific TCP port is open and accepting connections (defaults to localhost).

### `gitclone <url> [dir]`
Clones a git repository and immediately `cd`s into the project directory upon completion.

### `pyinit [project_name]` & `pyinitplus [project_name]`
Scaffolds a new Python project:
* Creates and activates a virtual environment (`.venv`).
* Generates `.gitignore`, `requirements.txt`, and boilerplate structure.
* `pyinitplus` additionally configures testing tools (`pytest`, `black`, `flake8`, `isort`, `pytest-cov`, and `src/` directory layout).

### `newproject <name> [type]`
Scaffolds projects based on type: `python`, `node`, `web`, or `shell`.

### `dotfiles <backup|restore>`
Manages user dotfiles versioning in `~/.dotfiles`.

---

## 3. Smart Hooks & Fastfetch Banners

### Smart Directory Hooks (`03-hooks.sh`)
* **Auto Virtual Environment**: Detects Python virtual environments (`.venv`, `venv`, `env`, Poetry, Pipenv, Conda) when entering a folder and automatically activates them. Deactivates upon leaving.
* **Auto Node Version**: Detects `.nvmrc` and switches Node.js version automatically via `nvm`.
* **Auto Directory Preview**: Displays directory contents upon `cd` if folder contains 20 items or fewer. Automatically bypassed on Windows NTFS mount points (`/mnt/*`) in WSL2 to eliminate 9P filesystem latency.

### Fastfetch Random Banner Runner (`random-fastfetch.sh`)
* Reads mascot images from `~/.dotfiles/logos` or `./logos`.
* **Protocol Negotiation**:
  * In WSL2 / Windows Terminal: Uses `chafa` (`--chafa-symbols vhalf`) for high-resolution 24-bit TrueColor ANSI character rendering.
  * In Linux Kitty: Uses Kitty GPU graphics protocol (`kitty icat`).
  * Other terminals: Gracefully falls back to text fetch.
* Aspect ratio is preserved proportionally based on `FELIS_LOGO_WIDTH` (default: 55 columns).

---

## 4. Troubleshooting & WSL2 Gotchas

### Line Endings on Windows (`CRLF`)
If you clone the repository using Windows Git, ensure Git line ending normalization is active. Felis Shell includes a [`.gitattributes`](../.gitattributes) enforcing `eol=lf` for all shell scripts. Running scripts with CRLF line endings will trigger `$'\r': command not found`.

### Filesystem Performance in WSL2
Always clone and keep your development repositories in the native Linux ext4 filesystem (e.g. `~/projects` or `~/felis-shell`). Accessing Windows drives mounted at `/mnt/c/` or `/mnt/d/` uses the 9P/virtiofs protocol, which is slower for multi-file operations and git queries.

### Missing Icons in Prompt
If prompt iconography (such as Git branch ` ` or language symbols) appears as empty boxes or broken glyphs, ensure you have a **Nerd Font** installed on your host system (e.g., JetBrainsMono Nerd Font) and configured in Windows Terminal settings:
`Settings -> Profiles -> Defaults -> Appearance -> Font face`.

If you prefer plain text indicators, set in `~/.bashrc.d/user.conf`:
```bash
export USE_NERD_FONT=false
```
