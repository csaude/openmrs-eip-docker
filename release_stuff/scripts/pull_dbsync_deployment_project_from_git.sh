#!/bin/sh
# THIS SCRIPT IS INTENDED TO PULL THE OPENMRS-EIP-DOCKER PROJECT FROM GIT REPOSITORY 
#

HOME_DIR="/home/eip"
SITE_SETUP_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
SITE_STUFF_DIR="$SITE_SETUP_BASE_DIR/release_stuff"
SITE_SETUP_SCRIPTS_DIR="$SITE_STUFF_DIR/scripts"

CURR_INSTALLATION_RELEASE_STUFF_DIR=$1
SETUP_GIT_TAG_INFO="$CURR_INSTALLATION_RELEASE_STUFF_DIR/../setup_git_tag_info.sh"

GIT_BRANCHES_DIR="$CURR_INSTALLATION_RELEASE_STUFF_DIR/git/branches"

. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/commons.sh
. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/try_to_load_environment.sh
. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/setenv.sh

timestamp=$(getCurrDateTime)

echo "CHECKING FOR UPDATES AT $timestamp" #| tee -a $LOG_DIR/upgrade.log
echo "-------------------------------------------------------------" #| tee -a $LOG_DIR/upgrade.log

git config --global user.email "epts.centralization@fgh.org.mz"
git config --global user.name "epts.centralization"

chmod +x $SETUP_GIT_TAG_INFO

#Load SETUP_GIT_TAG FROM SETUP_GIT_TAG_INFO
. $SETUP_GIT_TAG_INFO
SETUP_GIT_TAG=$setup_git_tag

logToScreenAndFile "Performing instalation/upgrade preparation on site $db_sync_senderId based on branch $SETUP_GIT_TAG" $LOG_FILE

if [ -d "$SITE_SETUP_BASE_DIR" ]; then
	#ALWAYS REMOVE THE EXISTING SITE SETUP DIR TO PREVENT GIT ERRORS
        rm -fr $SITE_SETUP_BASE_DIR
fi

mkdir $SITE_SETUP_BASE_DIR

git -C $SITE_SETUP_BASE_DIR init && git -C $SITE_SETUP_BASE_DIR checkout -b $SETUP_GIT_TAG
git -C $SITE_SETUP_BASE_DIR remote add origin https://github.com/csaude/openmrs-eip-docker.git
git -C $SITE_SETUP_BASE_DIR pull --depth=1 origin $SETUP_GIT_TAG

logToScreenAndFile "EIP PROJECT PULLED FROM GIT REPOSITORY" $LOG_FILE 
