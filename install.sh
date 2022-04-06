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
APK_CMD=$(which apk)

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
        echo "INSTALLATION FINISHED"
else
        timestamp=`date +%Y-%m-%d_%H-%M-%S`

        echo "STARTING EIP INSTALLATION PROCESS AT $timespamp"

        cd $HOME_DIR

        . $SETUP_SCRIPTS_DIR/release_info.sh

        REMOTE_RELEASE_NAME=$RELEASE_NAME
        REMOTE_RELEASE_DATE=$RELEASE_DATE

        echo "FOUND RELEASE {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE} "

        echo "PERFORMING INSTALLATION STEPS..."

        echo "COPPING EIP APP FILES"

        cp -R $EIP_SETUP_STUFF_DIR/* $HOME_DIR/
        cp -R $EIP_SETUP_BASE_DIR $HOME_DIR

        echo "CREATING EPTSSYNC HOME DIR"
        mkdir -p $EPTSSYNC_HOME_DIR

        echo "COPPING EPTSTYC STUFF TO $EPTSSYNC_HOME_DIR"
        cp -R $EPTSSYNC_SETUP_STUFF_DIR/* $EPTSSYNC_HOME_DIR

        echo "Downloading $OPENMRS_EIP_APP_RELEASE_URL to $HOME_DIR/openmrs-eip-app-sender.jar"
        wget -O "$HOME_DIR/openmrs-eip-app-sender.jar" $OPENMRS_EIP_APP_RELEASE_URL
        echo "Downloading $EPTSSYNC_API_RELEASE_URL to $EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"
        wget -O "$EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar" $EPTSSYNC_API_RELEASE_URL
        
        # flag for the version that uses github releases
        UPGRADE_LOG_DIR="$HOME_DIR/shared/logs/upgrade"
        USING_GITHUB_RELEASES="$UPGRADE_LOG_DIR/using_github_releases"
        mkdir -p "$UPGRADE_LOG_DIR" && touch "$USING_GITHUB_RELEASES"
        
        echo "ALL FILES WERE COPIED"

        if [ ! -z $APK_CMD ]
        then
           echo "INSTALLING DEPENDENCIES USING APK"
           $SCRIPTS_DIR/apk_install.sh
        fi

        echo "INSTALLING CRONS"
        $SCRIPTS_DIR/install_crons.sh

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

