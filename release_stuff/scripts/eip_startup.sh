#!/bin/sh
# Startup script for EIP Sender Application
#
# chkconfig: - 85 15
# description: EIP Sender Application
# processname: eip_sender
# pidfile:
# config:

# Set EIP environment.
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
EIP_MODE=sender
GIT_BRANCHES_DIR="$HOME_DIR/git/branches"
PATH_TO_CERTIFICATE="$HOME_DIR/artemis.cert"
DEFAULT_SET_ENV_FILE="$SCRIPTS_DIR/setenv.sh"

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh

cd $HOME_DIR

echo "Performing startup operations"

branch_name=$(getGitBranch $GIT_BRANCHES_DIR)
setenv_file="$SCRIPTS_DIR/${branch_name}_setenv.sh"

echo "Using env from $setenv_file"

old_artemis_host=$spring_artemis_host
old_artemis_port=$spring_artemis_port

. $DEFAULT_SET_ENV_FILE
. $setenv_file

URL="$spring_artemis_host:$spring_artemis_port"

$SCRIPTS_DIR/generate_certificate.sh $URL $PATH_TO_CERTIFICATE

if [ ! -s $PATH_TO_CERTIFICATE ]; then
        echo "Using non secure connection to artemis"

        export spring_artemis_host=$old_artemis_host
        export spring_artemis_port=$old_artemis_port
        export artemis_ssl_enabled=false
else
        echo "Using secure connection to artemis"
	
	if [ -z $JAVA_HOME ];then
		echo "JAVA_HOME is not defined! Configuring it"
		java_home=$(readlink -f $(which java))
		tmp="\/jre\/bin\/java"

		result=$(echo "$java_home" | sed "s/$tmp//g")

		export JAVA_HOME=$result
	fi

	echo "Using JAVA_HOME =$JAVA_HOME"

        $SCRIPTS_DIR/install_certificate_to_jdk_carcets.sh $PATH_TO_CERTIFICATE "artemis"

        export artemis_ssl_enabled=true
fi

echo "Starting notification manager app"

nohup java -jar -Dspring.profiles.active=remote centralization-features-manager-1.0.jar 2>&1 &

echo -n "CENTRALIZATION MANAGER STARTED IN BACKGROUND"

echo "Preparing to start Eip Application: [$EIP_MODE]"

sleep 7 

echo "Starting Eip Application: [$EIP_MODE]"

isDockerInstallation
isDockerInstall=$?

if [ $isDockerInstall = 1 ]; then
	echo "RUNNING EIP IN DOCKER CONTAINER..."

        java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar

	$SCRIPTS_DIR/try_to_generate_dbsync_stop_notification.sh
else
        nohup java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar 2>&1 &
	echo -n "APPLICATION STARTED IN BACKGROUND: [$EIP_MODE]"
fi
