#!/bin/sh
# Startup script for EIP Sender Application
#
# chkconfig: - 85 15
# description: EIP Sender Application
# processname: eip_sender
# pidfile:
# config:

# Set EIP environment.
export EIP_HOME=/home/eip
export EIP_MODE=sender

# Start application.
echo -n "Preparing to start Eip Application: [$EIP_MODE]"
sleep 30 
echo -n "Starting Eip Application: [$EIP_MODE]"
cd $EIP_HOME

java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar &
echo -n "APPLICATION STARTED IN BACKGROUND."

# Add update script to cron
echo "Adding update.sh to crontab"
echo "*/2       *       *       *       *       /home/eip/scripts/updates.sh" >> /etc/crontabs/root
echo "Script add to crontab"
crond -f -l 8

