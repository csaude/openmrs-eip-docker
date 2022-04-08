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
echo "Preparing to start Eip Application: [$EIP_MODE]"

sleep 20
echo "Starting Eip Application: [$EIP_MODE]"

if grep -q docker /proc/1/cgroup; then 
   echo "ENV ALREADY SET"
else
   echo "SETTING ENV"
   export $(cat eip.env | xargs)
fi

#source scripts/setenv.sh

cp application-sender-template.properties application-sender.properties

#sed -i "s/spring_artemis_host/$spring_artemis_host/g" application-sender.properties
#sed -i "s/spring_artemis_port/$spring_artemis_port/g" application-sender.properties

# backward compatibility, v.2.0.1.0. Will be removed on next release (this code is present on update.sh for future updates)
UPGRADE_LOG_DIR="$HOME_DIR/shared/logs/upgrade"
USING_GITHUB_RELEASES="$UPGRADE_LOG_DIR/using_github_releases"
if [ ! -f "$USING_GITHUB_RELEASES" ]
then
   $SCRIPTS_DIR/backward_compatibility_v.2.0.1.0.sh
   mkdir -p "$UPGRADE_LOG_DIR" && touch "$USING_GITHUB_RELEASES"
   echo "Using GitHub Releases"
fi

java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar
echo -n "APPLICATION STARTED IN BACKGROUND: [$EIP_MODE]"
