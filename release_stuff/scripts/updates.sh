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

chmod +x $SCRIPTS_DIR/*.sh

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" #| tee -a $LOG_DIR/upgrade.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" #| tee -a $LOG_DIR/upgrade.log
fi


timestamp=`date +%Y-%m-%d_%H-%M-%S`

echo "CHECKING FOR UPDATES AT $timestamp" #| tee -a $LOG_DIR/upgrade.log
echo "-------------------------------------------------------------" #| tee -a $LOG_DIR/upgrade.log

git config --global user.email "epts.centralization@fgh.org.mz"
git config --global user.name "epts.centralization"

#Pull changes from remote project
echo "LOOKING FOR EIP PROJECT UPDATES" #| tee -a $LOG_DIR/upgrade.log
	
echo "PULLING EIP PROJECT FROM DOCKER" #| tee -a $LOG_DIR/upgrade.log

branch_name=$(getGitBranch $GIT_BRANCHES_DIR)

if [ -z $branch_name ]; then
	echo "The git branch name for site $db_sync_senderId was not found"
	echo "Aborting upgrade process..."


	exit 1
fi

echo "Detected branch [$branch_name]"

git -C $RELEASE_BASE_DIR pull origin $branch_name
	
echo "EIP PROJECT PULLED FROM GIT REPOSITORY" #| tee -a $LOG_DIR/upgrade.log

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

	if [ "$updateAllowed" = 1 ]; then
		UPDATED=true
		
		echo "UPDATES FOUND..." #| tee -a $LOG_DIR/upgrade.log
		echo "PERFORMING UPDATE STEPS..." #| tee -a $LOG_DIR/upgrade.log

		# Downloading release packages
		echo "Verifying $REMOTE_RELEASE_NAME packages download status"
		$RELEASE_SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$REMOTE_RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTSSYNC_API_RELEASE_URL"

		CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$REMOTE_RELEASE_NAME"

		RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"
		if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]; then
		   echo "Error trying to download release packages: $REMOTE_RELEASE_NAME. See previous messages."
		   echo "Update process failed"
		   exit 1
		fi

		echo "STOPPING EIP APPLICATION.." #| tee -a $LOG_DIR/upgrade.log
		$SCRIPTS_DIR/eip_stop.sh
		echo "EIP APLICATION STOPPED!" #| tee -a $LOG_DIR/upgrade.log
		
		echo "EIP APLICATION STOPPED!" #| tee -a $LOG_DIR/upgrade.log
		echo "PERFORMING UPDATES..." #| tee -a $LOG_DIR/upgrade.log

		echo "Removing $HOME_DIR/cron folder"
		rm -fr $HOME_DIR/cron
		echo "Removing $HOME_DIR/scripts folder"
		rm -fr $HOME_DIR/scripts
		echo "Removing $HOME_DIR/etc folder"
		rm -fr $HOME_DIR/etc
		echo "Removing $HOME_DIR/routes folder"
		rm -fr $HOME_DIR/routes

		echo "Copying recursively from $RELEASE_DIR to $HOME_DIR"
		cp -R $RELEASE_DIR/* $HOME_DIR/
		echo "Copying recursively from $EPTSSYNC_SETUP_STUFF_DIR to $EPTSSYNC_HOME_DIR"
		cp -R $EPTSSYNC_SETUP_STUFF_DIR/* $EPTSSYNC_HOME_DIR

		# copying release packages
		EIP_PACKAGE_RELEASE_FILE_NAME=$(echo "$OPENMRS_EIP_APP_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)
		EPTSSYNC_PACKAGE_RELEASE_FILE_NAME=$(echo "$EPTSSYNC_API_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)

		echo "Copying $EIP_PACKAGE_RELEASE_FILE_NAME to $HOME_DIR/openmrs-eip-app-sender.jar"
		cp "$CURRENT_RELEASES_PACKAGES_DIR/$EIP_PACKAGE_RELEASE_FILE_NAME" "$HOME_DIR/openmrs-eip-app-sender.jar"

		echo "Copying $EPTSSYNC_PACKAGE_RELEASE_FILE_NAME to $EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"
		cp "$CURRENT_RELEASES_PACKAGES_DIR/$EPTSSYNC_PACKAGE_RELEASE_FILE_NAME" "$EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"

		chmod +x $RELEASE_SCRIPTS_DIR/*.sh
		chmod +x $SCRIPTS_DIR/*.sh

		echo "ALL FILES WERE COPIED"
	else
		echo "Updates found but not allowed for $db_sync_senderId" 
	fi
else
       	echo "NO UPDATES FOUND..." #| tee -a $LOG_DIR/upgrade.log
fi

. $SCRIPTS_DIR/setenv.sh

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
