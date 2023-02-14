#!/bin/sh
# This script is run  after every upgrade of container. The script pickup and run scripts in after upgrade folder
#
# Set environment.
HOME_DIR=/home/eip
SHARED_DIR=$HOME_DIR/shared
LOG_DIR=$SHARED_DIR/logs
AFTER_UPGRADE_SCRIPTS_HOME=$HOME_DIR/scripts/after_upgrade
AFTER_UPGRADE_LOG_DIR=$LOG_DIR/upgrade
timestamp=`date +%Y-%m-%d_%H-%M-%S`

INSTALL_INFO_DIR=$SHARED_DIR/install_info/after_upgrade

if [ ! -f "$INSTALL_INFO_DIR" ]; then
	echo "CREATING RUN HISTORY DIR" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
	mkdir -p $INSTALL_INFO_DIR
	echo "RUN HISTORY DIR CREATED" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
fi

#cd $AFTER_UPGRADE_SCRIPTS_HOME

cd /home/eip/scripts

QTY_FILES=$(ls "after_upgrade"*.sh | wc -l)

if [ "$QTY_FILES" -gt 0 ]; then
	for FILE in "after_upgrade"*.sh; do
        	if [ -f "$INSTALL_INFO_DIR/$FILE" ]; then
               		echo "THE SCRIPT $FILE WAS ALREDY RUN" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
        	else
                	echo "RUNNING SCRIP $FILE" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
                	$FILE
                	echo "THE SCRIPT $FILE WAS RUN" | tee -a $AFTER_UPGRADE_LOG_DIR/install.log
                	echo "SCRIPT RUN ON $timestamp" > "$INSTALL_INFO_DIR/$FILE"
        	fi

	done

	echo "AL SCRIPTS WERE EXECUTED" | tee $AFTER_UPGRADE_LOG_DIR/install.log
else
	echo "NO SCRIPT TO RUN AFTER UPDATE" | tee $AFTER_UPGRADE_LOG_DIR/install.log
fi
