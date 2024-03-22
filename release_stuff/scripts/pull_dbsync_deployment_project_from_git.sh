#!/bin/sh
# THIS SCRIPT IS INTENDED TO PULL THE OPENMRS-EIP-DOCKER PROJECT FROM GIT REPOSITORY 
#

HOME_DIR="/home/eip"
SITE_SETUP_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
SITE_STUFF_DIR="$SITE_SETUP_BASE_DIR/release_stuff"
SITE_SETUP_SCRIPTS_DIR="$SITE_STUFF_DIR/scripts"

CURR_INSTALLATION_RELEASE_STUFF_DIR=$1

GIT_BRANCHES_DIR="$CURR_INSTALLATION_RELEASE_STUFF_DIR/git/branches"

. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/commons.sh
. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/try_to_load_environment.sh
. $CURR_INSTALLATION_RELEASE_STUFF_DIR/scripts/setenv.sh

timestamp=$(getCurrDateTime)

echo "CHECKING FOR UPDATES AT $timestamp" #| tee -a $LOG_DIR/upgrade.log
echo "-------------------------------------------------------------" #| tee -a $LOG_DIR/upgrade.log

git config --global user.email "epts.centralization@fgh.org.mz"
git config --global user.name "epts.centralization"

#Pull changes from remote project
echo "LOOKING FOR EIP PROJECT UPDATES" #| tee -a $LOG_DIR/upgrade.log

echo "PULLING EIP PROJECT FROM DOCKER" #| tee -a $LOG_DIR/upgrade.log

branch_name=$curr_git_branch

if [ -z $branch_name ]; then
	logToScreenAndFile "The git branch name for site $db_sync_senderId was not found" $LOG_FILE
        logToScreenAndFile "Aborting the installation process..." $LOG_FILE

        exit 1
else

        logToScreenAndFile "Performing instalation/upgrade preparation on site $db_sync_senderId based on branch $branch_name" $LOG_FILE

        if [ -d "$SITE_SETUP_BASE_DIR" ]; then
		#ALWAYS REMOVE THE EXISTING SITE SETUP DIR TO PREVENT GIT ERRORS
                rm -fr $SITE_SETUP_BASE_DIR
        fi

        mkdir $SITE_SETUP_BASE_DIR

        git -C $SITE_SETUP_BASE_DIR init && git -C $SITE_SETUP_BASE_DIR checkout -b $branch_name
        git -C $SITE_SETUP_BASE_DIR remote add origin https://github.com/csaude/openmrs-eip-docker.git
        git -C $SITE_SETUP_BASE_DIR pull --depth=1 origin $branch_name
fi

echo "EIP PROJECT PULLED FROM GIT REPOSITORY" #| tee -a $LOG_DIR/upgrade.log
