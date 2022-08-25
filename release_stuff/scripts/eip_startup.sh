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

sleep 15 
echo "Starting Eip Application: [$EIP_MODE]"

if grep -q docker /proc/1/cgroup; then 
   echo "ENV ALREADY SET"
else
   echo "SETTING ENV"
   export $(cat $HOME_DIR/eip.env | xargs)
fi

# backward compatibility, v.2.0.1.0. Will be removed on next release (this code is present on update.sh for future updates)
. $SCRIPTS_DIR/release_info.sh
RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$HOME_DIR/shared/releases/$RELEASE_NAME/download_completed"
if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]
then
   $SCRIPTS_DIR/backward_compatibility_v.2.0.1.0.sh
   
   # verification
   if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]
   then
      echo "Startup process failed"
      exit 1
   fi
fi

if grep -q docker /proc/1/cgroup; then
        java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar
else
        nohup java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar 2>&1 &
	echo -n "APPLICATION STARTED IN BACKGROUND: [$EIP_MODE]"
fi
