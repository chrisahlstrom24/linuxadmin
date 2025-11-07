#This script was written with Gemini

#!/bin/bash

#================================================
# Cybersecurity Maintenance and Hardening Script
# Designed for CentOS/RHEL and Ubuntu/Debian
# Must be run as root or with sudo.
#================================================

LOGFILE="/var/log/security_maintenance_$(date +%Y%m%d).log"
DATE_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# --- 1. Utility Functions ---

function log_message() {
    echo "[$DATE_TIME] $1" | tee -a "$LOGFILE"
}

function check_status() {
    log_message "--- CHECKING $1 STATUS ---"
    if systemctl is-active --quiet "$2"; then
        log_message "$1 is active and running."
        echo "Status: Active" | tee -a "$LOGFILE"
    else
        log_message "$1 is NOT active. HIGH PRIORITY: Investigate or enable."
        echo "Status: Inactive/Disabled" | tee -a "$LOGFILE"
    fi
}

# --- 2. System Update and Cleaning ---

function run_updates() {
    log_message "Starting system package update..."

    # Detect OS using package manager
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        log_message "Detected Debian/Ubuntu. Running apt commands."
        sudo apt update >> "$LOGFILE" 2>&1
        sudo apt upgrade -y >> "$LOGFILE" 2>&1
        sudo apt autoremove -y >> "$LOGFILE" 2>&1
        log_message "Ubuntu/Debian update complete."
    elif command -v dnf &> /dev/null; then
        # CentOS/RHEL 8+
        log_message "Detected RHEL 8+. Running dnf commands."
        sudo dnf check-update >> "$LOGFILE" 2>&1
        sudo dnf upgrade -y >> "$LOGFILE" 2>&1
        sudo dnf autoremove -y >> "$LOGFILE" 2>&1
        log_message "CentOS/RHEL 8+ update complete."
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL 7-
        log_message "Detected RHEL 7-. Running yum commands."
        sudo yum check-update >> "$LOGFILE" 2>&1
        sudo yum update -y >> "$LOGFILE" 2>&1
        log_message "CentOS/RHEL 7- update complete."
    else
        log_message "ERROR: Cannot detect suitable package manager (apt/dnf/yum). Skipping updates."
    fi
}

# --- 3. Critical File Permissions Check (SSH Hardening) ---

function check_file_permissions() {
    log_message "--- CHECKING CRITICAL FILE PERMISSIONS ---"

    SSH_CONFIG="/etc/ssh/sshd_config"
    if [ -f "$SSH_CONFIG" ]; then
        PERMS=$(stat -c "%a" "$SSH_CONFIG")
        OWNER=$(stat -c "%U" "$SSH_CONFIG")

        log_message "Checking $SSH_CONFIG (Current Perms: $PERMS, Owner: $OWNER)"

        # Recommended secure permissions: 600 (read/write by root only)
        if [ "$PERMS" -ne "600" ]; then
            log_message "WARNING: Permissions for $SSH_CONFIG are $PERMS, should be 600. Running 'chmod 600 $SSH_CONFIG'."
            # WARNING: Uncomment the line below to automatically fix permissions
            # sudo chmod 600 "$SSH_CONFIG"
        fi

        # Recommended owner: root
        if [ "$OWNER" != "root" ]; then
            log_message "WARNING: Owner for $SSH_CONFIG is $OWNER, should be root. Running 'chown root:root $SSH_CONFIG'."
            # WARNING: Uncomment the line below to automatically fix ownership
            # sudo chown root:root "$SSH_CONFIG"
        fi
    else
        log_message "Note: SSH daemon configuration file not found at $SSH_CONFIG."
    fi
}

# --- 4. Security Service Status Check ---

function check_security_services() {
    log_message "--- CHECKING FIREWALL AND INTRUSION PREVENTION SERVICES ---"

    # Check for Ubuntu Firewall (UFW)
    if command -v ufw &> /dev/null; then
        log_message "Checking UFW status (Ubuntu/Debian specific)."
        sudo ufw status | grep -E 'Status|active' | tee -a "$LOGFILE"
    fi

    # Check for CentOS/RHEL Firewall (Firewalld)
    if command -v firewall-cmd &> /dev/null; then
        check_status "Firewalld" "firewalld"
    fi

    # Check for Fail2Ban (Intrusion Prevention)
    if command -v fail2ban-client &> /dev/null; then
        check_status "Fail2ban" "fail2ban"
    fi
}

# --- 5. Main Execution ---

log_message "========================================================"
log_message "STARTING SERVER MAINTENANCE SCRIPT"
log_message "========================================================"

# Run all functions
run_updates
check_file_permissions
check_security_services

log_message "Cleanup: Removing old log files (older than 30 days) from /var/log/..."
find /var/log/ -type f -name "*.log" -mtime +30 -exec rm {} \; 2>/dev/null
log_message "Cleanup complete."

log_message "========================================================"
log_message "SCRIPT FINISHED. Review log at $LOGFILE"
log_message "========================================================"

exit 0
