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

###########################EIP ENV#####################
SCRIPTS_DIR="$HOME_DIR/scripts"
SHARED_DIR="$HOME_DIR/shared"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"
CONFIG_FILE="$HOME_DIR/dbsync-users.properties"

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

	#rm -v  $HOME_DIR/scripts/!("$HOME_DIR/scripts/install.sh")

	rm -fr $HOME_DIR/scripts/*

fi

if [ -d "$HOME_DIR/etc" ]; then
	echo "Removing $HOME_DIR/etc folder"
        rm -fr $HOME_DIR/etc
fi

if [ -d "$HOME_DIR/routes" ]; then
	echo "Removing $HOME_DIR/routes folder"
        rm -fr $HOME_DIR/routes
fi

cp -R $SITE_STUFF_DIR/* $HOME_DIR/

chmod +x $SCRIPTS_DIR/*.sh

sed -i "s/eip_user/$eip_user/g" $CONFIG_FILE
sed -i "s/eip_pass/$eip_pass/g" $CONFIG_FILE


# Downloading release packages
logToScreenAndFile "Verifying $RELEASE_NAME packages download status" $LOG_FILE
$SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTS_ETL_API_RELEASE_URL" "$CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL"

CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"

RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"

if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]; then
	logToScreenAndFile "Error trying to download release packages: $RELEASE_NAME. See previous messages." $LOG_FILE
        logToScreenAndFile "Installation process failed" $LOG_FILE
        exit 1
fi

EIP_PACKAGE_RELEASE_FILE_NAME=$(getFileName "$OPENMRS_EIP_APP_RELEASE_URL")
EPTS_ETL_PACKAGE_RELEASE_FILE_NAME=$(getFileName "$EPTS_ETL_API_RELEASE_URL")
CENTRALIZATION_FEATURES_RELEASE_FILE_NAME=$(getFileName "$CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL")

logToScreenAndFile "Copying dbsync jar file" $LOG_FILE
cp "$CURRENT_RELEASES_PACKAGES_DIR/$EIP_PACKAGE_RELEASE_FILE_NAME" "$HOME_DIR/openmrs-eip-app-sender.jar"

logToScreenAndFile "Copying epts-etl jar file" $LOG_FILE
cp "$CURRENT_RELEASES_PACKAGES_DIR/$EPTS_ETL_PACKAGE_RELEASE_FILE_NAME" "$HOME_DIR/epts-etl-api.jar"

logToScreenAndFile "Copying Centralization Manager jar file" $LOG_FILE
cp "$CURRENT_RELEASES_PACKAGES_DIR/$CENTRALIZATION_FEATURES_RELEASE_FILE_NAME" "$HOME_DIR/centralization-features-manager.jar"

logToScreenAndFile "ALL FILES WERE COPIED" $LOG_FILE

logToScreenAndFile "INSTALLING CRONS" $LOG_FILE
$SCRIPTS_DIR/install_crons.sh
