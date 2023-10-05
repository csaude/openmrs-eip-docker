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

		echo "UPDATE DONE!"
	else
		echo "Updates found but not allowed for $db_sync_senderId" 
	fi
else
       	echo "NO UPDATES FOUND..." #| tee -a $LOG_DIR/upgrade.log
fi

$SCRIPTS_DIR/schedule_update_notification.sh

if [ "$UPDATED" ]; then
	echo "PERFORMING AFTER UPDATE STEPS" #| tee -a $LOG_DIR/upgrade.log

	echo "RE-INSTALLING CRONS!" #| tee -a $LOG_DIR/upgrade.log
        $SCRIPTS_DIR/install_crons.sh

       echo "RUNNING STARTUP SCRIPTS!" #| tee -a $LOG_DIR/upgrade.log
       $SCRIPTS_DIR/after_upgrade_scripts.sh

	echo "RESTARTING EIP APPLICATION!" #| tee -a $LOG_DIR/upgrade.log
        $SCRIPTS_DIR/eip_startup.sh
fi
