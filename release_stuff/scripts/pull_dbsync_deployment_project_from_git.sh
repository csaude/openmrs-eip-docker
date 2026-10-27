#!/bin/sh
# THIS SCRIPT IS INTENDED TO PREPARE THE OPENMRS-EIP-DOCKER PROJECT FOR INSTALLATION/UPGRADE.
# The project is no longer pulled from git inside the container: release_stuff is
# pulled from hub.csaude.org.mz on the host by pull_release_artifacts.sh and is
# copied here from the project dir mounted at /home/openmrs-eip-docker
#

HOME_DIR="/home/eip"
SITE_SETUP_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
SITE_STUFF_DIR="$SITE_SETUP_BASE_DIR/release_stuff"
SITE_SETUP_SCRIPTS_DIR="$SITE_STUFF_DIR/scripts"

SETUP_STOCK_DIR="/home/openmrs-eip-docker"
SETUP_STOCK_STUFF_DIR="$SETUP_STOCK_DIR/release_stuff"

CURR_INSTALLATION_RELEASE_STUFF_DIR=$1

GIT_BRANCHES_DIR="$CURR_INSTALLATION_RELEASE_STUFF_DIR/git/branches"

. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/commons.sh
. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/try_to_load_environment.sh
. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/setenv.sh

timestamp=$(getCurrDateTime)

echo "CHECKING FOR UPDATES AT $timestamp" #| tee -a $LOG_DIR/upgrade.log
echo "-------------------------------------------------------------" #| tee -a $LOG_DIR/upgrade.log

if [ ! -d "$SETUP_STOCK_STUFF_DIR/scripts" ]; then
	logToScreenAndFile "$SETUP_STOCK_STUFF_DIR not found. Run ./pull_release_artifacts.sh on the host (outside the container) in the openmrs-eip-docker project dir and restart the container" $LOG_FILE
	exit 1
fi

logToScreenAndFile "Performing instalation/upgrade preparation on site $db_sync_senderId based on $SETUP_STOCK_STUFF_DIR" $LOG_FILE

if [ -d "$SITE_SETUP_BASE_DIR" ]; then
	#ALWAYS REMOVE THE EXISTING SITE SETUP DIR TO START FROM A CLEAN COPY
        rm -fr $SITE_SETUP_BASE_DIR
fi

mkdir -p $SITE_SETUP_BASE_DIR

cp -R $SETUP_STOCK_STUFF_DIR $SITE_STUFF_DIR

logToScreenAndFile "EIP PROJECT COPIED FROM $SETUP_STOCK_STUFF_DIR" $LOG_FILE
