#!/bin/sh
# This scrip is intended to performe dbsync initial setup env
#
HOME_DIR="/home/eip"

################# ENVIRONMENT #########################
SCRIPTS_DIR="$HOME_DIR/scripts"
INSTALL_FINISHED_REPORT_FILE="$HOME_DIR/install_finished_report_file"
LOG_DIR="$HOME_DIR/logs/install"
LOG_FILE="$LOG_DIR/install.log"
UPGRADE_LOG_DIR="$LOG_DIR/upgrade"

APK_CMD=$(which apk)

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh
. $SCRIPTS_DIR/setenv.sh

MAIL_SUBJECT="EIP REMOTO - INITIAL SETUP INFO[${db_sync_senderId}]"
MAIL_RECIPIENTS="$administrators_emails"
MAIL_CONTENT_FILE="$HOME_DIR/setup_notification_content"
MAIL_ATTACHMENT="$HOME_DIR/setup_notification_log"

isDockerInstallation
isDocker=$?

if [ $isDocker = 1 ]; then
   echo "STARTING CROND INSIDE APK BASED DISTRO"
   crond
fi

$SCRIPTS_DIR/after_upgrade_scripts.sh

echo "STARTING EIP APPLICATION"
$SCRIPTS_DIR/eip_startup.sh

if [ $isDocker = 1 ]; then
	echo "The dbsync app is stopped. The container will exit in 2mins"
	sleep 120 
fi
