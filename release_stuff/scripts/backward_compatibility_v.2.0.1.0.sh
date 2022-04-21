#!/bin/sh
# backward compatibility, v.2.0.1.0. 
# This script will be removed on next release (this code is present on update.sh for future updates)
#

HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"
APK_CMD=$(which apk)

# solving wget version compatibility between apline(apk) and debian
if [ ! -z $APK_CMD ]
then
    echo "INSTALLING COMPATIBLE WGET PACKAGE USING APK"
    apk add wget
fi

source $SCRIPTS_DIR/release_info.sh

# Downloading release packages
echo "Verifying $RELEASE_NAME packages download status"
$SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTSSYNC_API_RELEASE_URL"

CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"
RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"
if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]
then
    echo "Error trying to download release packages: $RELEASE_NAME. See previous messages."
    exit 1
fi

EIP_PACKAGE_RELEASE_FILE_NAME=$(echo "$OPENMRS_EIP_APP_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)
EPTSSYNC_PACKAGE_RELEASE_FILE_NAME=$(echo "$EPTSSYNC_API_RELEASE_URL" | rev | cut -d'/' -f 1 | rev)

echo "Copying $EIP_PACKAGE_RELEASE_FILE_NAME to $HOME_DIR/openmrs-eip-app-sender.jar"
cp "$CURRENT_RELEASES_PACKAGES_DIR/$EIP_PACKAGE_RELEASE_FILE_NAME" "$HOME_DIR/openmrs-eip-app-sender.jar"

echo "Copying $EPTSSYNC_PACKAGE_RELEASE_FILE_NAME to $EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"
cp "$CURRENT_RELEASES_PACKAGES_DIR/$EPTSSYNC_PACKAGE_RELEASE_FILE_NAME" "$EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"

echo "ALL FILES WERE COPIED"
