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
AFTER_UPGRADE_SCRIPTS_HOME=$HOME_DIR/scripts/after_upgrade
INSTALL_INFO_DIR="$HOME_DIR/install_info/after_upgrade"
AFTER_UPGRADE_ERROR_SCRIPT_INFO="$INSTALL_INFO_DIR/error_script_info.txt"

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
   cron
fi

if [ ! -f "$INSTALL_INFO_DIR" ]; then
        echo "CREATING RUN HISTORY DIR" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
        mkdir -p $INSTALL_INFO_DIR
        echo "RUN HISTORY DIR CREATED" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
fi

if [ -f "$AFTER_UPGRADE_ERROR_SCRIPT_INFO" ]; then
        echo "REMOVING OLD AFTER_UPGRADE_ERROR_SCRIPT_INFO" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
	rm $AFTER_UPGRADE_ERROR_SCRIPT_INFO
fi


$SCRIPTS_DIR/after_upgrade_scripts.sh

if [ -f "$AFTER_UPGRADE_ERROR_SCRIPT_INFO" ]; then
        echo "ERROR FOUND IN ONE OR MORE AFTER UPGRADE SCRIPTS PLEASE CHECK THE LOG AND LOOK AT FILE $AFTER_UPGRADE_ERROR_SCRIPT_INFO" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
	exit 1
fi

echo "STARTING EIP APPLICATION"
$SCRIPTS_DIR/eip_startup.sh

if [ $isDocker = 1 ]; then
	echo "The dbsync app is stopped. The container will exit in 2mins"
	sleep 120 
fi
