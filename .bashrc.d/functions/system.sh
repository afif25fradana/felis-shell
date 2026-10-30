#!/bin/bash
#
# ~/.bashrc.d/functions/system.sh - System Maintenance Functions
#

# --- System Maintenance Functions ---

# Performs comprehensive system cleanup across multiple distributions.
#
# This function automates the process of cleaning up system caches, removing orphaned packages,
# and clearing user caches. It intelligently detects your package manager (pacman, apt, dnf, etc.)
# and executes the appropriate cleanup commands for your specific distribution.
#
# The function handles various Linux distributions including Arch Linux, Ubuntu/Debian, Fedora,
# openSUSE, and others, making it a versatile tool for system maintenance.
#
# Returns:
#   0 on success, 1 on failure
#
# @example
#   sysclean
sysclean() {
    local has_error=false
    local has_performed_action=false
    
    print_info "Starting system cleanup..."

    # Check for root privileges
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        return 1
    fi

    # Check available disk space before cleanup
    local available_space
    available_space=$(df -m / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1024 ]]; then  # Less than 1GB
        print_warning "Low disk space detected: ${available_space}MB available"
    fi

    # Function to handle command execution with error checking
    _fs_sysclean_exec() {
        local msg="$1"
        shift
        if ! "$@"; then
            print_error "Failed: $msg"
            has_error=true
            return 1
        fi
        has_performed_action=true
        return 0
    }
    trap 'unset -f _fs_sysclean_exec 2>/dev/null' RETURN

    # Check for different package managers and clean accordingly
    if command -v pacman >/dev/null 2>&1; then
        # Arch Linux
        if ! sudo -v; then
            print_error "Failed to acquire sudo privileges"
            return 1
        fi

        print_info "Cleaning pacman cache..."
        _fs_sysclean_exec "pacman cache cleanup" sudo pacman -Sc --noconfirm

        print_info "Removing orphan packages..."
        local orphans
        orphans=$(pacman -Qtdq 2>/dev/null) || true
        if [[ -n "$orphans" ]]; then
            if echo "$orphans" | xargs -r sudo pacman -Rns --noconfirm; then
                print_success "Removed orphan packages"
                has_performed_action=true
            else
                print_error "Failed to remove orphan packages"
                has_error=true
            fi
        else
            print_info "No orphan packages found"
        fi

        # Clean AUR helper cache if available
        if command -v yay >/dev/null 2>&1; then
            print_info "Cleaning yay cache..."
            _fs_sysclean_exec "yay cache cleanup" yay -Sc --noconfirm
        elif command -v paru >/dev/null 2>&1; then
            print_info "Cleaning paru cache..."
            _fs_sysclean_exec "paru cache cleanup" paru -Sc --noconfirm
        fi
    elif command -v apt >/dev/null; then
        # Debian/Ubuntu
        if ! sudo -v; then
            print_error "Failed to acquire sudo privileges"
            return 1
        fi

        print_info "Cleaning apt cache..."
        _fs_sysclean_exec "apt autoremove" sudo apt autoremove -y
        _fs_sysclean_exec "apt autoclean" sudo apt autoclean
        _fs_sysclean_exec "apt clean" sudo apt clean

    elif command -v dnf >/dev/null; then
        # Fedora
        if ! sudo -v; then
            print_error "Failed to acquire sudo privileges"
            return 1
        fi

        print_info "Cleaning dnf cache..."
        _fs_sysclean_exec "dnf clean all" sudo dnf clean all
        _fs_sysclean_exec "dnf autoremove" sudo dnf autoremove -y

    elif command -v yum >/dev/null; then
        # Older Fedora/RHEL/CentOS
        if ! sudo -v; then
            print_error "Failed to acquire sudo privileges"
            return 1
        fi

        print_info "Cleaning yum cache..."
        _fs_sysclean_exec "yum clean all" sudo yum clean all
        _fs_sysclean_exec "yum autoremove" sudo yum autoremove -y

    elif command -v zypper >/dev/null; then
        # openSUSE
        if ! sudo -v; then
            print_error "Failed to acquire sudo privileges"
            return 1
        fi

        print_info "Cleaning zypper cache..."
        _fs_sysclean_exec "zypper clean" sudo zypper clean
        _fs_sysclean_exec "zypper remove --clean-deps" sudo zypper remove --clean-deps

    else
        print_warning "Unknown package manager - manual cleanup required"
        return 1
    fi

    # Clean user caches
    print_info "Cleaning user caches..."
    [[ -d "$HOME/.cache" ]] && find "$HOME/.cache" -type f -atime +30 -delete 2>/dev/null
    [[ -d "$HOME/.local/share/Trash" ]] && rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null

    # Clean logs if systemd journal is available
    if command -v journalctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
        print_info "Cleaning system logs..."
        sudo journalctl --vacuum-time=7d 2>/dev/null
    fi

    # Final status check
    if ! $has_performed_action; then
        print_error "No package manager found or no cleanup actions performed"
        return 1
    fi

    if $has_error; then
        print_warning "Cleanup completed with some errors"
        return 1
    else
        print_success "System cleanup completed successfully"
        return 0
    fi
}

# Manages systemd services with a user-friendly interface.
#
# This function provides a simplified way to control systemd services, supporting both
# system services and user services. It handles the sudo requirements automatically
# and provides clear feedback about the operation results.
#
# @param $1 - The action to perform (start, stop, restart, status, enable, disable). Required.
# @param $2 - The name of the service to manage. Required.
# @param $3 - (Optional) Add --user flag to manage user services instead of system services.
#
# @example
#   serv start nginx
#   serv restart docker
#   serv status apache2
#   serv enable myapp --user
serv() {
    if [[ $# -lt 2 ]]; then
        print_error "Usage: serv <action> <service> [--user]"
        print_info "Actions: start, stop, restart, status, enable, disable"
        print_info "Add --user flag for user services"
        return 1
    fi

    local action="$1"
    local service="$2"
    local user_flag="$3"

    # Validate action
    case "$action" in
        start|stop|restart|status|enable|disable) ;;
        *)
            print_error "Invalid action: $action"
            return 1
            ;;
    esac

    if [[ "$user_flag" != "--user" && "$action" != "status" ]]; then
        if ! sudo -v; then
            print_error "Failed to acquire sudo privileges"
            return 1
        fi
    fi

    if [[ "$user_flag" == "--user" ]]; then
        systemctl --user "$action" "$service"
    else
        sudo systemctl "$action" "$service"
    fi

    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        print_success "Service $service $action completed"
    else
        print_error "Service $service $action failed"
    fi

    return $exit_code
}