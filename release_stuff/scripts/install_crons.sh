#!/bin/sh
# script for backup the debezium off-set file
#

# Set environment.
HOME_DIR=/home/eip
CRONS_HOME=$HOME_DIR/cron
timestamp=`date +%Y-%m-%d_%H-%M-%S`
LOG_DIR=$HOME_DIR/shared/logs/cron

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/cron_install.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/cron_install.log
fi

cd $CRONS_HOME

cp cron /etc/crontabs/root

for FILE in *.sh; do 
 	echo "INSTALLING CRON ON $FILE" | tee -a $LOG_DIR/cron_install.log
	./$FILE
   	echo "CRON ON $FILE INSTALLED" | tee -a $LOG_DIR/cron_install.log
	echo "Cron installed on $timestamp" > "$FILE"_installed

done

echo "AL CRONS WERE INSTALLED" | tee -a $LOG_DIR/cron_install.log

