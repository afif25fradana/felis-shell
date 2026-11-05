#!/bin/bash
#
# ~/.bashrc.d/functions/dotfiles.sh - Dotfiles Management
#

# --- Dotfiles Management ---

# Manages the backup and restoration of dotfiles, simplifying the process of saving and
# reloading your shell configuration.
#
# This function provides two main actions: `backup` and `restore`. The `backup` action copies
# your current dotfiles to the `~/.dotfiles` directory and initializes a Git repository for
# version control. The `restore` action copies the files from `~/.dotfiles` back to your
# home directory, allowing you to quickly restore your configuration on a new machine.
#
# @param $1 - The action to perform. Can be either `backup` or `restore`.
#
# @example
#   dotfiles backup
#   dotfiles restore
dotfiles() {
    local action="$1"
    local repo_dest
    repo_dest=$(readlink -f "$HOME/.bashrc" 2>/dev/null || true)
    local dotfiles_dir
    dotfiles_dir=$(dirname "$repo_dest")

    # Check if color functions are available, if not define them
    if ! command -v print_info >/dev/null 2>&1; then
        # Define fallback print functions if not available
        print_success() { echo -e "✓ $*"; }
        print_warning() { echo -e "⚠ $*" >&2; }
        print_error() { echo -e "✗ $*" >&2; }
        print_info() { echo -e "ℹ $*"; }
    fi

    if [[ ! -L "$HOME/.bashrc" || ! -d "$dotfiles_dir/.git" ]]; then
        print_error "Felis-Shell is not installed as a symlinked repository. Use ./install.sh"
        return 1
    fi

    case "$action" in
        "backup")
            print_info "Syncing dotfiles repository..."
            (
                cd "$dotfiles_dir" && \
                git add . && \
                if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                    git commit -m "Dotfiles backup update: $(date '+%Y-%m-%d %H:%M:%S')"
                    print_success "Changes committed to dotfiles repository"
                else
                    print_info "No changes to commit in dotfiles repository"
                fi
            ) || print_warning "Failed to commit changes to git repository"
            ;;
        "restore")
            print_info "Restoring dotfiles symlinks..."
            if [[ -x "$dotfiles_dir/install.sh" ]]; then
                "$dotfiles_dir/install.sh" --yes
                print_success "Dotfiles restored via install.sh"
            else
                print_error "Installer script not found at $dotfiles_dir/install.sh"
                return 1
            fi
            ;;
        *)
            print_error "Usage: dotfiles <backup|restore>"
            print_info "  backup  - Commit local dotfiles changes to repository"
            print_info "  restore - Re-apply symlinks via install.sh"
            ;;
    esac
}

# Creates a new GitHub issue from the command line using the GitHub CLI.
#
# This function provides a convenient wrapper around the `gh issue create` command, allowing
# you to quickly create a new issue without leaving your terminal. It requires the GitHub CLI
# (`gh`) to be installed and authenticated.
#
# @param $1 - The title of the issue. This is a required parameter.
# @param $2 - (Optional) The body of the issue. If not provided, the issue will be created
#             with an empty body.
#
# @example
#   ghissue "Fix a bug" "This is a critical bug that needs to be fixed."
#   ghissue "Add a new feature"
ghissue() {
    if [[ $# -eq 0 ]]; then
        print_error "Usage: ghissue <title> [body]"
        return 1
    fi

    local title="$1"
    local body="${2:-}"

    if ! command -v gh >/dev/null; then
        print_error "GitHub CLI (gh) not installed"
        return 1
    fi

    if [[ -n "$body" ]]; then
        gh issue create --title "$title" --body "$body"
    else
        gh issue create --title "$title"
    fi
}

# Provides a quick overview of the current Git repository's status, including uncommitted
# changes, unpushed commits, and recent issues.
#
# This function uses the GitHub CLI (`gh`) to fetch information about the repository and
# display it in a concise, easy-to-read format. It's a useful tool for quickly checking
# the state of your project without running multiple Git commands.
#
# @example
#   ghstatus
ghstatus() {
    if ! command -v gh >/dev/null; then
        print_error "GitHub CLI (gh) not installed"
        return 1
    fi

    print_info "Repository Status:"
    
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_error "Not in a git repository"
        return 1
    fi
    
    # Get repository info
    local repo_name
    repo_name=$(basename "$(git rev-parse --show-toplevel)")
    
    echo -e "${C_CYAN}Repository:${C_RESET} $repo_name"
    
    # Check for uncommitted changes
    if [[ -n "$(git status --porcelain)" ]]; then
        print_warning "You have uncommitted changes"
    else
        print_success "Working directory is clean"
    fi
    
    # Check for unpushed commits
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        local unpushed
        unpushed=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
        if [[ "$unpushed" -gt 0 ]]; then
            print_warning "You have $unpushed unpushed commits"
        fi
    fi
    
    # Show recent issues
    print_info "Recent Issues:"
    gh issue list --limit 5 2>/dev/null || echo "No issues or not connected to GitHub"
}
