#!/bin/sh
# script for backup the debezium off-set file
#
# Set environment.
HOME_DIR=/home/eip
AFTER_UPGRADE_SCRIPTS_HOME=$HOME_DIR/scripts/after_upgrade
timestamp=`date +%Y-%m-%d_%H-%M-%S`

cd $AFTER_UPGRADE_SCRIPTS_HOME

for FILE in *.sh; do
        if [ -f "$FILE"_installed ]; then
                echo "THE SCRIPT $FILE WAS ALREDY RUN" | tee -a $AFTER_UPGRADE_SCRIPTS_HOME/install.log
        else
                echo "RUNNING SCRIP $FILE" | tee -a $AFTER_UPGRADE_SCRIPTS_HOME/install.log
                ./$FILE
                echo "THE SCRIPT $FILE WAS RUN" | -a tee $AFTER_UPGRADE_SCRIPTS_HOME/install.log
                echo "SCRIPT RUN ON $timestamp" > "$FILE"_installed
        fi

done

echo "AL SCRIPTS WERE EXECUTED" | tee $AFTER_UPGRADE_SCRIPTS_HOME/install.log
