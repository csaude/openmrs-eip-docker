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

if [ "$artemis_ssl_enabled" = "true" ]; then
	echo "Artemis server is configured for SSL. The application will force secure connection to artemis."
	URL="$spring_artemis_host:$spring_artemis_port"

	$SCRIPTS_DIR/generate_and_install_certificate.sh	  
else
        echo "Artemis server is not configured for SSL. The application will connect to the artemis throught non secure connection!"
		spring_artemis_host=$old_artemis_host
		spring_artemis_port=$old_artemis_port
fi

echo "Preparing to start Eip Application AND the centralization Manager application"

sleep 7 

echo "Starting centralization features manager app..."

nohup java -jar -Dspring.profiles.active=remote -Dlogging.config=file:"logback-spring-c-features.xml" -Dcamel.springboot.routes-include-pattern=file:"/home/eip/features-routes/*.xml" centralization-features-manager.jar 2>&1 &

echo -n "CENTRALIZATION MANAGER STARTED IN BACKGROUND"

echo "Starting Eip Application..."

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
