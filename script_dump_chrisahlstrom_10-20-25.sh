#!/bin/bash

# This script gathers the details of the server

echo "---Network details---"

echo -e "\nIP Address:"
ip addr

echo -e "\nRouting IP:"
ip route

echo -e "\nNetwork connections:"
ss -tuln

echo -e "\nDNS configuration:"
cat /etc/resolv.conf

echo -e "\nHostname Information:"
hostnamectl
