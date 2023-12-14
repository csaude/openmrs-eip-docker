#!/bin/sh
# Script for stop EIP Sender Application
#
# chkconfig: - 85 15
# description: EIP Sender Application
# processname: eip_stop
# pidfile:
# config:

# Start application.
echo -n "Stoping EIP Application"


running_process=$(pgrep -f openmrs-eip-app-sender.jar)

if [ -z $running_process ]; then
	echo "EIP Application is not running!"
else
	kill -9 $(pgrep -f openmrs-eip-app-sender.jar)
	echo -n "EIP APP STOPPED"
fi

kill -9 $(pgrep -f centralization-features-manager.jar)
