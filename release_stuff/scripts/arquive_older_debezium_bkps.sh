#!/bin/sh
# script for arquive the older backps of debezium files
#

# Set environment.
HOME_DIR=/home/eip
BKPS_HOME=$HOME_DIR/shared/bkps
BKPS_ARQUIVED_HOME=$BKPS_HOME/arquived
timestamp=`date +%Y-%m-%d_%H-%M-%S`
LOG_DIR=$HOME_DIR/logs/debezium_bkps

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/arquive.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/arquive.log
fi

if [ ! -d "$BKPS_ARQUIVED_HOME" ]; then
   echo "$timestamp ARQUIVE DIRECTORY DOESN'T EXISTS" | tee -a $LOG_DIR/arquive.log
   echo "$timestamp ARQUIVE DIRECTORY IS BEING CREATED" | tee -a $LOG_DIR/arquive.log
   mkdir $BKPS_ARQUIVED_HOME
   echo "$timestamp ARQUIVE DIRECTORY WAS CREATED" | tee -a $LOG_DIR/arquive.log
fi

BKPS_TO_BE_ARQUIVED_HOME="$BKPS_HOME/arquive_$(ls $BKPS_ARQUIVED_HOME | wc -l)"

if [ ! -d "$BKPS_TO_BE_ARQUIVED_HOME" ]; then
	echo "$timestamp CREATING TEMPORARY DIR FOR ARQUIVING CURRENT FILES($BKPS_TO_BE_ARQUIVED_HOME)" | tee -a $LOG_DIR/arquive.log
	mkdir -p $BKPS_TO_BE_ARQUIVED_HOME
fi

#find $BKPS_HOME -type f -name '*.txt*' -mmin +3 -exec mv {} $BKPS_TO_BE_ARQUIVED_HOME \;
find $BKPS_HOME -type f -name '*.txt*' -mtime +15 -exec mv {} $BKPS_TO_BE_ARQUIVED_HOME \;

QTY_RECORDS=$(ls $BKPS_TO_BE_ARQUIVED_HOME/* | wc -l)

echo "$timestamp $QTY_RECORDS RECORDS WILL BE ARQUIVED!" | tee -a $LOG_DIR/arquive.log

if [ "$QTY_RECORDS" -gt 99 ]; then
	echo "$timestamp COMPRESSING $BKPS_TO_BE_ARQUIVED_HOME BEFORE ARQUIVE..." | tee -a $LOG_DIR/arquive.log
	tar -zcvf $BKPS_TO_BE_ARQUIVED_HOME".tar.gz" $BKPS_TO_BE_ARQUIVED_HOME	
	mv $BKPS_TO_BE_ARQUIVED_HOME".tar.gz" $BKPS_ARQUIVED_HOME
	echo "$timestamp COMPRESSING OF $BKPS_TO_BE_ARQUIVED_HOME IS DONE" | tee -a $LOG_DIR/arquive.log
else
	echo "$timestamp THE NUMBER OF FILES TO BE ARQUIVED IS LESS THAN 100. ARQUIVE WILL BE SKIPPED" | tee -a $LOG_DIR/arquive.log
	mv $BKPS_TO_BE_ARQUIVED_HOME/* $BKPS_HOME/

fi

rm -fr $BKPS_TO_BE_ARQUIVED_HOME


echo "$timestamp ARQUIVING OF OLDER FILES IS DONE!" | tee -a $LOG_DIR/arquive.log


