#!/bin/sh
# script for backup the debezium off-set file
#

# Set EIP environment.
BKPS_HOME=/home/eip/shared/bkps
DEBEZIUM_HOME=/home/eip/.debezium
DEBEZIUM_OFFSET_FILE=$DEBEZIUM_HOME/offsets.txt
DEBEZIUM_HISTORY_FILE=$DEBEZIUM_HOME/dbhistory.txt
timestamp=`date +%Y-%m-%d_%H-%M-%S`
DEBEZIUM_OFFSET_FILE_BKP="offsets.txt$timestamp"
DEBEZIUM_HISTORY_FILE_BKP="dbhistory.txt$timestamp"

if [ -d "$BKPS_HOME" ]; then
   echo "BKPS DIRECTORY ALREDY EXISTS" | tee $BKPS_HOME/bkps.log
else
   echo "BKPS DIRECTORY DOESN'T EXISTS" | tee $BKPS_HOME/bkps.log
   echo "BKPS DIRECTORY IS BEING CREATED" | tee $BKPS_HOME/bkps.log
   mkdir $BKPS_HOME
   echo "BKPS DIRECTORY WAS CREATED" | tee $BKPS_HOME/bkps.log

fi

cd $BKPS_HOME

echo "STARTING BACKUP" | tee $BKPS_HOME/bkps.log
cp $DEBEZIUM_OFFSET_FILE $DEBEZIUM_OFFSET_FILE_BKP
cp $DEBEZIUM_HISTORY_FILE $DEBEZIUM_HISTORY_FILE_BKP
echo "BACKUP FINISHED" | tee $BKPS_HOME/bkps.log

