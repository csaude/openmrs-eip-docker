#!/bin/sh
# This scrip is intended to performe dbsync initial setup env
#
#ENV
HOME_DIR="/home/eip"
SETUP_STOCK_DIR="/home/openmrs-eip-docker"
SETUP_STOCK_STUFF_DIR="$SETUP_STOCK_DIR/release_stuff"
SETUP_STOCK_SCRIPTS_DIR="$SETUP_STOCK_STUFF_DIR/scripts"
GIT_BRANCHES_DIR="$SETUP_STOCK_STUFF_DIR/git/branches"
INSTALL_FINISHED_REPORT_FILE="$HOME_DIR/install_finished_report_file"
LOG_DIR="$HOME_DIR/logs/install"
LOG_FILE="$LOG_DIR/install.log"
UPGRADE_LOG_DIR="$LOG_DIR/upgrade"

SETUP_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
STUFF_DIR="$SETUP_BASE_DIR/release_stuff"
SETUP_SCRIPTS_DIR="$STUFF_DIR/scripts"

SCRIPTS_DIR="$HOME_DIR/scripts"

ERROR_FILE="$HOME_DIR/install_error_file"

. $SETUP_STOCK_SCRIPTS_DIR/commons.sh
. $SETUP_STOCK_SCRIPTS_DIR/try_to_load_environment.sh

if [ -f "$ERROR_FILE" ];then
	logToScreenAndFile "REMOVING OLD ERROR INSTALLATION FILE $timespamp" $LOG_FILE
fi

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
        logToScreenAndFile "INSTALLATION FINISHED" $LOG_FILE
else
        timestamp=$(getCurrDateTime)

        logToScreenAndFile "STARTING EIP INSTALLATION PROCESS AT $timespamp" $LOG_FILE

 	branch_name=$(getGitBranch "$GIT_BRANCHES_DIR")

	if [ -z $branch_name ]; then
        	logToScreenAndFile "The git branch name for site $db_sync_senderId was not found" $LOG_FILE
        	logToScreenAndFile "Aborting the installation process on install.sh" $LOG_FILE

        	exit 1
	fi

	if [ ! -f "$UPGRADE_LOG_DIR" ]; then
        	echo "CREATING RUN HISTORY DIR" | tee -a $LOG_FILE
        	mkdir -p $UPGRADE_LOG_DIR
		touch $UPGRADE_LOG_DIR/install.log
        	echo "RUN HISTORY DIR CREATED" | tee -a $LOG_FILE
	fi

        logToScreenAndFile "INSTALLING DEPENDENCIES" $LOG_FILE
        $SETUP_STOCK_SCRIPTS_DIR/apt_install.sh
	
	$SETUP_STOCK_SCRIPTS_DIR/pull_dbsync_deployment_project_from_git.sh "$SETUP_STOCK_STUFF_DIR" 2>&1 | tee -a $LOG_FILE

	chmod +x $SETUP_SCRIPTS_DIR/*.sh

	$SETUP_SCRIPTS_DIR/performe_initial_installation.sh "$ERROR_FILE"

	if [ -f "$ERROR_FILE" ]; then
        	exit 1
	fi

fi

if [ ! -f "$ERROR_FILE" ];then
	$SCRIPTS_DIR/startup.sh
fi
