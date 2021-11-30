#!/bin/sh
# Startup script for EIP Sender Application
#
# chkconfig: - 85 15
# description: EIP Sender Application
# processname: eip_sender
# pidfile:
# config:

# Set EIP environment.
echo "*/1       *       *       *       *       /home/eip/scripts/updates.sh" >> /etc/crontabs/root
echo -n "Preparing to start Eip Application..."
crond -f -l 8
