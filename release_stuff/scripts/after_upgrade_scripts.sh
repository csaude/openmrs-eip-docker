#!/bin/sh
# This script is run  after every upgrade of container. The script pickup and run scripts in after upgrade folder
#
# Set environment.
HOME_DIR=/home/eip
LOG_DIR=$HOME_DIR/logs
AFTER_UPGRADE_SCRIPTS_HOME=$HOME_DIR/scripts/after_upgrade
AFTER_UPGRADE_LOG_DIR=$LOG_DIR/upgrade
timestamp=`date +%Y-%m-%d_%H-%M-%S`

INSTALL_INFO_DIR="$HOME_DIR/install_info/after_upgrade"

if [ ! -f "$AFTER_UPGRADE_LOG_DIR" ]; then
	echo "CREATING RUN HISTORY DIR"
	mkdir -p $AFTER_UPGRADE_LOG_DIR
	echo "RUN HISTORY DIR CREATED"
fi

if [ ! -f "$LOG_DIR" ]; then
	echo "CREATING RUN HISTORY DIR" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
	mkdir -p $LOG_DIR
	echo "RUN HISTORY DIR CREATED" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
fi

if [ ! -f "$INSTALL_INFO_DIR" ]; then
	echo "CREATING RUN HISTORY DIR" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
	mkdir -p $INSTALL_INFO_DIR
	echo "RUN HISTORY DIR CREATED" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
fi


cd $AFTER_UPGRADE_SCRIPTS_HOME

QTY_FILES=$(ls *.sh | wc -l)

chmod +x *.sh

if [ "$QTY_FILES" -gt 0 ]; then
	for FILE in *.sh; do
        	if [ -f "$INSTALL_INFO_DIR/$FILE" ]; then
               		echo "THE SCRIPT $FILE WAS ALREDY RUN" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
        	else
                	echo "RUNNING SCRIP $FILE" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
                	./$FILE
                	echo "THE SCRIPT $FILE WAS RUN" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
                	echo "SCRIPT RUN ON $timestamp" > "$INSTALL_INFO_DIR/$FILE"
        	fi

	done

	echo "AL SCRIPTS WERE EXECUTED" | tee $AFTER_UPGRADE_LOG_DIR/install.log
else
	echo "NO SCRIPT TO RUN AFTER UPDATE" | tee $AFTER_UPGRADE_LOG_DIR/install.log
fi
