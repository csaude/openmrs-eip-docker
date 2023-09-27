#!/bin/sh
# script for install cron jobs. The cron jobs a picked up from $HOME_DIR/cron
#

# Set environment.
HOME_DIR=/home/eip
CRONS_HOME=$HOME_DIR/cron
timestamp=`date +%Y-%m-%d_%H-%M-%S`
LOG_DIR=$HOME_DIR/logs/cron

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/cron_install.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/cron_install.log
fi

cd $CRONS_HOME

cat default > CRONTAB 

for FILE in *.sh; do 
	echo "INSTALLING CRON ON $FILE" | tee -a $LOG_DIR/cron_install.log
	echo "" >> CRONTAB
	cat ./$FILE >> CRONTAB
	echo "CRON ON $FILE INSTALLED" | tee -a $LOG_DIR/cron_install.log
	echo "Cron installed on $timestamp" > "$FILE"_installed
done
echo "" >> CRONTAB

crontab CRONTAB

rm CRONTAB

echo "ALL CRONS WERE INSTALLED" | tee -a $LOG_DIR/cron_install.log
