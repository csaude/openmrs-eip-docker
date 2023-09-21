#!/bin/sh
# Set EIP environment.
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/logs/upgrade"
ONGOING_UPGRADE="$HOME_DIR/ongoing_upgrade.tmp"

. $SCRIPTS_DIR/commons.sh

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/upgrade.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/upgrade.log
fi

if [ -f "$LOG_DIR/upgrade.log" ]; then
        rm $LOG_DIR/upgrade.log
fi

cd $SCRIPTS_DIR

# Start application.
echo -n "INITIALIZING UPDATE CHECK"



checkIfProcessIsRunning "{updates.sh}" 
running=$?

if [ $running = 1 ]; then
        logToScreenAndFile "There is another upgrade process running. Aborting..." $LOG_FILE

	exit 0
fi

./updates.sh 2>&1 | tee -a $LOG_DIR/upgrade.log
