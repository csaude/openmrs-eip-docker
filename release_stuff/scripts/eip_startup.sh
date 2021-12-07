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
#sleep 10 
echo -n "Starting Eip Application: [$EIP_MODE]"
cd $EIP_HOME

java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar &
echo -n "APPLICATION STARTED IN BACKGROUND."
