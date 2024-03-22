#!/bin/sh
# This scrip is intended to performe dbsync initial setup env
#
#ENV
HOME_DIR="/home/eip"

########### STOCK ENVIRONMENT ###################
SETUP_STOCK_DIR="/home/openmrs-eip-docker"
SETUP_STOCK_STUFF_DIR="$SETUP_STOCK_DIR/release_stuff"
SETUP_STOCK_SCRIPTS_DIR="$SETUP_STOCK_STUFF_DIR/scripts"
GIT_BRANCHES_DIR="$SETUP_STOCK_STUFF_DIR/git/branches"

############ SITE ENVIRONMENT #######################
SITE_SETUP_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
SITE_STUFF_DIR="$SITE_SETUP_BASE_DIR/release_stuff"
SITE_SETUP_SCRIPTS_DIR="$SITE_STUFF_DIR/scripts"

EPTSSYNC_SETUP_STUFF_DIR="$SITE_STUFF_DIR/etc/eptssync"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"

################# ENVIRONMENT #########################
SCRIPTS_DIR="$HOME_DIR/scripts"
INSTALL_FINISHED_REPORT_FILE="$HOME_DIR/install_finished_report_file"
LOG_DIR="$HOME_DIR/logs/install"
LOG_FILE="$LOG_DIR/install.log"
UPGRADE_LOG_DIR="$LOG_DIR/upgrade"

################ RELEASE ###############################
SHARED_DIR="$HOME_DIR/shared"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"


APK_CMD=$(which apk)

. $SETUP_STOCK_SCRIPTS_DIR/commons.sh
. $SETUP_STOCK_SCRIPTS_DIR/try_to_load_environment.sh
. $SETUP_STOCK_SCRIPTS_DIR/setenv.sh

MAIL_SUBJECT="EIP REMOTO - INITIAL SETUP INFO[${db_sync_senderId}]"
MAIL_RECIPIENTS="$administrators_emails"
MAIL_CONTENT_FILE="$HOME_DIR/setup_notification_content"
MAIL_ATTACHMENT="$HOME_DIR/setup_notification_log"

isDockerInstallation
isDocker=$?

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
        logToScreenAndFile "INSTALLATION FINISHED" $LOG_FILE
else
        timestamp=$(getCurrDateTime)

        logToScreenAndFile "STARTING EIP INSTALLATION PROCESS AT $timespamp" $LOG_FILE

 	branch_name=$(getGitBranch "$GIT_BRANCHES_DIR")

	if [ -z $branch_name ]; then
        	logToScreenAndFile "The git branch name for site $db_sync_senderId was not found" $LOG_FILE
        	logToScreenAndFile "Aborting the installation process..." $LOG_FILE

        	exit 1
	fi

	if [ ! -f "$UPGRADE_LOG_DIR" ]; then
        	echo "CREATING RUN HISTORY DIR" | tee -a $LOG_FILE
        	mkdir -p $UPGRADE_LOG_DIR
		touch $UPGRADE_LOG_DIR/install.log
        	echo "RUN HISTORY DIR CREATED" | tee -a $LOG_FILE
	fi

        if [ ! -z $APK_CMD ]; then
           logToScreenAndFile "INSTALLING DEPENDENCIES USING APK" $LOG_FILE
           $SETUP_STOCK_SCRIPTS_DIR/apk_install.sh
        fi
	
	$SETUP_STOCK_SCRIPTS_DIR/pull_dbsync_deployment_project_from_git.sh "$SETUP_STOCK_STUFF_DIR" 2>&1 | tee -a $LOG_FILE
	$SITE_SETUP_SCRIPTS_DIR/performe_dbsync_installation.sh

	. $SCRIPTS_DIR/release_info.sh
	
	CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"
	RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"

	if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]; then
        	exit 1
	fi


	timestamp=$(getCurrDateTime)
        logToScreenAndFile "Installation finished at $timestamp" $INSTALL_FINISHED_REPORT_FILE

 	cat $INSTALL_FINISHED_REPORT_FILE > $MAIL_CONTENT_FILE
	cat $LOG_FILE > $MAIL_ATTACHMENT

	echo "Dbsync Initial Setup report" > $MAIL_CONTENT_FILE
	echo "" >> $MAIL_CONTENT_FILE
        echo "" >> $MAIL_CONTENT_FILE
	echo "______________________" >> $MAIL_CONTENT_FILE
	echo "Automaticaly sent from remote site: $db_sync_senderId" >> $MAIL_CONTENT_FILE

	$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"  
fi

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
