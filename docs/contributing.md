# Contributing to Felis Shell

Thank you for your interest in contributing to Felis Shell! Whether you are fixing a typo, improving WSL2 compatibility, or adding a new shortcut, all contributions are appreciated.

---

## Development Workflow

1. **Fork & Clone**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Felis-Shell-Modular-Dotfile.git
   cd Felis-Shell-Modular-Dotfile
   ```

2. **Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**:
   * Keep modular boundaries intact: aliases in `01-aliases.sh`, prompt logic in `02-prompt.sh`, hooks in `03-hooks.sh`, and modular functions in `functions/`.
   * Adhere to the code standards below.

4. **Verify Locally**:
   Run the test harness before committing:
   ```bash
   ./test_dotfiles.sh
   ```

5. **Commit & Push**:
   Use conventional commits (`feat: ...`, `fix: ...`, `docs: ...`):
   ```bash
   git commit -m "feat(aliases): add new shortcut for dev workflow"
   git push origin feature/your-feature-name
   ```

6. **Submit PR**: Open a pull request describing the rationale and changes made.

---

## Coding Standards

* **Indentation**: 2 spaces (matching `.editorconfig`). No tabs.
* **Line Endings**: LF only (enforced by `.gitattributes`).
* **Shellcheck**: Validate shell scripts with `shellcheck`:
  ```bash
  shellcheck your_script.sh
  ```
* **Namespace Discipline**:
  * Never place `set -o pipefail` or `shopt -s nullglob` at file scope inside modular function files (`functions/*.sh`), as sourcing them leaks options into the user's interactive session.
  * Use local variables (`local var_name`) inside all functions.
  * Prefix internal variables to avoid clobbering Bash reserved variables (e.g. `_FS_DIRSTACK`).
* **Cross-Platform Awareness**: Test or guard commands that behave differently between Linux native, WSL2, and different distributions (Arch vs Debian).

---

## Reporting Issues

If you encounter an issue or unexpected behavior:
1. Check the [Reference Manual](reference.md#4-troubleshooting--wsl2-gotchas) for common setup quirks.
2. Open an issue on GitHub with reproduction steps, your operating system (or WSL version), and terminal emulator information.
