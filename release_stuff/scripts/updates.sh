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
ONGOING_UPDATE_INFO_FILE="$HOME_DIR/ongoing_update_info"
SHARED_DIR="$HOME_DIR/shared"
LOG_DIR="$SHARED_DIR/logs/upgrade"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"

checkIfTokenExistsInFile(){
        filename=$1
        token=$2

        while read line; do
                if [ "$line"  = "$token" ]; then
			echo "Found $line"
                        return 1;
                 fi

        done < $filename
}

checIfupdateIsAllowedToCurrentSite(){
        filename="$RELEASE_SCRIPTS_DIR/sites_to_update.txt"

        allowed=$(checkIfTockenExistsInFile $filename $db_sync_senderId)

        echo $allowed
}


getGitBranch(){
        curr_dir=$(pwd)

        branch_dir="/home/eip/git/branches"

        cd $branch_dir

        for FILE in *; do
                checkIfTokenExistsInFile $FILE $db_sync_senderId
                exists=$?

                if [ "$exists" = 1 ]; then
                        echo $FILE
			return;
                fi
        done
}

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" #| tee -a $LOG_DIR/upgrade.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" #| tee -a $LOG_DIR/upgrade.log
fi


if [ -f "$ONGOING_UPDATE_INFO_FILE" ]; then
	echo "THERE IS ANOTHER UPDATE PROCESS ONGOING" #| tee -a $LOG_DIR/upgrade.log
else
	touch $ONGOING_UPDATE_INFO_FILE 

	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo "CHECKING FOR UPDATES AT $timestamp" #| tee -a $LOG_DIR/upgrade.log
	echo "-------------------------------------------------------------" #| tee -a $LOG_DIR/upgrade.log

	if [ -d "$RELEASE_BASE_DIR" ]; then
	   echo "RELEASE PROJECT ALREADY CLONED!" #| tee -a $LOG_DIR/upgrade.log
	else
   		echo "CLONIG RELEASE PROJECT..." #| tee -a $LOG_DIR/upgrade.log
	   	git clone https://github.com/FriendsInGlobalHealth/openmrs-eip-docker.git $RELEASE_BASE_DIR
	   	echo "RELEASE PROJECT CLONED TO $RELEASE_BASE_DIR" #| tee -a $LOG_DIR/upgrade.log
	fi

	git config --global user.email "jpboane@gmail.com"
	git config --global user.name "jpboane"

	#Pull changes from remote project
	echo "LOOKING FOR EIP PROJECT UPDATES" #| tee -a $LOG_DIR/upgrade.log
	
	echo "PULLING EIP PROJECT FROM DOCKER" #| tee -a $LOG_DIR/upgrade.log
	
	git -C $RELEASE_BASE_DIR clean -df
	git -C $RELEASE_BASE_DIR reset --hard
	git -C $RELEASE_BASE_DIR fetch

	brach_name=$(getGitBranch)

	git checkout $brach_name

	git -C $RELEASE_BASE_DIR pull origin $brach_name
	
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
			$SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$REMOTE_RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTSSYNC_API_RELEASE_URL"

			CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$REMOTE_RELEASE_NAME"

			RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"
			if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]
			then
			   echo "Error trying to download release packages: $REMOTE_RELEASE_NAME. See previous messages."
			   echo "Update process failed"
			   rm $ONGOING_UPDATE_INFO_FILE
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

			echo "ALL FILES WERE COPIED"
		else
			echo "Updates found but not allowed for $db_sync_senderId" 
		fi
	else
        	echo "NO UPDATES FOUND..." #| tee -a $LOG_DIR/upgrade.log
	fi

	rm $ONGOING_UPDATE_INFO_FILE
	
	if [ "$UPDATED" ]; then
 		echo "PERFORMING AFTER UPDATE STEPS" #| tee -a $LOG_DIR/upgrade.log

		echo "RE-INSTALLING CRONS!" #| tee -a $LOG_DIR/upgrade.log
                $SCRIPTS_DIR/install_crons.sh

                echo "RESTARTING EIP APPLICATION!" #| tee -a $LOG_DIR/upgrade.log
                $SCRIPTS_DIR/eip_startup.sh

                echo "RUNNING STARTUP SCRIPTS!" #| tee -a $LOG_DIR/upgrade.log
                $SCRIPTS_DIR/after_upgrade_scripts.sh
	fi
fi
