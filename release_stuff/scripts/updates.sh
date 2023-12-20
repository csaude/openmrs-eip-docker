#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#

#ENV
HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
SCRIPTS_DIR="$HOME_DIR/scripts"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
EPTSSYNC_SETUP_STUFF_DIR="$RELEASE_DIR/etc/eptssync"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"
SHARED_DIR="$HOME_DIR/shared"
LOG_DIR="$SHARED_DIR/logs/upgrade"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"
GIT_BRANCHES_DIR="$RELEASE_DIR/git/branches"

. $RELEASE_SCRIPTS_DIR/commons.sh

checIfupdateIsAllowedToCurrentSite(){
	branch_name=$(getGitBranch $GIT_BRANCHES_DIR)
        filename="$RELEASE_SCRIPTS_DIR/${branch_name}_sites_to_update"
	
	echo "Sites to update file name [$filename]"

        checkIfTokenExistsInFile $filename $db_sync_senderId

        allowed=$?

	return $allowed
}

. $SCRIPTS_DIR/release_info.sh

LOCAL_RELEASE_NAME=$RELEASE_NAME
LOCAL_RELEASE_DATE=$RELEASE_DATE

. $RELEASE_SCRIPTS_DIR/release_info.sh

REMOTE_RELEASE_NAME=$RELEASE_NAME
REMOTE_RELEASE_DATE=$RELEASE_DATE

echo "LOCAL RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE} " #| tee -a $LOG_DIR/upgrade.log
echo "REMOTE RELEASE INFO {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE} " #| tee -a $LOG_DIR/upgrade.log

if [ "$LOCAL_RELEASE_DATE" != "$REMOTE_RELEASE_DATE" ]; then
	checIfupdateIsAllowedToCurrentSite

	updateAllowed=$?

	if [ $updateAllowed -eq 1 ]; then
		UPDATED=true
		
		echo "UPDATES FOUND..." #| tee -a $LOG_DIR/upgrade.log
		echo "PERFORMING UPDATE STEPS..." #| tee -a $LOG_DIR/upgrade.log

		$RELEASE_SCRIPTS_DIR/eip_stop.sh

		$RELEASE_SCRIPTS_DIR/before_upgrade_scripts.sh

		$RELEASE_SCRIPTS_DIR/performe_dbsync_installation.sh

		SHARED_DIR="$HOME_DIR/shared"
		RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"
        	CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$REMOTE_RELEASE_NAME"
        	RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"

        	if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]; then
			UPDATED=""
		else
			echo "UPDATE DONE!"
        	fi

	else
		echo "Updates found but not allowed for $db_sync_senderId" 
	fi
else
       	echo "NO UPDATES FOUND..." #| tee -a $LOG_DIR/upgrade.log
fi

MAIL_SUBJECT="EIP REMOTO - ESTADO DE ACTUALIZACAO"
MAIL_RECIPIENTS="$administrators_emails"
MAIL_CONTENT_FILE="$HOME_DIR/update_notification_content"
MAIL_ATTACHMENT="$HOME_DIR/update_notification_log_file.log"


echo "Caros" >> $MAIL_CONTENT_FILE
echo "Junto enviamos o report da ultima tentativa de actualizacao da aplicacao openmrs-eip." >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "INFORMACAO DAS RELEASES" >> $MAIL_CONTENT_FILE
echo "---------------------" >> $MAIL_CONTENT_FILE
echo "CURRENT RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE}" >> $MAIL_CONTENT_FILE
echo "--------------------" >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "-----------------------------------------------------" >> $MAIL_CONTENT_FILE
echo "LOG: See Attachment"

cat $UPDATES_LOG_FILE > $MAIL_ATTACHMENT

$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"

$SCRIPTS_DIR/performe_after_update_check_actions.sh

if [ "$UPDATED" ]; then
	echo "PERFORMING AFTER UPDATE STEPS" #| tee -a $LOG_DIR/upgrade.log

	echo "RE-INSTALLING CRONS!" #| tee -a $LOG_DIR/upgrade.log
        $SCRIPTS_DIR/install_crons.sh

       echo "RUNNING STARTUP SCRIPTS!" #| tee -a $LOG_DIR/upgrade.log
       $SCRIPTS_DIR/after_upgrade_scripts.sh

	echo "RESTARTING EIP APPLICATION!" #| tee -a $LOG_DIR/upgrade.log
        $SCRIPTS_DIR/eip_startup.sh
fi
