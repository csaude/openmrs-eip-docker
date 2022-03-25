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
   . $EIP_HOME/eip.env
fi

#source scripts/setenv.sh

cp application-sender-template.properties application-sender.properties

#sed -i "s/spring_artemis_host/$spring_artemis_host/g" application-sender.properties
#sed -i "s/spring_artemis_port/$spring_artemis_port/g" application-sender.properties

# This code will execute once, after the installation of the version with GIT LFS. 
# Subsequential version installations will run normally
GIT_LFS=$(which git-lfs)
if [ -z $GIT_LFS ]
then
   echo "GIT LFS IS NOT INSTALLED. INVOKING INSTALLATION SCRIPT"
   $SCRIPTS_DIR/git_lfs_install_and_first_pull.sh
   echo "GIT LFS INSTALLATION SCRIPT INVOCATION ENDED"
fi

java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar
echo -n "APPLICATION STARTED IN BACKGROUND: [$EIP_MODE]"
