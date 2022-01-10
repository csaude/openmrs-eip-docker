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
export HOME_DIR=/home/eip
export SCRIPTS_DIR=$HOME_DIR/scripts

cd $EIP_HOME

# Start application.
echo -n "Preparing to start Eip Application: [$EIP_MODE]"

sleep 20 
echo -n "Starting Eip Application: [$EIP_MODE]"

#source scripts/setenv.sh

cp application-sender-template.properties application-sender.properties

#sed -i "s/spring_artemis_host/$spring_artemis_host/g" application-sender.properties
#sed -i "s/spring_artemis_port/$spring_artemis_port/g" application-sender.properties

java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar &
echo -n "APPLICATION STARTED IN BACKGROUND."
