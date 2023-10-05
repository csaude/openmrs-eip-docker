#!/bin/sh
# This script is run  before every upgrade of container. The script pickup and run scripts in before_upgrade folder
#
# Set environment.
HOME_DIR=/home/eip
LOG_DIR=$HOME_DIR/logs
BEFORE_UPGRADE_SCRIPTS_HOME=$HOME_DIR/scripts/before_upgrade
BEFORE_UPGRADE_LOG_DIR=$LOG_DIR/upgrade
timestamp=`date +%Y-%m-%d_%H-%M-%S`

INSTALL_INFO_DIR="$HOME_DIR/install_info/before_upgrade"

if [ ! -f "$INSTALL_INFO_DIR" ]; then
        echo "CREATING RUN HISTORY DIR" | tee -a $BEFORE_UPGRADE_LOG_DIR/install.log
        mkdir -p $INSTALL_INFO_DIR
        echo "RUN HISTORY DIR CREATED" | tee -a $BEFORE_UPGRADE_LOG_DIR/install.log
fi

cd $BEFORE_UPGRADE_SCRIPTS_HOME

QTY_FILES=$(ls *.sh | wc -l)

chmod +x *.sh

if [ "$QTY_FILES" -gt 0 ]; then
        for FILE in *.sh; do
                if [ -f "$INSTALL_INFO_DIR/$FILE" ]; then
                        echo "THE SCRIPT $FILE WAS ALREDY RUN" | tee -a $BEFORE_UPGRADE_LOG_DIR/install.log
                else
                        echo "RUNNING SCRIP $FILE" | tee -a $BEFORE_UPGRADE_LOG_DIR/install.log
                        ./$FILE
                        echo "THE SCRIPT $FILE WAS RUN" | tee -a $BEFORE_UPGRADE_LOG_DIR/install.log
                        echo "SCRIPT RUN ON $timestamp" > "$INSTALL_INFO_DIR/$FILE"
                fi

        done

        echo "AL SCRIPTS WERE EXECUTED" | tee $BEFORE_UPGRADE_LOG_DIR/install.log
else
        echo "NO SCRIPT TO RUN BEFORE UPDATE" | tee $BEFORE_UPGRADE_LOG_DIR/install.log
fi
