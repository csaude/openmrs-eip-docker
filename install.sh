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

APK_CMD=$(which apk)

. $SETUP_SCRIPTS_DIR/commons.sh

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
        echo "INSTALLATION FINISHED"
else
        timestamp=`date +%Y-%m-%d_%H-%M-%S`

        echo "STARTING EIP INSTALLATION PROCESS AT $timespamp"

 	branch_name=$(getGitBranch $GIT_BRANCHES_DIR)

        if [ -z $branch_name ]; then
                echo "The git branch name for site $db_sync_senderId was not found"
                echo "Aborting the installation process..."

                exit 1
	else
		echo "Performing installation on site $db_sync_senderId based on branch $branch_name"
        fi
        
        if [ ! -z $APK_CMD ]; then
           echo "INSTALLING DEPENDENCIES USING APK"
           $SETUP_SCRIPTS_DIR/apk_install.sh
        fi

        cd $HOME_DIR

        . $SETUP_SCRIPTS_DIR/release_info.sh

        echo "FOUND RELEASE {NAME: $RELEASE_NAME, DATE: $RELEASE_DATE} "

        echo "PERFORMING INSTALLATION STEPS..."

        echo "COPPING EIP APP FILES"

        cp -R $EIP_SETUP_STUFF_DIR/* $HOME_DIR/
        cp -R $EIP_SETUP_BASE_DIR $HOME_DIR

        echo "CREATING EPTSSYNC HOME DIR"
        mkdir -p $EPTSSYNC_HOME_DIR

        echo "COPPING EPTSTYC STUFF TO $EPTSSYNC_HOME_DIR"
        cp -R $EPTSSYNC_SETUP_STUFF_DIR/* $EPTSSYNC_HOME_DIR

	chmod +x $SCRIPTS_DIR/*.sh
        
        # Downloading release packages
        echo "Verifying $RELEASE_NAME packages download status"
        $SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTSSYNC_API_RELEASE_URL"
        
        CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"
        
        RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"
        if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]
        then
           echo "Error trying to download release packages: $RELEASE_NAME. See previous messages."
           echo "Installation process failed"
           exit 1
        fi
        
        EIP_PACKAGE_RELEASE_FILE_NAME=$(echo "$OPENMRS_EIP_APP_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)
        EPTSSYNC_PACKAGE_RELEASE_FILE_NAME=$(echo "$EPTSSYNC_API_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)

        echo "Copying $EIP_PACKAGE_RELEASE_FILE_NAME to $HOME_DIR/openmrs-eip-app-sender.jar"
        cp "$CURRENT_RELEASES_PACKAGES_DIR/$EIP_PACKAGE_RELEASE_FILE_NAME" "$HOME_DIR/openmrs-eip-app-sender.jar"
        
        echo "Copying $EPTSSYNC_PACKAGE_RELEASE_FILE_NAME to $EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"
        cp "$CURRENT_RELEASES_PACKAGES_DIR/$EPTSSYNC_PACKAGE_RELEASE_FILE_NAME" "$EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"
        
        echo "ALL FILES WERE COPIED"

        echo "INSTALLING CRONS"
        $SCRIPTS_DIR/install_crons.sh

	if [ ! -z $APK_CMD ]
        then
           $SETUP_SCRIPTS_DIR/configure_ssmtp.sh
        fi

	echo "CONFIGURING SSMTP"

        timestamp=`date +%Y-%m-%d_%H-%M-%S`
        echo "Installation finished at $timestamp" >> $INSTALL_FINISHED_REPORT_FILE
fi

if [ ! -z $APK_CMD ]
then
   echo "STARTING CROND INSIDE APK BASED DISTRO"
   crond
fi

echo "STARTING EIP APPLICATION"
$SCRIPTS_DIR/eip_startup.sh

echo "The dbsync app is stopped. The container will exit in 2mins"
sleep 120 




