#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
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
SHARED_DIR="$HOME_DIR/shared"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"
LOG_FILE="$HOME_DIR/install.log"

APK_CMD=$(which apk)

. $SETUP_STOCK_SCRIPTS_DIR/commons.sh
. $SETUP_STOCK_SCRIPTS_DIR/try_to_load_environment.sh
. $SETUP_STOCK_SCRIPTS_DIR/setenv.sh

isDockerInstallation
isDocker=$?

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
        logToScreenAndFile "INSTALLATION FINISHED" $LOG_FILE
else
        timestamp=`date +%Y-%m-%d_%H-%M-%S`

        logToScreenAndFile "STARTING EIP INSTALLATION PROCESS AT $timespamp" $LOG_FILE

 	branch_name=$(getGitBranch $GIT_BRANCHES_DIR)

        if [ ! -z $APK_CMD ]; then
           logToScreenAndFile "INSTALLING DEPENDENCIES USING APK" $LOG_FILE
           $SETUP_STOCK_SCRIPTS_DIR/apk_install.sh
        fi

        if [ -z $branch_name ]; then
                logToScreenAndFile "The git branch name for site $db_sync_senderId was not found" $LOG_FILE
                logToScreenAndFile "Aborting the installation process..." $LOG_FILE

                exit 1
	else
		logToScreenAndFile "Performing installation on site $db_sync_senderId based on branch $branch_name" $LOG_FILE

		if [ -d "$SITE_SETUP_BASE_DIR" ]; then
			logToScreenAndFile "$SITE_SETUP_BASE_DIR dir exists from old installation! Removing it..." 
			rm -fr $SITE_SETUP_BASE_DIR
		fi

		mkdir $SITE_SETUP_BASE_DIR

		git -C $SITE_SETUP_BASE_DIR init && git -C $SITE_SETUP_BASE_DIR checkout -b $branch_name
		git -C $SITE_SETUP_BASE_DIR remote add origin https://github.com/csaude/openmrs-eip-docker.git
		git -C $SITE_SETUP_BASE_DIR pull --depth=1 origin $branch_name
        fi
        
        cd $HOME_DIR

        . $SITE_SETUP_SCRIPTS_DIR/release_info.sh

        logToScreenAndFile "FOUND RELEASE {NAME: $RELEASE_NAME, DATE: $RELEASE_DATE} " $LOG_FILE

        logToScreenAndFile "PERFORMING INSTALLATION STEPS..." $LOG_FILE

        logToScreenAndFile "COPPING EIP APP FILES" $LOG_FILE

        cp -R $SITE_STUFF_DIR/* $HOME_DIR/

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
	MAIL_RECIPIENTS="$administrators_emails"
	MAIL_CONTENT_FILE="$INSTALL_FINISHED_REPORT_FILE"
	MAIL_ATTACHMENT="$LOG_FILE"

	echo "Automaticaly sent from remote site: $db_sync_senderId" > $MAIL_CONTENT_FILE

	$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"  
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
