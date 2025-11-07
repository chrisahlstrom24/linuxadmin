#This Script was done with ChatGPT

#!/usr/bin/env bash
# ubuntu_harden.sh - Basic cyber security hardening for Ubuntu
# WARNING: Review SSH_PORT and ALLOW_PORTS before running to avoid lockout.

set -euo pipefail
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_DIR="/root/sec-backups-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# === User-editable variables ===
SSH_PORT=22
ALLOW_PORTS=(22 80 443)
DISABLE_PASSWORD_AUTH=true

echo "Running on $(lsb_release -d -s 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2-)"

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp -a "$f" "$BACKUP_DIR/$(basename $f).$TIMESTAMP.bak"
  fi
}

# 1) update packages
apt-get update -y
apt-get upgrade -y

# 2) Install UFW and enable
apt-get install -y ufw
ufw --force reset
# Allow loopback
ufw allow from 127.0.0.1 to any
# Allow specified ports
for p in "${ALLOW_PORTS[@]}"; do
  ufw allow ${p}/tcp
done
ufw --force enable

# 4) Harden SSH
SSHD_CONF="/etc/ssh/sshd_config"
backup_file "$SSHD_CONF"
tempfile=$(mktemp)
cp "$SSHD_CONF" "$tempfile"

sed -i -E "s/^(#?Port ).*/Port $SSH_PORT/" "$tempfile" || echo "Port $SSH_PORT" >> "$tempfile"
sed -i -E "s/^(#?PermitRootLogin ).*/PermitRootLogin no/" "$tempfile" || echo "PermitRootLogin no" >> "$tempfile"
if $DISABLE_PASSWORD_AUTH; then
  sed -i -E "s/^(#?PasswordAuthentication ).*/PasswordAuthentication no/" "$tempfile" || echo "PasswordAuthentication no" >> "$tempfile"
  sed -i -E "s/^(#?ChallengeResponseAuthentication ).*/ChallengeResponseAuthentication no/" "$tempfile" || echo "ChallengeResponseAuthentication no" >> "$tempfile"
fi

cp "$tempfile" "$SSHD_CONF"
rm -f "$tempfile"
systemctl restart sshd

# 5) enable unattended-upgrades
apt-get install -y unattended-upgrades apt-listchanges
dpkg-reconfigure -plow unattended-upgrades || true
# ensure config enables only security updates by default (file exists on modern Ubuntu)
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# 6) kernel/network sysctl hardening
SYSCTL_FILE="/etc/sysctl.d/99-security.conf"
backup_file "$SYSCTL_FILE"
cat > "$SYSCTL_FILE" <<EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF
sysctl --system

# 7) install auditd
apt-get install -y auditd
systemctl enable --now auditd

# 8) AppArmor note (Ubuntu ships with AppArmor). Ensure enabled:
if command -v aa-status >/dev/null 2>&1; then
  echo "AppArmor status:"
  aa-status || true
fi

# final status report
echo "BACKUPS created at: $BACKUP_DIR"
echo "UFW status:"
ufw status verbose || true
echo "fail2ban status:"
systemctl is-active fail2ban && fail2ban-client status sshd || echo "fail2ban not active"
echo "sshd config test:"
sshd -T | grep -E "port|permitrootlogin|passwordauthentication" || true
echo "auditd status:"
systemctl is-active auditd || true

echo "Done. IMPORTANT: Keep your current SSH session open and test new connection from another shell before closing."
