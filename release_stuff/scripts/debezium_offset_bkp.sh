#!/bin/sh
# script for backup the debezium off-set file
#

# Set EIP environment.
HOME_DIR=/home/eip
SCRIPTS_DIR=$HOME_DIR/scripts
BKPS_HOME=/home/eip/shared/bkps
DEBEZIUM_HOME=/home/eip/shared/.debezium
DEBEZIUM_OFFSET_FILE=$DEBEZIUM_HOME/offsets.txt
DEBEZIUM_HISTORY_FILE=$DEBEZIUM_HOME/dbhistory.txt
timestamp=`date +%Y-%m-%d_%H-%M-%S`
DEBEZIUM_OFFSET_FILE_BKP="offsets.txt$timestamp"
DEBEZIUM_HISTORY_FILE_BKP="dbhistory.txt$timestamp"
LOG_DIR=$HOME_DIR/logs/debezium_bkps

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/bkps.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/bkps.log
fi


if [ -d "$BKPS_HOME" ]; then
   echo "BKPS DIRECTORY ALREDY EXISTS" | tee -a $LOG_DIR/bkps.log
else
   echo "BKPS DIRECTORY DOESN'T EXISTS" | tee -a $LOG_DIR/bkps.log
   echo "BKPS DIRECTORY IS BEING CREATED" | tee -a $LOG_DIR/bkps.log
   mkdir $BKPS_HOME
   echo "BKPS DIRECTORY WAS CREATED" | tee -a $LOG_DIR/bkps.log

fi

cd $BKPS_HOME

echo "STARTING BACKUP" | tee  -a $LOG_DIR/bkps.log
cp $DEBEZIUM_OFFSET_FILE $DEBEZIUM_OFFSET_FILE_BKP
cp $DEBEZIUM_HISTORY_FILE $DEBEZIUM_HISTORY_FILE_BKP
echo "BACKUP FINISHED" | tee  -a $LOG_DIR/bkps.log

