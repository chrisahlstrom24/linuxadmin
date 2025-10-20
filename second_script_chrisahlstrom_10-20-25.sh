#!/bin/bash

# Prompt the user for server version
echo "Please enter server version (Ubuntu or CentOS):"
read server_version

# Give suggestions based on user's response
if [ "$server_version" == "ubuntu" ]; then
    echo "Troubleshooting for Ubuntu:"
    echo "- Check for internet connectivity: ping google.com"
    echo "- Set static IP: identify network interface using 'nmcli d', then edit Netplan: sudo nano /etc/netplan/01-netcfg.yaml"
    echo "- Check DNS: cat /etc/resolv.conf"
    echo "- Trace path to website: traceroute google.com"

elif [ "$server_version" == "centos" ]; then
    echo "Troubleshooting for CentOS:"
    echo "- Check for internet connectivity: ping google.com"
    echo "- Set static IP: open config file using 'sudo vi /etc/sysconfig/network-scripts/ifcfg-eth0' and update settings"
    echo "- Check DNS: cat /etc/resolv.conf"
    echo "- Trace path to website: traceroute google.com"

else
    echo "Unknown server version. Please enter either 'Ubuntu' or 'CentOS'."
fi
