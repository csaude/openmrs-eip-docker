#!/bin/sh
# description: This shell is intended to force the upgrade of eptssync jar file 
#
HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/shared/releases/EIP-Release-6.0.0"

rm $RELEASE_BASE_DIR/download_completed
rm $RELEASE_BASE_DIR/eptssync-api-1.0.jar.SHA256
rm $RELEASE_BASE_DIR/eptssync-api-1.0.jar

