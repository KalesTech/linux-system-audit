#!/bin/bash
# Linux System Audit Script
# Collects hardware, software, and network configuration details
# Saves results in a timestamped folder + compressed archive

# ───────────────────────────────
# Config (May tweak later for folder location outputs line 10,11) 
# ───────────────────────────────

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
INFO_DIR=~/EndeavourOS-Audit/$TIMESTAMP
LOG_FILE="$INFO_DIR/audit.log"

# ───────────────────────────────
# Helpers: Output & Logging Utilities
# ───────────────────────────────

mkdir -p "$INFO_DIR"

log() {echo -e "[$(date +"%H:%M:%S")] $1" | tee -a "$LOG_FILE"}
success() {echo -e "\e[32m[✓] $1\e[0m" | tee -a "$LOG_FILE"}
error() {echo -e "\e[31m[✗] $1\e[0m" | tee -a "$LOG_FILE"}

run_cmd() {
    CMD="$1"
    OUTFILE="$2"
    if eval "$CMD" > "$OUTFILE" 2>>"$LOG_FILE"; then
        success "$CMD → $OUTFILE"
    else
        error "$CMD failed"
    fi
}

log "Starting Linux system audit..."
log "Output directory: $INFO_DIR"

# ───────────────────────────────
# System Information Pull Commands 
# ───────────────────────────────

run_cmd "neofetch --stdout" "$INFO_DIR/system_info.txt"
run_cmd "pacman -Qe" "$INFO_DIR/installed_packages.txt"
run_cmd "yay -Qm || paru -Qm" "$INFO_DIR/aur_packages.txt"

# Kernel & OS
run_cmd "uname -a" "$INFO_DIR/kernel_info.txt"
if command -v lsb_release &>/dev/null; then
    run_cmd "lsb_release -a" "$INFO_DIR/os_info.txt"
else
    run_cmd "cat /etc/os-release" "$INFO_DIR/os_info.txt"
fi

# Desktop / WM
{
    echo "DE: $XDG_CURRENT_DESKTOP"
    echo "WM: $XDG_SESSION_TYPE"
} > "$INFO_DIR/desktop_info.txt"

# Services
run_cmd "systemctl list-units --type=service --state=running" "$INFO_DIR/active_services.txt"
run_cmd "systemctl list-unit-files --type=service | grep enabled" "$INFO_DIR/enabled_services.txt"

# Dotfiles
run_cmd "ls -la ~ | grep '^\.'" "$INFO_DIR/dotfiles_list.txt"

# Hardware
run_cmd "lscpu" "$INFO_DIR/cpu_info.txt"
run_cmd "lsblk" "$INFO_DIR/disk_partitions.txt"
run_cmd "lsusb" "$INFO_DIR/usb_devices.txt"
run_cmd "lspci" "$INFO_DIR/pci_devices.txt"
run_cmd "free -h" "$INFO_DIR/memory_info.txt"

# Disk usage
run_cmd "df -h" "$INFO_DIR/disk_usage.txt"
run_cmd "du -sh ~/*" "$INFO_DIR/home_folder_sizes.txt"

# Networking
run_cmd "ip a" "$INFO_DIR/network_interfaces.txt"
run_cmd "nmcli dev show" "$INFO_DIR/network_details.txt"

# Shell
echo "$SHELL" > "$INFO_DIR/shell_info.txt"

# Processes
run_cmd "ps aux" "$INFO_DIR/running_processes.txt"

# Cron Jobs
run_cmd "crontab -l" "$INFO_DIR/user_cron_jobs.txt"
run_cmd "sudo crontab -l" "$INFO_DIR/root_cron_jobs.txt"

# ───────────────────────────────
# README File
# ───────────────────────────────

cat <<EOF > "$INFO_DIR/README.md"
# Linux System Audit Report

This folder contains a snapshot of the system configuration and hardware information as of $TIMESTAMP.

## Contents
- system_info.txt
- installed_packages.txt
- aur_packages.txt
- kernel_info.txt
- os_info.txt
- desktop_info.txt
- active_services.txt
- enabled_services.txt
- dotfiles_list.txt
- cpu_info.txt
- disk_partitions.txt
- usb_devices.txt
- pci_devices.txt
- memory_info.txt
- disk_usage.txt
- home_folder_sizes.txt
- network_interfaces.txt
- network_details.txt
- shell_info.txt
- running_processes.txt
- user_cron_jobs.txt
- root_cron_jobs.txt

## Usage
Run \`audit.sh\` on any Arch-based Linux system. A timestamped folder will be created under \`~/EndeavourOS-Audit\`, and all results will be archived into a \`.tar.gz\` file.
EOF

# ───────────────────────────────
# Archive Results
# ───────────────────────────────
cd ~/EndeavourOS-Audit || exit
tar -czf "$TIMESTAMP.tar.gz" "$TIMESTAMP" && success "Archive created: $TIMESTAMP.tar.gz"

log "Audit completed."
