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
pkill -f openmrs-eip-app-sender.jar 
echo -n "EIP APP STOPPED"
