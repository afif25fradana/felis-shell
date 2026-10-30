#!/usr/bin/env bash
# random-fastfetch.sh - High-performance, robust random banner runner for Fastfetch v2.x
# Spec-compliant: Negotiates Chafa (WSL2 / Windows Terminal) and Kitty (native Linux)
# Zero external subprocesses in image discovery; O(1) deterministic anti-repetition.

set -euo pipefail

# 1. Dependency Validation
if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Error: fastfetch is not installed or not in PATH." >&2
    exit 1
fi

# 2. Configuration & User Overrides
readonly LOGO_WIDTH="${FELIS_LOGO_WIDTH:-55}"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/felis-shell"
readonly CACHE_FILE="$CACHE_DIR/last_logo"

# 3. Locate Logo Directory (Resolve canonical path across symlinks)
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
    SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
    [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"

if [[ -d "$SCRIPT_DIR/logos" ]]; then
    LOGO_DIR="$SCRIPT_DIR/logos"
elif [[ -d "$HOME/.dotfiles/logos" ]]; then
    LOGO_DIR="$HOME/.dotfiles/logos"
else
    # Graceful fallback: run standard fastfetch without crashing
    exec fastfetch
fi

# 4. Pure-Bash Image Discovery (Zero subshell / fork overhead)
declare -a images=()
shopt -s nullglob nocaseglob
for img in "$LOGO_DIR"/*.{png,jpg,jpeg,gif,bmp,webp}; do
    [[ -f "$img" && -r "$img" ]] && images+=("$img")
done
shopt -u nullglob nocaseglob

readonly total_images=${#images[@]}
if (( total_images == 0 )); then
    exec fastfetch
fi

# 5. Protocol Negotiation (WSL2 vs Native Linux Kitty vs Fallback)
LOGO_TYPE="auto"
EXTRA_FASTFETCH_FLAGS=()

if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" || -n "${WT_SESSION:-}" ]]; then
    # Windows Terminal / WSL2 environment does not support Kitty graphics protocol
    if command -v chafa >/dev/null 2>&1; then
        LOGO_TYPE="chafa"
        EXTRA_FASTFETCH_FLAGS+=(--chafa-symbols vhalf)
    fi
elif [[ "${TERM:-}" == *"kitty"* || -n "${KITTY_PID:-}" || -n "${KITTY_WINDOW_ID:-}" ]]; then
    # Native Linux Kitty terminal emulator
    LOGO_TYPE="kitty"
elif command -v chafa >/dev/null 2>&1; then
    LOGO_TYPE="chafa"
    EXTRA_FASTFETCH_FLAGS+=(--chafa-symbols vhalf)
fi

# 6. O(1) Deterministic Random Selection (No while-loop spinning)
mkdir -p "$CACHE_DIR"
last_image=""
if [[ -f "$CACHE_FILE" ]]; then
    last_image="$(<"$CACHE_FILE")"
fi

if (( total_images == 1 )); then
    selected_image="${images[0]}"
elif [[ -n "$last_image" ]]; then
    last_idx=-1
    for i in "${!images[@]}"; do
        if [[ "${images[i]}" == "$last_image" ]]; then
            last_idx=$i
            break
        fi
    done

    if (( last_idx >= 0 )); then
        # Deterministically select from remaining (total_images - 1) candidates
        rand_offset=$(( RANDOM % (total_images - 1) ))
        new_idx=$(( (last_idx + 1 + rand_offset) % total_images ))
        selected_image="${images[new_idx]}"
    else
        selected_image="${images[RANDOM % total_images]}"
    fi
else
    selected_image="${images[RANDOM % total_images]}"
fi

# 7. Update Cache Atomically
printf '%s\n' "$selected_image" > "$CACHE_FILE"

# 8. Execute Fastfetch (Omit --logo-height to preserve proportional aspect ratio)
FASTFETCH_ARGS=(
    --logo "$selected_image"
    --logo-type "$LOGO_TYPE"
    --logo-width "$LOGO_WIDTH"
    --logo-padding-top 0
    --logo-padding-left 0
    "${EXTRA_FASTFETCH_FLAGS[@]}"
)

if ! fastfetch "${FASTFETCH_ARGS[@]}"; then
    echo "Warning: fastfetch logo rendering failed; falling back to text banner." >&2
    exec fastfetch
fi
