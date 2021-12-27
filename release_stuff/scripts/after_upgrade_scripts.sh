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

cd $AFTER_UPGRADE_SCRIPTS_HOME

for FILE in *.sh; do
        if [ -f "$INSTALL_INFO_DIR/$FILE" ]; then
                echo "THE SCRIPT $FILE WAS ALREDY RUN" | tee -a $AFTER_UPGRADE_SCRIPTS_HOME/install.log
        else
                echo "RUNNING SCRIP $FILE" | tee -a $AFTER_UPGRADE_SCRIPTS_HOME/install.log
                ./$FILE
                echo "THE SCRIPT $FILE WAS RUN" | -a tee $AFTER_UPGRADE_SCRIPTS_HOME/install.log
                echo "SCRIPT RUN ON $timestamp" > "$INSTALL_INFO_DIR/$FILE"
        fi

done

echo "AL SCRIPTS WERE EXECUTED" | tee $AFTER_UPGRADE_SCRIPTS_HOME/install.log
