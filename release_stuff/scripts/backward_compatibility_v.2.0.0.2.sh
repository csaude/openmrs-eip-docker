#!/bin/sh
# backward compatibility, v.2.0.0.2. 
# This script will be removed on next release (this code is present on update.sh for future updates)
#

#ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"

echo "Removing old jar: $HOME_DIR/openmrs-eip-app-sender.jar"
rm "$HOME_DIR/openmrs-eip-app-sender.jar"

source $SCRIPTS_DIR/release_info.sh

echo "Downloading $OPENMRS_EIP_APP_RELEASE_URL to $HOME_DIR/openmrs-eip-app-1.0-SNAPSHOT.jar"
wget -O "$HOME_DIR/openmrs-eip-app-1.0-SNAPSHOT.jar" $OPENMRS_EIP_APP_RELEASE_URL
echo "Downloading $EPTSSYNC_API_RELEASE_URL to $EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar"
wget -O "$EPTSSYNC_HOME_DIR/eptssync-api-1.0-SNAPSHOT.jar" $EPTSSYNC_API_RELEASE_URL
