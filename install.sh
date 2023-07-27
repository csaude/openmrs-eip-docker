#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#
#ENV
HOME_DIR="/home/eip"
EIP_SETUP_BASE_DIR="/home/openmrs-eip-docker"
EIP_SETUP_STUFF_DIR="$EIP_SETUP_BASE_DIR/release_stuff"
EPTSSYNC_SETUP_STUFF_DIR="$EIP_SETUP_STUFF_DIR/etc/eptssync"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"
SCRIPTS_DIR="$HOME_DIR/scripts"
SETUP_SCRIPTS_DIR="$EIP_SETUP_STUFF_DIR/scripts"
INSTALL_FINISHED_REPORT_FILE="$HOME_DIR/install_finished_report_file"
SHARED_DIR="$HOME_DIR/shared"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"
GIT_BRANCHES_DIR="$EIP_SETUP_STUFF_DIR/git/branches"
LOG_FILE="$HOME_DIR/install.log"

APK_CMD=$(which apk)

. $SETUP_SCRIPTS_DIR/commons.sh
. $SETUP_SCRIPTS_DIR/try_to_load_environment.sh

isDockerInstallation
isDocker=$?

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
        logToScreenAndFile "INSTALLATION FINISHED"
else
        timestamp=`date +%Y-%m-%d_%H-%M-%S`

        logToScreenAndFile "STARTING EIP INSTALLATION PROCESS AT $timespamp" $LOG_FILE

 	branch_name=$(getGitBranch $GIT_BRANCHES_DIR)

        if [ ! -z $APK_CMD ]; then
           logToScreenAndFile "INSTALLING DEPENDENCIES USING APK" $LOG_FILE
           $SETUP_SCRIPTS_DIR/apk_install.sh
        fi

        if [ -z $branch_name ]; then
                logToScreenAndFile "The git branch name for site $db_sync_senderId was not found" $LOG_FILE
                logToScreenAndFile "Aborting the installation process..." $LOG_FILE

                exit 1
	else
		logToScreenAndFile "Performing installation on site $db_sync_senderId based on branch $branch_name" $LOG_FILE

		git -C $EIP_SETUP_BASE_DIR clean -df
		git -C $EIP_SETUP_BASE_DIR reset --hard
		git -C $EIP_SETUP_BASE_DIR checkout $branch_name
        fi
        
        cd $HOME_DIR

        . $SETUP_SCRIPTS_DIR/release_info.sh

        logToScreenAndFile "FOUND RELEASE {NAME: $RELEASE_NAME, DATE: $RELEASE_DATE} " $LOG_FILE

        logToScreenAndFile "PERFORMING INSTALLATION STEPS..." $LOG_FILE

        logToScreenAndFile "COPPING EIP APP FILES" $LOG_FILE

        cp -R $EIP_SETUP_STUFF_DIR/* $HOME_DIR/
        cp -R $EIP_SETUP_BASE_DIR $HOME_DIR

        logToScreenAndFile "CREATING EPTSSYNC HOME DIR" $LOG_FILE
        mkdir -p $EPTSSYNC_HOME_DIR

        logToScreenAndFile "COPPING EPTSTYC STUFF TO $EPTSSYNC_HOME_DIR" $LOG_FILE
        cp -R $EPTSSYNC_SETUP_STUFF_DIR/* $EPTSSYNC_HOME_DIR

	chmod +x $SCRIPTS_DIR/*.sh
        
        # Downloading release packages
        logToScreenAndFile "Verifying $RELEASE_NAME packages download status" $LOG_FILE
        $SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTSSYNC_API_RELEASE_URL"
        
        CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"
        
        RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"
        if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]
        then
           logToScreenAndFile "Error trying to download release packages: $RELEASE_NAME. See previous messages." $LOG_FILE
           logToScreenAndFile "Installation process failed" $LOG_FILE
           exit 1
        fi
        
        EIP_PACKAGE_RELEASE_FILE_NAME=$(echo "$OPENMRS_EIP_APP_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)
        EPTSSYNC_PACKAGE_RELEASE_FILE_NAME=$(echo "$EPTSSYNC_API_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)

        logToScreenAndFile "Copying dbsync jar file" $LOG_FILE
        cp "$CURRENT_RELEASES_PACKAGES_DIR/$EIP_PACKAGE_RELEASE_FILE_NAME" "$HOME_DIR/openmrs-eip-app-sender.jar"
        
        logToScreenAndFile "Copying eptssync jar file" $LOG_FILE
        cp "$CURRENT_RELEASES_PACKAGES_DIR/$EPTSSYNC_PACKAGE_RELEASE_FILE_NAME" "$EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"
        
        logToScreenAndFile "ALL FILES WERE COPIED" $LOG_FILE

        logToScreenAndFile "INSTALLING CRONS" $LOG_FILE
        $SCRIPTS_DIR/install_crons.sh


	if [ $isDocker = 1 ]; then
        	$SCRIPTS_DIR/configure_ssmtp.sh
	fi

        timestamp=`date +%Y-%m-%d_%H-%M-%S`
        logToScreenAndFile "Installation finished at $timestamp" $INSTALL_FINISHED_REPORT_FILE

	MAIL_SUBJECT="EIP REMOTO - SETUP INFO"
	EMAIL_CONTENT_FILE="$LOG_FILE"
        PATH_TO_ERROR_LOG="$HOME_DIR/tmp_error_setup_email_notification"

	$SCRIPTS_DIR/send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" $EMAIL_CONTENT_FILE $PATH_TO_ERROR_LOG

        if [ -s $PATH_TO_ERROR_LOG ]; then
                 logToScreenAndFile  "THE NOTIFICATION EMAIL STATUS COULD NOT SENT YET!" $LOG_FILE

                #$SCRIPTS_DIR/schedule_send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" "$EMAIL_CONTENT_FILE"
        fi

fi

if [ $isDocker = 1 ]; then
   echo "STARTING CROND INSIDE APK BASED DISTRO"
   crond
fi

echo "STARTING EIP APPLICATION"
$SCRIPTS_DIR/eip_startup.sh

if [ $isDocker = 1 ]; then
	echo "The dbsync app is stopped. The container will exit in 2mins"
	sleep 120 
fi
