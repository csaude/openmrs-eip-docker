#!/bin/sh

# Set EIP environment.
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

LOG_DIR="$HOME_DIR/logs/upgrade"
ONGOING_UPGRADE="$HOME_DIR/ongoing_upgrade.tmp"

. $SCRIPTS_DIR/commons.sh

if [ -f "$LOG_DIR/upgrade.log" ]; then
        rm $LOG_DIR/upgrade.log
fi

logToScreenAndFile "INITIALIZING UPDATE CHECK" $LOG_FILE

checkIfProcessIsRunning "{updates.sh}" 
running=$?

if [ $running -eq 1 ]; then
	logToScreenAndFile "There is another upgrade process running. Aborting..." $LOG_FILE

	exit 0
fi

. $SCRIPTS_DIR/pull_dbsync_deployment_project_from_git.sh "$RELEASE_DIR" 2>&1 | tee -a $LOG_DIR/upgrade.log

$RELEASE_SCRIPTS_DIR/updates.sh 2>&1 | tee -a $LOG_DIR/upgrade.log
