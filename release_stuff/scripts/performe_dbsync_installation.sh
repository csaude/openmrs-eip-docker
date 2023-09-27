#!/bin/sh
# This script performe the installation of necessary files for dbsync and related apps works
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
############ SITE ENVIRONMENT #######################
SITE_SETUP_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
SITE_STUFF_DIR="$SITE_SETUP_BASE_DIR/release_stuff"
SITE_SETUP_SCRIPTS_DIR="$SITE_STUFF_DIR/scripts"

EPTSSYNC_SETUP_STUFF_DIR="$SITE_STUFF_DIR/etc/eptssync"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"

. $SITE_SETUP_SCRIPTS_DIR/commons.sh
. $SITE_SETUP_SCRIPTS_DIR/try_to_load_environment.sh
. $SITE_SETUP_SCRIPTS_DIR/setenv.sh

. $SITE_SETUP_SCRIPTS_DIR/release_info.sh

logToScreenAndFile "FOUND RELEASE {NAME: $RELEASE_NAME, DATE: $RELEASE_DATE} " $LOG_FILE

logToScreenAndFile "PERFORMING INSTALLATION STEPS..." $LOG_FILE

logToScreenAndFile "COPPING EIP APP FILES" $LOG_FILE


if [ -d "$HOME_DIR/cron" ]; then
	echo "Removing $HOME_DIR/cron folder"
	rm -fr $HOME_DIR/cron
fi

if [ -d "$HOME_DIR/scripts" ]; then
	echo "Removing $HOME_DIR/scripts folder"

	rm -v  $HOME_DIR/scripts/!("$HOME_DIR/scripts/install.sh")

fi

if [ -d "$HOME_DIR/etc" ]; then
	echo "Removing $HOME_DIR/etc folder"
        rm -fr $HOME_DIR/etc
fi

if [ -d "$HOME_DIR/routes" ]; then
	echo "Removing $HOME_DIR/routes folder"
        rm -fr $HOME_DIR/routes
fi

if [ -d $EPTSSYNC_HOME_DIR ]; then
	echo "Removing $EPTSSYNC_HOME_DIR folder"
        rm -fr $EPTSSYNC_HOME_DIR
fi

cp -R $SITE_STUFF_DIR/* $HOME_DIR/

logToScreenAndFile "CREATING EPTSSYNC HOME DIR" $LOG_FILE
mkdir -p $EPTSSYNC_HOME_DIR

logToScreenAndFile "COPPING EPTSTYC STUFF TO $EPTSSYNC_HOME_DIR" $LOG_FILE
cp -R $EPTSSYNC_SETUP_STUFF_DIR/* $EPTSSYNC_HOME_DIR

chmod +x $SCRIPTS_DIR/*.sh

# Downloading release packages
logToScreenAndFile "Verifying $RELEASE_NAME packages download status" $LOG_FILE
$SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTSSYNC_API_RELEASE_URL" "$DBSYNC_NOTIFICATIONS_MANAGER_RELEASE_URL"

CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"

RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"

if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]; then
	logToScreenAndFile "Error trying to download release packages: $RELEASE_NAME. See previous messages." $LOG_FILE
        logToScreenAndFile "Installation process failed" $LOG_FILE
        exit 1
fi

EIP_PACKAGE_RELEASE_FILE_NAME=$(getFileName "$OPENMRS_EIP_APP_RELEASE_URL")
EPTSSYNC_PACKAGE_RELEASE_FILE_NAME=$(getFileName "$EPTSSYNC_API_RELEASE_URL")
DBSYNC_NOTIFICATIONS_MANAGER_FILE_NAME=$(getFileName "$DBSYNC_NOTIFICATIONS_MANAGER_RELEASE_URL")

logToScreenAndFile "Copying dbsync jar file" $LOG_FILE
cp "$CURRENT_RELEASES_PACKAGES_DIR/$EIP_PACKAGE_RELEASE_FILE_NAME" "$HOME_DIR/openmrs-eip-app-sender.jar"

logToScreenAndFile "Copying eptssync jar file" $LOG_FILE
cp "$CURRENT_RELEASES_PACKAGES_DIR/$EPTSSYNC_PACKAGE_RELEASE_FILE_NAME" "$EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"

logToScreenAndFile "Copying Dbsync notification Manager jar file" $LOG_FILE
cp "$CURRENT_RELEASES_PACKAGES_DIR/$DBSYNC_NOTIFICATIONS_MANAGER_FILE_NAME" "$HOME_DIR/notifications-manager.jar"

logToScreenAndFile "ALL FILES WERE COPIED" $LOG_FILE

logToScreenAndFile "INSTALLING CRONS" $LOG_FILE
$SCRIPTS_DIR/install_crons.sh
