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
. $SCRIPTS_DIR/try_to_load_environment.sh

cd $EIP_HOME

# Start application.
echo "Preparing to start Eip Application: [$EIP_MODE]"

branch_name=$(getGitBranch $GIT_BRANCHES_DIR)
setenv_file="$SCRIPTS_DIR/${branch_name}_setenv.sh"

echo "Using env from $setenv_file"


old_artemis_host=$spring_artemis_host
old_artemis_port=$spring_artemis_port

. $setenv_file 

isSSLCertificateAvaliable $spring_artemis_host:$spring_artemis_port

sslAvaliable=$1

if [ $sslAvaliable=0 ]; then
	echo "Using non secure connection to artemis"

	export spring_artemis_host=$old_artemis_host
	export spring_artemis_port=$old_artemis_port
else
	echo "Using secure connection to artemis"
fi

sleep 15 
echo "Starting Eip Application: [$EIP_MODE]"

if grep -q docker /proc/1/cgroup; then
        java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar
else
        nohup java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar 2>&1 &
	echo -n "APPLICATION STARTED IN BACKGROUND: [$EIP_MODE]"
fi
