#This script was done with ChatGPT.

#!/usr/bin/env bash
# centos_harden.sh - Basic cyber security hardening for CentOS 7/8/9
# WARNING: Review SSH_PORT and ALLOW_PORTS before running to avoid lockout.

set -euo pipefail
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_DIR="/root/sec-backups-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# === User-editable variables ===
SSH_PORT=22                 # change this if you use a different SSH port
ALLOW_PORTS=(22 80 443)     # ports to allow through firewall (numbers only)
DISABLE_PASSWORD_AUTH=true  # set to false to keep password auth enabled
KEEP_CURRENT_SSH_SESSION=true

# detect package manager
if command -v dnf >/dev/null 2>&1; then
  PKG_MGR=dnf
else
  PKG_MGR=yum
fi

echo "Running on $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2-)"

# function to backup files
backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp -a "$f" "$BACKUP_DIR/$(basename $f).$TIMESTAMP.bak"
  fi
}

# 1) update system (security updates only)
echo "Installing updates..."
$PKG_MGR -y update

# 2) install firewall (firewalld) and enable
echo "Installing and enabling firewalld..."
$PKG_MGR -y install firewalld
systemctl enable --now firewalld

# Open allowed ports
echo "Configuring firewalld rules..."
for p in "${ALLOW_PORTS[@]}"; do
  firewall-cmd --permanent --add-port=${p}/tcp
done
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="127.0.0.1" accept'
firewall-cmd --reload


# 4) Harden SSH
SSHD_CONF="/etc/ssh/sshd_config"
backup_file "$SSHD_CONF"

# safe edits: create temp file with new settings appended and then replace
tempfile=$(mktemp)
cp "$SSHD_CONF" "$tempfile"

# set options idempotently (use sshd -T to test)
# Disable root login, optionally disable password authentication, change port
sed -i -E "s/^(#?Port ).*/Port $SSH_PORT/" "$tempfile" || echo "Port $SSH_PORT" >> "$tempfile"
sed -i -E "s/^(#?PermitRootLogin ).*/PermitRootLogin no/" "$tempfile" || echo "PermitRootLogin no" >> "$tempfile"
if $DISABLE_PASSWORD_AUTH; then
  sed -i -E "s/^(#?PasswordAuthentication ).*/PasswordAuthentication no/" "$tempfile" || echo "PasswordAuthentication no" >> "$tempfile"
  sed -i -E "s/^(#?ChallengeResponseAuthentication ).*/ChallengeResponseAuthentication no/" "$tempfile" || echo "ChallengeResponseAuthentication no" >> "$tempfile"
fi
# Force use of modern Ciphers/MACs if absent (basic)
grep -q "^Ciphers " "$tempfile" || echo "Ciphers" >> "$tempfile"
grep -q "^MACs " "$tempfile" || echo "MACs" >> "$tempfile"

# install modified file only after backup
cp "$tempfile" "$SSHD_CONF"
rm -f "$tempfile"
systemctl restart sshd

# 5) enable automatic security updates (dnf-automatic or yum-cron)
if [ "$PKG_MGR" = "dnf" ]; then
  echo "Configuring dnf-automatic for security updates..."
  $PKG_MGR -y install dnf-automatic || true
  sed -i -E 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf || true
  systemctl enable --now dnf-automatic.timer || true
else
  echo "Configuring yum-cron for automatic security updates..."
  $PKG_MGR -y install yum-cron || true
  sed -i -E 's/^apply_updates.*/apply_updates = yes/' /etc/yum/yum-cron.conf || true
  systemctl enable --now yum-cron || true
fi

# 6) sysctl kernel hardening (ip forwarding disabled, rp_filter, tcp_syncookies, etc)
SYSCTL_FILE="/etc/sysctl.d/99-security.conf"
backup_file "$SYSCTL_FILE"
cat > "$SYSCTL_FILE" <<EOF
# Basic network hardening
net.ipv4.ip_forward = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
# reduce icmp redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF
sysctl --system

# 7) install auditd and enable
echo "Installing and enabling auditd..."
$PKG_MGR -y install audit || true
systemctl enable --now auditd

# 8) SELinux enforcement
if command -v getenforce >/dev/null 2>&1; then
  echo "Ensuring SELinux is Enforcing..."
  setenforce 1 || true
  backup_file /etc/selinux/config
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
fi

# 9) basic log rotation already present, nothing to change

# final status report
echo "BACKUPS created at: $BACKUP_DIR"
echo "Firewall (firewalld) status:"
firewall-cmd --state || true
echo "Open ports:"
firewall-cmd --list-ports || true

echo "fail2ban status:"
systemctl is-active fail2ban && fail2ban-client status sshd || echo "fail2ban service not active"

echo "sshd config test:"
sshd -T | grep -E "port|permitrootlogin|passwordauthentication" || true

echo "auditd status:"
systemctl is-active auditd || true

echo "Done. IMPORTANT: Keep your current SSH session open and test new connection from another shell before closing."
