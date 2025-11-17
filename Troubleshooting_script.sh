#!/bin/sh

ISSUE=/tmp/troubleshooting.txt
> "$ISSUE"  

#Troubleshooting advice for each scenario
S1="Scenario #1 (Network/DNS) detected. Troubleshooting Advice: edit /etc/resolv.conf and set a valid nameserver"
S2="Scenario #2 (GRUB/fstab) detected. Troubleshooting Advice: boot from a Live ISO, mount root, chroot, then run 'grub-install /dev/sda && update-grub'"
S3="Scenario #3 (Permissions/SSH) detected. Troubleshooting Advice: fix permissions: chmod 755 /bin/ls /bin/cat, chmod 644 /etc/passwd /etc/ssh/sshd_config, chmod 640 /etc/shadow. change ownership back to root for all 'chown root:root'"
S4="Scenario #4 (Disk/logs) detected. Troubleshooting Advice: remove large files: rm /var/log/bigfile /tmp/hugefile and clean logs"

echo "Troubleshoot report - $(date)" >>"$ISSUE"


# Scenario 1: network/DNS
if [ -f /etc/resolv.conf ] && grep -q "999\.999\.999\.999" /etc/resolv.conf 2>/dev/null; then
    echo "$S1" >>"$ISSUE"
fi

# Scenario 2: grub & fstab
if [ -f /boot/grub/grub.cfg ] && grep -q "vmlinux\|root=UUID=broken-" /boot/grub/grub.cfg 2>/dev/null; then
    echo "$S2" >>"$ISSUE"
fi

# Scenario 3: permissions & ssh
if [ -e /bin/ls ] && [ "$(stat -c "%a" /bin/ls 2>/dev/null)" != "755" ]; then
    echo "$S3" >>"$ISSUE"
fi

#  Scenario 4: disk & logs
if [ -f /var/log/bigfile ] || [ -f /tmp/hugefile ]; then
    echo "$S4" >>"$ISSUE"
fi

# Final output 
if [ ! -s "$ISSUE" ]; then
    echo "No issues detected." >>"$ISSUE"
fi

cat "$ISSUE"
