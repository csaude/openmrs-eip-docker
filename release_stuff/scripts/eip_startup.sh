#!/bin/sh
# Startup script for EIP Sender Application
#
# chkconfig: - 85 15
# description: EIP Sender Application
# processname: eip_sender
# pidfile:
# config:

# Set EIP environment.
EIP_HOME=/home/eip
EIP_MODE=sender
HOME_DIR=/home/eip
SCRIPTS_DIR=$HOME_DIR/scripts
HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
GIT_BRANCHES_DIR="$RELEASE_DIR/git/branches"

. $SCRIPTS_DIR/commons.sh


cd $EIP_HOME


# Start application.
echo "Preparing to start Eip Application: [$EIP_MODE]"


if grep -q docker /proc/1/cgroup; then 
   echo "ENV ALREADY SET"
else
   echo "SETTING ENV"
   export $(cat $HOME_DIR/eip.env | xargs)
fi


branch_name=$(getGitBranch $GIT_BRANCHES_DIR)
setenv_file="$SCRIPTS_DIR/${branch_name}_setenv.sh"

echo "Using env from $setenv_file"

. $setenv_file 


sleep 15 
echo "Starting Eip Application: [$EIP_MODE]"

if grep -q docker /proc/1/cgroup; then
        java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar
else
        nohup java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar 2>&1 &
	echo -n "APPLICATION STARTED IN BACKGROUND: [$EIP_MODE]"
fi
