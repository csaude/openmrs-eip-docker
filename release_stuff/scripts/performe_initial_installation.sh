#!/bin/sh
# This scrip is intended to performe dbsync initial setup env
#
#ENV
HOME_DIR="/home/eip"

SETUP_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
STUFF_DIR="$SETUP_BASE_DIR/release_stuff"
SETUP_SCRIPTS_DIR="$STUFF_DIR/scripts"

EPTSSYNC_SETUP_STUFF_DIR="$STUFF_DIR/etc/eptssync"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"

SCRIPTS_DIR="$HOME_DIR/scripts"
INSTALL_FINISHED_REPORT_FILE="$HOME_DIR/install_finished_report_file"
LOG_DIR="$HOME_DIR/logs/install"
LOG_FILE="$LOG_DIR/install.log"
UPGRADE_LOG_DIR="$LOG_DIR/upgrade"

SHARED_DIR="$HOME_DIR/shared"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"


APK_CMD=$(which apk)

. $SETUP_SCRIPTS_DIR/commons.sh
. $SETUP_SCRIPTS_DIR/try_to_load_environment.sh
. $SETUP_SCRIPTS_DIR/setenv.sh

MAIL_SUBJECT="EIP REMOTO - INITIAL SETUP INFO[${db_sync_senderId}]"
MAIL_RECIPIENTS="$administrators_emails"
MAIL_CONTENT_FILE="$HOME_DIR/setup_notification_content"
MAIL_ATTACHMENT="$HOME_DIR/setup_notification_log"


##########################PARAMS=========================
ERROR_FILE=$1


isDockerInstallation
isDocker=$?

$SETUP_SCRIPTS_DIR/performe_dbsync_installation.sh "$ERROR_FILE"


if [ ! -f "$ERROR_FILE" ]; then
	logToScreenAndFile "Aborting from performe_initial_installation.sh at $timestamp" "$LOG_FILE"
     	exit 1
fi

. $SCRIPTS_DIR/release_info.sh
	
CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"
RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"

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
