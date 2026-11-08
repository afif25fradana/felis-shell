#!/bin/bash

# Exit if not running interactively
[[ $- != *i* ]] && return

# Check for minimum bash version
if ((BASH_VERSINFO[0] < 4)); then
    echo "Warning: Some features may not work properly with Bash versions below 4.0" >&2
fi

# --- [USER CONFIG] ---
# Default configuration
export USE_NERD_FONT=${USE_NERD_FONT:-true}
export FELIS_SHELL_DEBUG=${FELIS_SHELL_DEBUG:-false}
export FELIS_SHELL_VERBOSE=${FELIS_SHELL_VERBOSE:-false}
export FELIS_QUIET=${FELIS_QUIET:-false}
export FELIS_WSL_PATH_MODE=${FELIS_WSL_PATH_MODE:-prune}

# --- [CORE SETUP] ---
BASHRC_CACHE_DIR="$HOME/.cache/bashrc"
mkdir -p "$BASHRC_CACHE_DIR"

BASHRC_DIR="${BASHRC_DIR:-$HOME/.bashrc.d}"
# Resolve symlink to actual directory if needed
if [[ -L "$BASHRC_DIR" ]]; then
    BASHRC_DIR=$(readlink -f "$BASHRC_DIR")
fi

if [[ ! -d "$BASHRC_DIR" ]]; then
    echo "Warning: $BASHRC_DIR directory not found" >&2
    return 1
fi

# Load user configuration if it exists
if [[ -r "$BASHRC_DIR/user.conf" ]]; then
    # shellcheck source=/dev/null
    if ! source "$BASHRC_DIR/user.conf"; then
        echo "Error: Failed to load user configuration" >&2
    fi
fi

# --- [WSL PATH OPTIMIZATION] ---
# Windows PATH entries mounted under /mnt/* are served over 9P, which makes
# every failed command lookup (command -v) dramatically slower. Prune those
# entries while keeping the few Windows tools Felis Shell integrates with.
# Set FELIS_WSL_PATH_MODE=keep in user.conf to preserve the original PATH.
_fs_prune_wsl_path() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || return 0
    [[ "${FELIS_WSL_PATH_MODE:-prune}" == "prune" ]] || return 0

    local entry lower
    local -a path_entries=() kept=()
    local seen=":"

    IFS=':' read -r -a path_entries <<< "${PATH:-}"

    for entry in "${path_entries[@]}"; do
        [[ -n "$entry" ]] || continue

        # Only touch Windows drive mounts; leave native Linux paths alone.
        if [[ "$entry" == /mnt/[a-z] || "$entry" == /mnt/[a-z]/* ]]; then
            lower="${entry,,}"
            case "$lower" in
                /mnt/[a-z]/windows | \
                /mnt/[a-z]/windows/system32 | \
                /mnt/[a-z]/windows/system32/wbem | \
                /mnt/[a-z]/windows/system32/windowspowershell/v1.0 | \
                */microsoft\ vs\ code/bin)
                    ;;
                *)
                    continue
                    ;;
            esac
        fi

        # De-duplicate while preserving order.
        [[ "$seen" == *":$entry:"* ]] && continue
        seen+="$entry:"
        kept+=("$entry")
    done

    # Never wipe PATH completely if only Windows entries were present.
    (( ${#kept[@]} > 0 )) || return 0

    local IFS=':'
    PATH="${kept[*]}"
    export PATH
}

if [[ -n "${WSL_DISTRO_NAME:-}" && "${FELIS_WSL_PATH_MODE:-prune}" == "prune" ]]; then
    _fs_prune_wsl_path
fi

# Define module loading order
declare -a MODULE_ORDER=(
    "00" # Colors and basic setup
    "01" # Aliases
    "02" # Prompt configuration
    "03" # Hooks and extensions
)

# Load core modules in order
for prefix in "${MODULE_ORDER[@]}"; do
    if [[ "${FELIS_SHELL_DEBUG}" == "true" ]]; then
        echo "Debug: Looking for modules with prefix $prefix in $BASHRC_DIR"
    fi
    # Debug: List all files first
    if [[ "${FELIS_SHELL_DEBUG}" == "true" ]]; then
        echo "Debug: All files in $BASHRC_DIR:"
        ls -la "$BASHRC_DIR"/"${prefix}"-*.sh 2>/dev/null || echo "Debug: No files found matching pattern ${prefix}-*.sh"
    fi
    
    # Simpler approach: use glob expansion instead of find
    for module_file in "$BASHRC_DIR"/"${prefix}"-*.sh; do
        # Check if the file actually exists (glob expansion might create a literal string if no files match)
        if [[ -e "$module_file" && -r "$module_file" ]]; then
            if [[ "${FELIS_SHELL_DEBUG}" == "true" ]]; then
                echo "Debug: Found module file: $module_file"
            fi
            # shellcheck source=/dev/null
            if ! source "$module_file"; then
                echo "Error: Failed to load module $module_file" >&2
            elif [[ "${FELIS_SHELL_DEBUG}" == "true" ]]; then
                echo "Debug: Loaded module $module_file"
            fi
        elif [[ "${FELIS_SHELL_DEBUG}" == "true" ]]; then
            echo "Debug: Skipping $module_file (does not exist or not readable)"
        fi
    done
done

# Load functions
if [[ -d "$BASHRC_DIR/functions" ]]; then
    for func_file in "$BASHRC_DIR"/functions/*.sh; do
        if [[ -r "$func_file" ]]; then
            # shellcheck source=/dev/null
            if ! source "$func_file"; then
                echo "Error: Failed to load function module $func_file" >&2
            elif [[ "${FELIS_SHELL_DEBUG}" == "true" ]]; then
                echo "Debug: Loaded function module $func_file"
            fi
        fi
    done
fi

# --- [NVM CONFIGURATION] ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Ensure clean exit status when sourced
:
